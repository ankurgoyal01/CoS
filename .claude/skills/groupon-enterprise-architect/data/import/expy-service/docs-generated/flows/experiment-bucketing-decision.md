---
service: "expy-service"
title: "Experiment Bucketing Decision"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "experiment-bucketing-decision"
flow_type: synchronous
trigger: "POST /experiments API call from an internal Groupon service"
participants:
  - "continuumExpyService"
  - "expyService_apiResources"
  - "serviceLayer_Exp"
  - "expyService_cacheLayer"
  - "expyService_dataAccessLayer"
  - "continuumExpyMySql"
architecture_ref: "dynamic-experiment-bucketing"
---

# Experiment Bucketing Decision

## Summary

This flow handles inbound experiment bucketing requests from internal Groupon services. The caller submits user and experiment context to `POST /experiments`; the service resolves the appropriate datafile from the in-memory cache (or MySQL on a cache miss), invokes the Optimizely core SDK to evaluate the experiment and assign a variation, and returns the bucketing decision synchronously. This flow is the primary consumer-facing responsibility of Expy Service.

## Trigger

- **Type**: api-call
- **Source**: Internal Groupon service calling `POST /experiments`
- **Frequency**: On-demand — per bucketing request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Expy Service (REST Resources) | Receives inbound HTTP request and routes to service layer | `expyService_apiResources` |
| Expy Service (Service Layer) | Orchestrates bucketing logic — resolves datafile, invokes SDK, returns decision | `serviceLayer_Exp` |
| Expy Service (Cache Layer) | Provides in-memory datafile and project lookup | `expyService_cacheLayer` |
| Expy Service (Data Access) | Fallback MySQL read on cache miss | `expyService_dataAccessLayer` |
| Expy MySQL | Persists datafiles and project config | `continuumExpyMySql` |

## Steps

1. **Receive bucketing request**: An internal service sends `POST /experiments` with user ID, experiment key, and attributes.
   - From: `internal Groupon service`
   - To: `expyService_apiResources`
   - Protocol: REST/HTTPS

2. **Route to service layer**: REST resource delegates to the service layer for business logic.
   - From: `expyService_apiResources`
   - To: `serviceLayer_Exp`
   - Protocol: Direct (in-process)

3. **Resolve datafile from cache**: Service layer looks up the relevant datafile (by SDK key / project) from the in-memory cache.
   - From: `serviceLayer_Exp`
   - To: `expyService_cacheLayer`
   - Protocol: Direct (in-process)

4. **Cache miss — read from MySQL** (conditional): If the datafile is not in cache, the data access layer reads it from MySQL.
   - From: `expyService_dataAccessLayer`
   - To: `continuumExpyMySql`
   - Protocol: JDBC / JDBI

5. **Populate cache**: Loaded datafile is stored back into the cache layer for subsequent requests.
   - From: `serviceLayer_Exp`
   - To: `expyService_cacheLayer`
   - Protocol: Direct (in-process)

6. **Invoke Optimizely SDK bucketing**: Service layer passes the datafile and user context to the Optimizely core SDK (embedded library, optimizely-core-api 4.1.1) to evaluate the experiment and determine the variation.
   - From: `serviceLayer_Exp`
   - To: Optimizely SDK (in-process)
   - Protocol: Direct (in-process library call)

7. **Return bucketing decision**: The resolved variation assignment is returned to the REST resource, which serializes the response and returns HTTP 200 to the caller.
   - From: `expyService_apiResources`
   - To: `internal Groupon service`
   - Protocol: REST/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Datafile not found in cache or MySQL | Return error response indicating unknown SDK key / project | HTTP 4xx returned to caller |
| Optimizely SDK parse error on datafile | Log parse error to MySQL; return error response | HTTP 5xx returned to caller; parse error logged |
| MySQL read failure on cache miss | Service layer handles exception; return error response | HTTP 5xx returned to caller |
| Unknown experiment key | Optimizely SDK returns null variation | Null/default variation returned to caller |

## Sequence Diagram

```
Groupon Service  ->  expyService_apiResources: POST /experiments {userId, experimentKey, attributes}
expyService_apiResources  ->  serviceLayer_Exp: bucket(userId, experimentKey, attributes)
serviceLayer_Exp  ->  expyService_cacheLayer: getDatafile(sdkKey)
expyService_cacheLayer  -->  serviceLayer_Exp: datafile (or null on miss)
serviceLayer_Exp  ->  expyService_dataAccessLayer: readDatafile(sdkKey) [on cache miss]
expyService_dataAccessLayer  ->  continuumExpyMySql: SELECT datafile WHERE sdk_key = ?
continuumExpyMySql  -->  expyService_dataAccessLayer: datafile record
expyService_dataAccessLayer  -->  serviceLayer_Exp: datafile
serviceLayer_Exp  ->  expyService_cacheLayer: putDatafile(sdkKey, datafile)
serviceLayer_Exp  ->  OptimizelySDK: activate(experimentKey, userId, attributes, datafile)
OptimizelySDK  -->  serviceLayer_Exp: variationKey
serviceLayer_Exp  -->  expyService_apiResources: BucketingDecision{variationKey}
expyService_apiResources  -->  Groupon Service: HTTP 200 {variationKey}
```

## Related

- Architecture dynamic view: `dynamic-experiment-bucketing` (not yet defined in model)
- Related flows: [Datafile Update Scheduled Job](datafile-update-scheduled-job.md), [Datafile Parsing Error Logging](datafile-parsing-error-logging.md)
