---
service: "watson-realtime"
title: "KS Table Trim"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "ks-table-trim"
flow_type: scheduled
trigger: "Timer / scheduled job invocation"
participants:
  - "continuumKsTableTrimmerService"
  - "cassandraKeyspaces_5c9a"
architecture_ref: "components-ks-table-trimmer-components"
---

# KS Table Trim

## Summary

The KS Table Trim flow is a scheduled maintenance job that deletes aged rows from Cassandra/Keyspaces analytics tables. `continuumKsTableTrimmerService` connects to `cassandraKeyspaces_5c9a` using the DataStax Cassandra driver (with AWS SigV4 authentication for Amazon Keyspaces) and executes delete or TTL-based trim operations against the analytics counter tables written by `continuumAnalyticsKsService`. This prevents unbounded table growth that would degrade Cassandra query performance and storage costs over time.

## Trigger

- **Type**: schedule
- **Source**: Container orchestrator scheduled job (cron/periodic job)
- **Frequency**: Scheduled — specific interval not discoverable from architecture model; contact dnd-ds-search-ranking@groupon.com for schedule details

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Keyspaces Table Trimmer | Executes the scheduled trim operation | `continuumKsTableTrimmerService` |
| Cassandra / Amazon Keyspaces | Target store from which aged rows are removed | `cassandraKeyspaces_5c9a` |

## Steps

1. **Job invoked**: The container orchestrator triggers `continuumKsTableTrimmerService` on its configured schedule.
   - From: Scheduler (orchestrator)
   - To: `continuumKsTableTrimmerService`
   - Protocol: direct (process start)

2. **Connect to Keyspaces**: The trimmer job establishes a connection to `cassandraKeyspaces_5c9a` using the DataStax Cassandra driver, signing each request with AWS SigV4.
   - From: `continuumKsTableTrimmerService`
   - To: `cassandraKeyspaces_5c9a`
   - Protocol: Cassandra (with AWS SigV4 auth)

3. **Identify aged rows**: The job queries or calculates the set of rows that exceed the configured retention threshold (by timestamp, partition key range, or TTL boundary).
   - From: `continuumKsTableTrimmerService`
   - To: `cassandraKeyspaces_5c9a`
   - Protocol: Cassandra (CQL SELECT)

4. **Delete aged rows**: The job executes batch or individual DELETE statements against the identified rows in `cassandraKeyspaces_5c9a`.
   - From: `continuumKsTableTrimmerService`
   - To: `cassandraKeyspaces_5c9a`
   - Protocol: Cassandra (CQL DELETE)

5. **Job completes**: The trimmer process exits cleanly after completing the trim operation.
   - From: `continuumKsTableTrimmerService`
   - To: Scheduler (orchestrator)
   - Protocol: process exit code

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Cassandra connection failure | Job process exits with error; orchestrator may retry on next schedule | Tables remain untrimmed; table growth continues until next successful run |
| AWS SigV4 credential expiry | Authentication failure on Cassandra connection | Job fails; requires credential rotation and re-trigger |
| Partial trim (job killed mid-run) | Next scheduled run retries trim from retention boundary | Some aged rows may persist one additional cycle; no data corruption risk |
| Table size exceeds trim capacity per run | Next scheduled run continues from last completed range | Eventual consistency; trimming catches up over multiple cycles |

## Sequence Diagram

```
Scheduler                   -> continuumKsTableTrimmerService: Invoke trim job (scheduled)
continuumKsTableTrimmerService -> cassandraKeyspaces_5c9a: Establish connection (Cassandra driver + SigV4)
cassandraKeyspaces_5c9a      --> continuumKsTableTrimmerService: Connection established
continuumKsTableTrimmerService -> cassandraKeyspaces_5c9a: Query aged rows (CQL SELECT)
cassandraKeyspaces_5c9a      --> continuumKsTableTrimmerService: Return row identifiers
continuumKsTableTrimmerService -> cassandraKeyspaces_5c9a: Delete aged rows (CQL DELETE)
cassandraKeyspaces_5c9a      --> continuumKsTableTrimmerService: Acknowledged
continuumKsTableTrimmerService -> Scheduler: Exit 0 (success)
```

## Related

- Architecture component view: `components-ks-table-trimmer-components`
- Related flows: [Analytics Aggregation](analytics-aggregation.md)
