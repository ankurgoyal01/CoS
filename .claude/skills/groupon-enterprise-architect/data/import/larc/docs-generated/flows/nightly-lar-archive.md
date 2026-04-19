---
service: "larc"
title: "Nightly LAR Archive"
generated: "2026-03-03"
type: flow
flow_name: "nightly-lar-archive"
flow_type: scheduled
trigger: "TableArchiveWorkerManager scheduler fires on tableArchiveIntervalInSec interval"
participants:
  - "continuumTravelLarcService"
  - "continuumTravelLarcDatabase"
architecture_ref: "components-larc-service"
---

# Nightly LAR Archive

## Summary

The `NightlyLar` table accumulates a large volume of pricing records over time as QL2 feeds are ingested continuously. To keep this active table lean and queries performant, the table archive worker periodically identifies and migrates stale records from `NightlyLar` to the `NightlyLarArchived` table. The types of records eligible for archiving are controlled by three feature flags, allowing operators to tune archive aggressiveness.

## Trigger

- **Type**: schedule
- **Source**: `TableArchiveWorkerManager` scheduled worker (starts on `tableArchiveStartTime`, repeats every `tableArchiveIntervalInSec` seconds)
- **Frequency**: Configurable interval set in `workerConfig.tableArchiveIntervalInSec`; production value set in the environment YAML configuration

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| LARC Service (Worker Schedulers) | Drives the table archive loop on schedule | `continuumTravelLarcService` / `larcWorkerSchedulers` |
| LARC Service (Rate Computation) | Applies `NightlyLarArchiveHelper` archive logic | `continuumTravelLarcService` / `larcRateComputation` |
| LARC Service (Persistence Layer) | Reads from `NightlyLar`; writes to `NightlyLarArchived` | `continuumTravelLarcService` / `larcDataAccess` |
| LARC Database | Source (`NightlyLar`) and destination (`NightlyLarArchived`) of archive operations | `continuumTravelLarcDatabase` |

## Steps

1. **Scheduler wakes**: `TableArchiveWorkerManager` fires on the configured interval and invokes `NightlyLarArchiveHelper`.
   - From: `larcWorkerSchedulers`
   - To: `larcRateComputation`
   - Protocol: Direct (in-process)

2. **Identify stale records — old QL2 timestamps** (if `nightlyLarArchiveOldQl2Timestamps = true`): Query `NightlyLar` for records whose `ql2Timestamp` is older than the configured offset (default 7 days — `DEFAULT_QL2_FTP_OFFSET_IN_MIN = 10080`). These represent outdated pricing data that has been superseded.
   - From: `larcDataAccess`
   - To: `continuumTravelLarcDatabase`
   - Protocol: JDBC/MySQL

3. **Identify stale records — past nights** (if `nightlyLarArchivePastNights = true`): Query `NightlyLar` for records where `night < today`. Historical nights are no longer relevant to active LAR computation (LARs are only sent for future nights).
   - From: `larcDataAccess`
   - To: `continuumTravelLarcDatabase`
   - Protocol: JDBC/MySQL

4. **Identify stale records — unused records** (if `nightlyLarArchiveUnusedRecords = true`): Query `NightlyLar` for records not referenced by any active rate plan's `roomTypeUuid`. Unused records accumulate when hotel-rate-plan associations are dissolved.
   - From: `larcDataAccess`
   - To: `continuumTravelLarcDatabase`
   - Protocol: JDBC/MySQL

5. **Copy records to archive table**: Identified stale `NightlyLar` records are inserted into `NightlyLarArchived`.
   - From: `larcDataAccess`
   - To: `continuumTravelLarcDatabase`
   - Protocol: JDBC/MySQL (INSERT ... SELECT or batch insert)

6. **Delete archived records from active table**: Matching records are deleted from `NightlyLar` after successful insertion into `NightlyLarArchived`.
   - From: `larcDataAccess`
   - To: `continuumTravelLarcDatabase`
   - Protocol: JDBC/MySQL (DELETE)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Feature flags all disabled | No archive queries executed | `NightlyLar` table grows unbounded; no data loss |
| SQL error during archive copy | `SQLException` caught; logged as `DB_ERROR` | Partial archive possible; active table may retain some stale records; retried on next scheduler cycle |
| SQL error during delete | Delete transaction may be rolled back | Records remain in both `NightlyLar` and `NightlyLarArchived` (safe — duplicates handled by archive logic) |

## Sequence Diagram

```
TableArchiveWorkerManager -> NightlyLarArchiveHelper: Trigger archive cycle
NightlyLarArchiveHelper -> LARC Database: SELECT stale NightlyLar records (per enabled feature flags)
LARC Database --> NightlyLarArchiveHelper: Stale record set
NightlyLarArchiveHelper -> LARC Database: INSERT INTO NightlyLarArchived (stale records)
LARC Database --> NightlyLarArchiveHelper: Insert confirmation
NightlyLarArchiveHelper -> LARC Database: DELETE FROM NightlyLar (archived record IDs)
LARC Database --> NightlyLarArchiveHelper: Delete confirmation
```

## Related

- Architecture diagram: `components-larc-service`
- Related flows: [QL2 Feed Ingestion](ql2-feed-ingestion.md)
- Feature flags: `nightlyLarArchiveOldQl2Timestamps`, `nightlyLarArchivePastNights`, `nightlyLarArchiveUnusedRecords` — see [Configuration](../configuration.md)
