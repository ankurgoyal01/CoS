---
service: "gcp-aiaas-terraform"
title: "Async Background ML Processing Request"
generated: "2026-03-03"
type: flow
flow_name: "async-submit-request"
flow_type: asynchronous
trigger: "HTTP POST to /v1/submitRequest via API Gateway"
participants:
  - "External caller"
  - "continuumApiGateway"
  - "continuumCloudFunctionsGen2"
  - "continuumCloudTasks"
  - "continuumCloudRunService"
  - "continuumBigQuery"
  - "continuumSecretManager"
architecture_ref: "containers-gcp-aiaas"
---

# Async Background ML Processing Request

## Summary

A caller submits a POST request to `/v1/submitRequest` via GCP API Gateway. Rather than performing the ML computation synchronously, the Cloud Function (`submit_request`) accepts the request, immediately returns an acknowledgement to the caller, and enqueues the work as a Cloud Tasks item for deferred processing. A downstream Cloud Run service then picks up the queued task and executes the full ML computation, writing results to BigQuery when complete. This pattern decouples long-running ML inference from the synchronous request/response cycle.

## Trigger

- **Type**: api-call
- **Source**: Internal consumer (Merchant Advisor tooling or another Groupon service) sending `POST /v1/submitRequest`
- **Frequency**: On-demand (driven by merchant workflow events that require background ML processing)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| External caller | Submits the background processing request | N/A |
| API Gateway | Validates API key; routes to `submit_request` Cloud Function | `continuumApiGateway` |
| Cloud Functions Gen 2 (`submit_request`) | Accepts the request; enqueues work to Cloud Tasks; returns acknowledgement | `continuumCloudFunctionsGen2` |
| Cloud Tasks | Queues the deferred ML work item for reliable async delivery | `continuumCloudTasks` |
| Cloud Run Service | Processes the deferred ML computation when Cloud Tasks delivers the task | `continuumCloudRunService` |
| BigQuery | Receives the ML computation results written by Cloud Run | `continuumBigQuery` |
| Secret Manager | Provides runtime secrets to Cloud Function and Cloud Run | `continuumSecretManager` |

## Steps

1. **Receives background request**: Caller sends `POST /v1/submitRequest` with `Content-Type: application/json` and a valid API key.
   - From: External caller
   - To: `continuumApiGateway`
   - Protocol: HTTPS

2. **Validates API key and routes**: API Gateway validates the API key and forwards the request to the `submit_request` Cloud Function backend (`https://us-central1-prj-grp-aiaas-prod-0052.cloudfunctions.net/submit_request`) with a deadline of 600 seconds.
   - From: `continuumApiGateway`
   - To: `continuumCloudFunctionsGen2`
   - Protocol: HTTPS (`x-google-backend`)

3. **Reads runtime secrets**: The `submit_request` Cloud Function reads any required secrets (e.g., Cloud Tasks queue credentials, service tokens) from Secret Manager.
   - From: `continuumCloudFunctionsGen2`
   - To: `continuumSecretManager`
   - Protocol: GCP SDK

4. **Enqueues background task**: The Cloud Function creates a Cloud Tasks item describing the ML work to be done and enqueues it to the appropriate Cloud Tasks queue.
   - From: `continuumCloudFunctionsGen2`
   - To: `continuumCloudTasks`
   - Protocol: GCP SDK (Cloud Tasks client)

5. **Returns acknowledgement to caller**: The Cloud Function immediately returns an HTTP 200 acknowledgement (JSON) to the API Gateway and caller — before the ML work is completed.
   - From: `continuumCloudFunctionsGen2`
   - To: `continuumApiGateway`
   - Protocol: HTTPS

6. **Relays acknowledgement**: API Gateway relays the Cloud Function response to the original caller.
   - From: `continuumApiGateway`
   - To: External caller
   - Protocol: HTTPS

7. **Delivers task to Cloud Run**: Cloud Tasks delivers the queued HTTP task to the Cloud Run service responsible for executing the ML computation (OIDC-authenticated).
   - From: `continuumCloudTasks`
   - To: `continuumCloudRunService`
   - Protocol: HTTPS (OIDC)

8. **Executes ML computation**: Cloud Run processes the deferred ML job (inference, scoring, aggregation).
   - From: `continuumCloudRunService`
   - To: Internal container processing
   - Protocol: Internal

9. **Writes results to BigQuery**: Cloud Run writes the computed ML results to the `merchant_data_center` BigQuery dataset.
   - From: `continuumCloudRunService`
   - To: `continuumBigQuery`
   - Protocol: GCP SDK

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid API key | API Gateway rejects with HTTP 403 | Caller receives 403; no work enqueued |
| Cloud Function fails to enqueue task | Function returns error; caller must retry `submitRequest` | No task enqueued; caller is responsible for retry |
| Cloud Tasks delivery fails | Cloud Tasks retries with exponential backoff until task TTL | ML computation delayed; eventually discarded if TTL exceeded |
| Cloud Run ML job fails | Cloud Run returns non-2xx; Cloud Tasks retries delivery | ML result not written; if max retries exceeded, task is dropped |
| BigQuery write fails | Cloud Run application handles error internally | Results not persisted; manual investigation required |

## Sequence Diagram

```
Caller            -> API Gateway          : POST /v1/submitRequest [API Key]
API Gateway       -> Cloud Function       : Forward request (submit_request, deadline=600s)
Cloud Function    -> Secret Manager       : Read secrets (GCP SDK)
Cloud Function    -> Cloud Tasks          : Enqueue ML work item (GCP SDK)
Cloud Tasks       --> Cloud Function      : Task enqueued (acknowledgement)
Cloud Function    --> API Gateway         : HTTP 200 acknowledgement (JSON)
API Gateway       --> Caller              : HTTP 200 acknowledgement
...async...
Cloud Tasks       -> Cloud Run Service    : POST /process-ml-job [OIDC token]
Cloud Run Service -> BigQuery             : Write ML results (GCP SDK)
Cloud Run Service --> Cloud Tasks         : HTTP 200 (task acknowledged)
```

## Related

- Architecture dynamic view: `containers-gcp-aiaas`
- OpenAPI spec: `doc/swagger.yml` (`/v1/submitRequest` operation)
- Related flows: [Synchronous AI Inference via API Gateway](api-gateway-inference.md), [Scheduled Background Job](scheduled-background-job.md)
