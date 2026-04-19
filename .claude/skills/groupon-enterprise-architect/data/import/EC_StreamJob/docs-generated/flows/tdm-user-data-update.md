---
service: "EC_StreamJob"
title: "TDM User Data Update"
generated: "2026-03-03"
type: flow
flow_name: "tdm-user-data-update"
flow_type: event-driven
trigger: "Filtered and deduplicated event queue is ready after Janus ingestion within a Spark partition"
participants:
  - "continuumEcStreamJob"
  - "tdmApi"
architecture_ref: "dynamic-TDMUpdateFlow"
---

# TDM User Data Update

## Summary

This flow covers the second half of each 20-second Spark micro-batch: taking the deduplicated event payload queue built during the ingestion phase and concurrently posting each payload to the Targeted Deal Message (TDM) API endpoint `/v1/updateUserData`. A fixed 10-thread pool per partition issues all HTTP requests in parallel. The entire batch is bounded to a 19-second await window; any futures still pending at that point are abandoned.

## Trigger

- **Type**: event (continuation within Spark `foreachPartition` call)
- **Source**: Non-empty `ListBuffer[JsObject]` queue produced by the [Janus Event Ingestion and Filtering](janus-event-ingestion.md) flow within the same partition execution
- **Frequency**: Continuous; once per 20-second batch per partition

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| EC Stream Job (`RealTimeJob`) | Orchestrates concurrent HTTP posting; manages thread pool lifecycle | `continuumEcStreamJob` |
| TDM API | Receives user deal-interaction event payloads and updates personalization state | `tdmApi` |

## Steps

1. **Select TDM endpoint URL**: Based on `colo` and `env` arguments, resolves the correct TDM base URL:
   - NA staging: `http://targeted-deal-message-app1-staging.snc1:8080/v1/updateUserData`
   - EMEA staging: `http://targeted-deal-message-app2-emea-staging.snc1:8080/v1/updateUserData`
   - NA prod: `http://targeted-deal-message-app-vip.snc1/v1/updateUserData`
   - EMEA prod: `http://targeted-deal-message-app-vip.dub1/v1/updateUserData`
   - Internal to `continuumEcStreamJob`

2. **Create HTTP client and thread pool**: Initializes a `NingWSClient` (Play WS async HTTP client) and a `FixedThreadPool` of 10 threads (`THREAD_POOL_SIZE`) scoped to the current partition.
   - Internal to `continuumEcStreamJob`

3. **Submit async POST requests**: For each payload in the `ListBuffer` queue, submits a non-blocking HTTP POST to the TDM endpoint with:
   - Header: `Content-Type: application/json`
   - Request timeout: 2000 ms (`API_TIMEOUT`)
   - Body: `JsObject` serialized to JSON
   - From: `continuumEcStreamJob`
   - To: `tdmApi`
   - Protocol: HTTP/JSON POST to `/v1/updateUserData`

4. **Collect futures**: Collects all `Future[WSResponse]` values into a sequence.
   - Internal to `continuumEcStreamJob`

5. **Await completion with timeout**: Calls `Await.result(Future.sequence(futures), 19.seconds)` to wait for all HTTP responses. Uses `scala.util.Try` to handle timeout without crashing the executor.
   - If all futures complete within 19 seconds: batch succeeds silently
   - If timeout occurs: prints `Request interrupted, error {message}` and stack trace to stdout; batch is considered done and Kafka offset advances

6. **Tear down resources**: Closes the `NingWSClient` and shuts down the thread pool executor.
   - Internal to `continuumEcStreamJob`

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| TDM API returns non-2xx response | `WSResponse` is received but response code is not inspected in code; no error handling | Event considered processed; TDM state may not have been updated |
| TDM API request times out (>2000ms) | `withRequestTimeout(API_TIMEOUT)` throws; future completes with failure | Contributes to overall batch timeout countdown |
| Entire batch exceeds 19-second window | `Try(Await.result(..., 19.seconds))` captures `TimeoutException` | Error logged to stdout; all pending futures abandoned; no retry; Kafka offset advances |
| `NingWSClient` / thread pool initialization fails | Exception propagates from `foreachPartition` | Partition fails; Spark may retry depending on cluster config |

## Sequence Diagram

```
RealTimeJob  -> RealTimeJob: Resolve TDM URL from (colo, env)
RealTimeJob  -> RealTimeJob: Create NingWSClient + FixedThreadPool(10)
RealTimeJob  -> TDM API:    POST /v1/updateUserData (payload 1, async)
RealTimeJob  -> TDM API:    POST /v1/updateUserData (payload 2, async)
RealTimeJob  -> TDM API:    POST /v1/updateUserData (payload N, async)
TDM API      --> RealTimeJob: HTTP response (per request, within 2000ms)
RealTimeJob  -> RealTimeJob: Await.result(Future.sequence, 19s)
RealTimeJob  -> RealTimeJob: Close client + shutdown thread pool
```

## Related

- Architecture dynamic view: `dynamic-TDMUpdateFlow`
- Related flows: [Janus Event Ingestion and Filtering](janus-event-ingestion.md), [Spark Job Startup and Colo Selection](spark-job-startup.md)
