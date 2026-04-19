---
service: "expy-service"
title: "Datafile Parsing Error Logging"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "datafile-parsing-error-logging"
flow_type: event-driven
trigger: "Parse exception raised during datafile validation in the Datafile Update Scheduled Job"
participants:
  - "serviceLayer_Exp"
  - "expyService_dataAccessLayer"
  - "continuumExpyMySql"
architecture_ref: "dynamic-datafile-parse-error"
---

# Datafile Parsing Error Logging

## Summary

When a fetched Optimizely datafile fails to parse or validate during the scheduled refresh cycle, Expy Service captures the error and persists it to MySQL for audit and observability. This flow is triggered internally — never by an external caller — and ensures that datafile corruption, schema changes from Optimizely, or SDK compatibility issues are durably recorded. The last successfully parsed datafile remains active in the cache; no bucketing disruption occurs unless all cached datafiles are exhausted.

## Trigger

- **Type**: event
- **Source**: Parse exception raised within `serviceLayer_Exp` during the [Datafile Update Scheduled Job](datafile-update-scheduled-job.md)
- **Frequency**: On-demand — only when a datafile parse failure occurs

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Service Layer | Catches the parse exception and initiates error logging | `serviceLayer_Exp` |
| Data Access | Writes the structured error record to MySQL | `expyService_dataAccessLayer` |
| Expy MySQL | Persists the parse error record for audit and observability | `continuumExpyMySql` |

## Steps

1. **Parse exception raised**: During datafile validation (invoked from the scheduled refresh job), the Optimizely SDK or service layer raises a parse exception for the fetched datafile.
   - From: Optimizely SDK (in-process)
   - To: `serviceLayer_Exp`
   - Protocol: Java exception (in-process)

2. **Catch and structure error**: Service layer catches the exception and constructs a structured error record containing the SDK key, timestamp, error message, and raw payload reference.
   - From: `serviceLayer_Exp`
   - To: `serviceLayer_Exp` (internal handling)
   - Protocol: Direct (in-process)

3. **Persist error to MySQL**: Data access layer writes the structured error record to the datafile parse error table in `continuumExpyMySql`.
   - From: `expyService_dataAccessLayer`
   - To: `continuumExpyMySql`
   - Protocol: JDBC / JDBI

4. **Retain previous datafile in cache**: Service layer does NOT update the cache with the failed datafile — the previous valid datafile remains active for bucketing.
   - From: `serviceLayer_Exp`
   - To: `expyService_cacheLayer`
   - Protocol: Direct (in-process — no-op / cache retained)

5. **Resume scheduled job execution**: The scheduled job continues to process remaining SDK keys; a single parse failure does not abort the entire refresh cycle.
   - From: `quartzJobs`
   - To: `serviceLayer_Exp`
   - Protocol: Direct (in-process)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MySQL write fails while logging parse error | Log to application log; continue | Error may not be persisted to DB; application log captures it |
| Repeated parse errors for same SDK key | Each failure logged independently | Error log grows; alerting should trigger on sustained failures |
| Parse error on all SDK keys simultaneously | All errors logged; no datafiles updated | All cached datafiles become stale; escalate as P1 if Optimizely SDK incompatible |

## Sequence Diagram

```
OptimizelySDK  ->  serviceLayer_Exp: throw ParseException(sdkKey, reason)
serviceLayer_Exp  ->  serviceLayer_Exp: buildErrorRecord(sdkKey, timestamp, message)
serviceLayer_Exp  ->  expyService_dataAccessLayer: logParseError(errorRecord)
expyService_dataAccessLayer  ->  continuumExpyMySql: INSERT INTO datafile_parse_errors (sdk_key, error_msg, occurred_at)
continuumExpyMySql  -->  expyService_dataAccessLayer: ok
serviceLayer_Exp  ->  expyService_cacheLayer: retain existing cached datafile (no update)
serviceLayer_Exp  -->  quartzJobs: continue with next sdkKey
```

## Related

- Architecture dynamic view: `dynamic-datafile-parse-error` (not yet defined in model)
- Related flows: [Datafile Update Scheduled Job](datafile-update-scheduled-job.md), [Experiment Bucketing Decision](experiment-bucketing-decision.md)
