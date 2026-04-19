---
service: "expy-service"
title: "Datafile Update Scheduled Job"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "datafile-update-scheduled-job"
flow_type: scheduled
trigger: "Quartz scheduler fires datafile refresh job on configured periodic interval"
participants:
  - "quartzJobs"
  - "serviceLayer_Exp"
  - "expyService_externalClients"
  - "expyService_dataAccessLayer"
  - "expyService_cacheLayer"
  - "continuumExpyMySql"
  - "optimizelyCdnSystem_9d42"
  - "optimizelyDataListenerSystem_5b7f"
architecture_ref: "dynamic-datafile-update"
---

# Datafile Update Scheduled Job

## Summary

This flow keeps Expy Service's local copy of Optimizely datafiles current. The Quartz scheduler fires the datafile refresh job at a configured interval; the job fetches the latest datafile from the Optimizely CDN and/or Data Listener via HTTP, validates and parses the payload, writes the updated datafile to MySQL, and refreshes the in-memory cache so that subsequent bucketing decisions use the most recent experiment configuration.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler (`quartzJobs` component, backed by Quartz tables in `continuumExpyMySql`)
- **Frequency**: Periodic — interval configured in JTier YAML config (exact cadence not defined in architecture model)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Quartz Jobs | Initiates the scheduled datafile refresh | `quartzJobs` |
| Service Layer | Orchestrates datafile fetch, parse, and storage logic | `serviceLayer_Exp` |
| External Clients | HTTP calls to Optimizely CDN and Data Listener | `expyService_externalClients` |
| Data Access | Writes updated datafile to MySQL | `expyService_dataAccessLayer` |
| Cache Layer | Refreshes in-memory datafile cache after MySQL write | `expyService_cacheLayer` |
| Expy MySQL | Stores updated datafile records and Quartz job state | `continuumExpyMySql` |
| Optimizely CDN | Source of current Optimizely datafiles | `optimizelyCdnSystem_9d42` |
| Optimizely Data Listener | Source of event-specific datafiles | `optimizelyDataListenerSystem_5b7f` |

## Steps

1. **Quartz job fires**: The Quartz scheduler triggers the datafile update job on schedule.
   - From: Quartz scheduler (internal)
   - To: `quartzJobs`
   - Protocol: Quartz trigger (in-process)

2. **Trigger service layer refresh**: Quartz job delegates datafile fetch logic to the service layer.
   - From: `quartzJobs`
   - To: `serviceLayer_Exp`
   - Protocol: Direct (in-process)

3. **Fetch datafile from Optimizely CDN**: Service layer instructs external clients to GET the current datafile for each registered SDK key from the Optimizely CDN.
   - From: `expyService_externalClients`
   - To: `optimizelyCdnSystem_9d42`
   - Protocol: HTTPS (Retrofit/OkHttp)

4. **Fetch event datafile from Data Listener**: Service layer instructs external clients to fetch event-specific datafiles from the Optimizely Data Listener.
   - From: `expyService_externalClients`
   - To: `optimizelyDataListenerSystem_5b7f`
   - Protocol: REST/HTTPS (Retrofit/OkHttp)

5. **Parse and validate datafile**: Service layer parses the fetched datafile payload using the Optimizely SDK and validates its structure. On parse failure, the error logging flow is triggered (see [Datafile Parsing Error Logging](datafile-parsing-error-logging.md)).
   - From: `serviceLayer_Exp`
   - To: Optimizely SDK (in-process)
   - Protocol: Direct (in-process library call)

6. **Write updated datafile to MySQL**: On successful parse, the data access layer writes the new datafile record to `continuumExpyMySql`.
   - From: `expyService_dataAccessLayer`
   - To: `continuumExpyMySql`
   - Protocol: JDBC / JDBI

7. **Refresh in-memory cache**: Service layer updates the cache layer with the freshly written datafile so bucketing requests are served the latest version immediately.
   - From: `serviceLayer_Exp`
   - To: `expyService_cacheLayer`
   - Protocol: Direct (in-process)

8. **Update Quartz job state**: Quartz records the successful job execution in the Quartz tables in MySQL.
   - From: `quartzJobs`
   - To: `continuumExpyMySql`
   - Protocol: JDBC (Quartz internal)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Optimizely CDN unreachable | Retry per Retrofit/OkHttp timeout config; log failure | Last cached datafile remains active; job records failure |
| Data Listener unreachable | Retry per Retrofit/OkHttp timeout config; log failure | Last cached event datafile remains active |
| Datafile parse failure | Trigger error logging flow; skip MySQL write | Parse error logged to MySQL; old datafile retained in cache |
| MySQL write failure | Log exception; cache not updated | Stale datafile may persist until next successful job run |

## Sequence Diagram

```
Quartz  ->  quartzJobs: fire datafile refresh trigger
quartzJobs  ->  serviceLayer_Exp: refreshDatafiles()
serviceLayer_Exp  ->  expyService_externalClients: fetchDatafile(sdkKey)
expyService_externalClients  ->  optimizelyCdnSystem_9d42: GET /datafiles/{sdkKey}.json
optimizelyCdnSystem_9d42  -->  expyService_externalClients: datafile JSON
expyService_externalClients  ->  optimizelyDataListenerSystem_5b7f: GET event datafile
optimizelyDataListenerSystem_5b7f  -->  expyService_externalClients: event datafile JSON
expyService_externalClients  -->  serviceLayer_Exp: datafile payloads
serviceLayer_Exp  ->  OptimizelySDK: parse(datafileJSON)
OptimizelySDK  -->  serviceLayer_Exp: parsed datafile (or ParseException)
serviceLayer_Exp  ->  expyService_dataAccessLayer: updateDatafile(sdkKey, datafile)
expyService_dataAccessLayer  ->  continuumExpyMySql: UPDATE datafiles SET content = ? WHERE sdk_key = ?
continuumExpyMySql  -->  expyService_dataAccessLayer: ok
serviceLayer_Exp  ->  expyService_cacheLayer: invalidate(sdkKey); put(sdkKey, datafile)
quartzJobs  ->  continuumExpyMySql: UPDATE quartz_job_details (last_fired)
```

## Related

- Architecture dynamic view: `dynamic-datafile-update` (not yet defined in model)
- Related flows: [Experiment Bucketing Decision](experiment-bucketing-decision.md), [Datafile Parsing Error Logging](datafile-parsing-error-logging.md), [S3 Backup Copy Daily](s3-backup-copy-daily.md)
