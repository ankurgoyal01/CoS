---
service: "expy-service"
title: "Feature Flag CRUD"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "feature-flag-crud"
flow_type: synchronous
trigger: "POST/PUT/DELETE /feature-manager/* API call from an internal Groupon service or admin tool"
participants:
  - "continuumExpyService"
  - "expyService_apiResources"
  - "serviceLayer_Exp"
  - "expyService_externalClients"
  - "expyService_dataAccessLayer"
  - "expyService_cacheLayer"
  - "continuumExpyMySql"
  - "optimizelyApiSystem_6c1a"
architecture_ref: "dynamic-feature-flag-crud"
---

# Feature Flag CRUD

## Summary

This flow handles create, update, and delete operations on feature flag definitions managed by Expy Service. An internal caller sends a mutating request to the `/feature-manager/*` endpoints; the service layer validates the request, persists the change to MySQL, optionally syncs the mutation to the Optimizely REST API to keep the Optimizely platform in sync, and invalidates the relevant cache entries so subsequent bucketing decisions reflect the updated flag state.

## Trigger

- **Type**: api-call
- **Source**: Internal Groupon service or admin tool calling `POST /feature-manager/*`, `PUT /feature-manager/*`, or `DELETE /feature-manager/*`
- **Frequency**: On-demand — per flag mutation request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Expy Service (REST Resources) | Receives inbound HTTP mutation request | `expyService_apiResources` |
| Service Layer | Validates request, orchestrates persistence and Optimizely sync | `serviceLayer_Exp` |
| External Clients | Calls Optimizely REST API to sync flag mutation upstream | `expyService_externalClients` |
| Data Access | Reads/writes feature flag records in MySQL | `expyService_dataAccessLayer` |
| Cache Layer | Invalidates stale cache entries after mutation | `expyService_cacheLayer` |
| Expy MySQL | Persists feature flag definition | `continuumExpyMySql` |
| Optimizely API | External sync target for feature flag state | `optimizelyApiSystem_6c1a` |

## Steps

1. **Receive feature flag mutation request**: Caller sends `POST`, `PUT`, or `DELETE` to `/feature-manager/*` with feature flag payload.
   - From: `internal Groupon service`
   - To: `expyService_apiResources`
   - Protocol: REST/HTTPS

2. **Route to service layer**: REST resource deserializes the request body (Jackson) and delegates to the service layer.
   - From: `expyService_apiResources`
   - To: `serviceLayer_Exp`
   - Protocol: Direct (in-process)

3. **Validate request**: Service layer validates the feature flag payload — checks required fields, project existence, and key uniqueness.
   - From: `serviceLayer_Exp`
   - To: `expyService_dataAccessLayer` (for existence checks)
   - Protocol: Direct (in-process)

4. **Persist change to MySQL**: Data access layer writes the create/update/delete operation to the features table in `continuumExpyMySql`.
   - From: `expyService_dataAccessLayer`
   - To: `continuumExpyMySql`
   - Protocol: JDBC / JDBI

5. **Sync to Optimizely API**: Service layer calls the Optimizely REST API via external clients to replicate the flag mutation in the Optimizely platform.
   - From: `expyService_externalClients`
   - To: `optimizelyApiSystem_6c1a`
   - Protocol: REST/HTTPS (Retrofit/OkHttp)

6. **Invalidate cache**: Service layer evicts the affected project/feature entries from the in-memory cache so the next read or bucketing decision picks up the updated state.
   - From: `serviceLayer_Exp`
   - To: `expyService_cacheLayer`
   - Protocol: Direct (in-process)

7. **Return response to caller**: REST resource serializes the result and returns HTTP 200/201/204 to the caller.
   - From: `expyService_apiResources`
   - To: `internal Groupon service`
   - Protocol: REST/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Validation failure (missing fields, unknown project) | Return HTTP 400 immediately; no DB write | Caller receives validation error; no state change |
| MySQL write failure | Rollback (if transactional); return HTTP 500 | No state change; caller receives server error |
| Optimizely API sync failure | Log error; MySQL write may still succeed | Local DB and cache updated; Optimizely out of sync — monitor for divergence |
| Optimizely API returns conflict | Log conflict; return error to caller | Caller must resolve conflict and retry |
| Cache invalidation failure | Log warning; stale cache may persist briefly | Cache will self-heal on TTL expiry or next datafile refresh |

## Sequence Diagram

```
Groupon Service  ->  expyService_apiResources: POST /feature-manager/{featureKey} {flagPayload}
expyService_apiResources  ->  serviceLayer_Exp: createFeatureFlag(flagPayload)
serviceLayer_Exp  ->  expyService_dataAccessLayer: getProject(projectId)
expyService_dataAccessLayer  ->  continuumExpyMySql: SELECT * FROM projects WHERE id = ?
continuumExpyMySql  -->  expyService_dataAccessLayer: project record
expyService_dataAccessLayer  -->  serviceLayer_Exp: project exists
serviceLayer_Exp  ->  expyService_dataAccessLayer: insertFeatureFlag(flagPayload)
expyService_dataAccessLayer  ->  continuumExpyMySql: INSERT INTO features (feature_key, project_id, ...)
continuumExpyMySql  -->  expyService_dataAccessLayer: ok
serviceLayer_Exp  ->  expyService_externalClients: syncFeatureFlag(optimizelyProjectId, flagPayload)
expyService_externalClients  ->  optimizelyApiSystem_6c1a: POST /v2/features {flagPayload}
optimizelyApiSystem_6c1a  -->  expyService_externalClients: HTTP 201 Created
expyService_externalClients  -->  serviceLayer_Exp: sync success
serviceLayer_Exp  ->  expyService_cacheLayer: invalidate(projectId)
serviceLayer_Exp  -->  expyService_apiResources: FeatureFlag{created}
expyService_apiResources  -->  Groupon Service: HTTP 201 {featureFlagResponse}
```

## Related

- Architecture dynamic view: `dynamic-feature-flag-crud` (not yet defined in model)
- Related flows: [Experiment Bucketing Decision](experiment-bucketing-decision.md), [Datafile Update Scheduled Job](datafile-update-scheduled-job.md)
