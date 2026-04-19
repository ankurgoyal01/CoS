---
service: "arbitration-service"
title: "Experiment Config Refresh"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "experiment-config-refresh"
flow_type: synchronous
trigger: "POST /experiment-config/refresh API call, service startup, or periodic polling"
participants:
  - "continuumArbitrationService"
  - "apiHandlers"
  - "experimentationAdapter"
  - "optimizelyService"
architecture_ref: "dynamic-experimentConfigRefresh"
---

# Experiment Config Refresh

## Summary

The experiment config refresh flow triggers a re-fetch of Optimizely experiment definitions and updates the in-memory experiment config cache. This flow runs at service startup (as part of [Startup Cache Loading](startup-cache-loading.md)), via periodic polling by the service, and on-demand via the `POST /experiment-config/refresh` endpoint. The refreshed config influences arbitration algorithm behavior and A/B test variant selection in subsequent decisioning flows.

## Trigger

- **Type**: api-call (on-demand), startup (automatic), schedule (periodic polling)
- **Source**: On-demand via `POST /experiment-config/refresh`; automatic on service startup; periodic internal polling
- **Frequency**: On startup, on demand, and periodically (polling interval not specified in inventory)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Handlers | Receives `POST /experiment-config/refresh` and routes to experimentation adapter | `apiHandlers` |
| Experimentation Adapter | Fetches experiment definitions from Optimizely SDK and updates in-memory cache | `experimentationAdapter` |
| Optimizely | Provides experiment definitions and feature flag variant context | `optimizelyService` |

## Steps

1. **Trigger config refresh**: Refresh is triggered by an API call to `POST /experiment-config/refresh`, by service startup, or by the periodic polling timer.
   - From: caller or internal scheduler
   - To: `apiHandlers` (API-triggered) or `experimentationAdapter` (startup/polling)
   - Protocol: REST/HTTPS (API-triggered) or direct (in-process, startup/polling)

2. **Invoke experimentation adapter**: API handler routes the on-demand request to the experimentation adapter to execute the refresh.
   - From: `apiHandlers`
   - To: `experimentationAdapter`
   - Protocol: direct (in-process)

3. **Fetch experiment definitions from Optimizely**: Experimentation adapter uses the Optimizely Go SDK to fetch the latest experiment datafile using the configured `OPTIMIZELY_SDK_KEY`.
   - From: `experimentationAdapter`
   - To: `optimizelyService`
   - Protocol: HTTPS (Optimizely CDN / SDK)

4. **Update in-memory cache**: Experimentation adapter replaces the current in-memory experiment config with the newly fetched definitions.
   - From: `experimentationAdapter`
   - To: `experimentationAdapter`
   - Protocol: direct (in-process)

5. **Return new config**: On API-triggered refresh, the API handler returns the updated experiment config to the caller.
   - From: `apiHandlers`
   - To: caller
   - Protocol: REST/HTTPS (JSON response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Optimizely SDK fetch fails (network or auth error) | Retain last successfully cached config; log error | Arbitration continues with stale experiment config; no immediate impact unless config is very outdated |
| `OPTIMIZELY_SDK_KEY` invalid or expired | SDK returns error; refresh fails | Stale config retained; operator must rotate the SDK key |
| In-memory cache update fails | Log error | Cache may be in inconsistent state; periodic retry will eventually succeed |

## Sequence Diagram

```
caller -> apiHandlers: POST /experiment-config/refresh
apiHandlers -> experimentationAdapter: trigger config refresh
experimentationAdapter -> optimizelyService: fetch experiment datafile (SDK key auth)
optimizelyService --> experimentationAdapter: experiment definitions (datafile)
experimentationAdapter -> experimentationAdapter: update in-memory experiment config cache
experimentationAdapter --> apiHandlers: updated config
apiHandlers --> caller: HTTP 200 (new experiment config JSON)
```

## Related

- Architecture dynamic view: `dynamic-experimentConfigRefresh`
- Related flows: [Startup Cache Loading](startup-cache-loading.md) — includes experiment config fetch as part of startup
- Related flows: [Best-For Selection](best-for-selection.md) — uses experiment config during eligibility scoring
- Related flows: [Arbitration Decision](arbitration-decision.md) — uses experiment config for algorithm variant selection
