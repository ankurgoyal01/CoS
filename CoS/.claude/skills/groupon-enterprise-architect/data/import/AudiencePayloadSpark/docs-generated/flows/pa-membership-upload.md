---
service: "AudiencePayloadSpark"
title: "PA Membership Upload"
generated: "2026-03-03"
type: flow
flow_name: "pa-membership-upload"
flow_type: batch
trigger: "Manual Fabric command or cron schedule"
participants:
  - "continuumAudiencePayloadOps"
  - "continuumAudiencePayloadSpark"
  - "amsApi"
  - "hiveMetastore"
  - "cassandraKeyspaces"
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumAudiencePayloadSpark", "continuumAudiencePayloadOps"]
architecture_ref: "dynamic-payload_generation_flow"
---

# PA Membership Upload

## Summary

The PA membership upload flow fetches Published Audience (PA) definitions from the AMS API for a given time window, loads the corresponding Hive audience tables (one per PA), and writes or deletes `consumer_id:pa_id` and `bcookie:pa_id` mappings in Cassandra (`user_pa_v1`, `bcookie_pa_v1`) with a 48-hour TTL. This ensures that audience membership data in the real-time serving layer stays current with the latest scheduled and on-demand PA runs.

## Trigger

- **Type**: manual / schedule
- **Source**: `continuumAudiencePayloadOps` — Fabric tasks `batch_upload_pas` or `batch_delete_pas`
- **Frequency**: Typically daily; configurable `--number-of-prev-days` window

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Fabric scripts (`continuumAudiencePayloadOps`) | Submits `spark-submit` job | `continuumAudiencePayloadOps` |
| `PAPayloadGeneratorMain` | Spark entrypoint; parses CLI args, configures SparkSession | `paPayloadGeneratorMain` |
| `PAPayloadGenerator` | Core generator; queries AMS API, iterates PA Hive tables | `attributePayloadEngine` |
| AMS API (`/searchPublishedAudience`) | Returns list of PA details (ID, SAD ID, Hive table name, record count) for the time window | `amsApi` |
| Hive Metastore | Per-PA audience tables containing consumer/bcookie member lists | `hiveMetastore` |
| `CassandraWriter` | Writes and deletes PA membership rows to Cassandra with TTL | `cassandraAccessLayer` |

## Steps

1. **Submit job**: Operator runs `fab production:na batch_upload_pas:users,-2,true`.
   - From: `fabricTasks`
   - To: `submitPayloadScript`
   - Protocol: direct

2. **Build spark-submit command**: `CommandBuilder.upload_pamembership_by_days()` builds the `spark-submit` invocation for `PAPayloadGeneratorMain` with `--env`, `--payload-type`, `--number-of-prev-days`, `--pa-state`.
   - From: `submitPayloadScript`
   - To: YARN cluster
   - Protocol: spark-submit

3. **Search AMS API for PA list**: For each day in the window (e.g., last 2 days), calls `GET {amsHost}/searchPublishedAudience?startDate=...&endDate=...&sad=true&state=PUBLISHED&audienceType=users` (and again for `audienceType=universal`). Retries up to 3 times with exponential backoff.
   - From: `attributePayloadEngine` (`AudienceUtil.getPublishedAudiences`)
   - To: `amsApi`
   - Protocol: HTTP

4. **Load each PA Hive table**: For each PA returned, reads the PA's Hive table (containing the member consumer_id list) using `spark.sql(SELECT consumer_id FROM <hiveTableName>)`.
   - From: `attributePayloadEngine`
   - To: `hiveMetastore`
   - Protocol: Spark SQL

5. **Write PA memberships to Cassandra**: Writes `(consumer_id, pa_id, segment_label, custom_payload)` rows to `user_pa_v1` (or `bcookie_pa_v1`). TTL applied: `cassPaTableTtlInSeconds = 172800` (48 hours).
   - From: `cassandraAccessLayer`
   - To: `cassandraKeyspaces` (`user_pa_v1` / `bcookie_pa_v1`)
   - Protocol: Spark Cassandra Connector

6. **Update record count in AMS**: After writing, calls `PUT {amsHost}/published-audience/update-record-count?isBcookieRecordCount=true` with the per-PA record counts.
   - From: `attributePayloadEngine` (`AudienceUtil.updateRecordCountToAms`)
   - To: `amsApi`
   - Protocol: HTTP PUT

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AMS API search returns error | Retry with exponential backoff (3 attempts) | Job fails if retries exhausted |
| PA Hive table missing or stale | Exception logged; job continues for other PAs | Partial write; re-run required for failed PAs |
| Cassandra write failure | Exception thrown from Spark Cassandra Connector | Spark job fails; YARN reports failure |
| AMS record count update fails | Exception propagated from `putRequest` | Job fails; record counts may be stale in AMS |

## Sequence Diagram

```
Operator          -> fabricTasks         : fab production:na batch_upload_pas:users,-2,true
fabricTasks       -> submitPayloadScript : CommandBuilder.upload_pamembership_by_days()
submitPayloadScript -> PAPayloadGeneratorMain : spark-submit --env production-na --payload-type users --number-of-prev-days -2
PAPayloadGeneratorMain -> AmsApi         : GET /searchPublishedAudience?startDate=...&endDate=...&sad=true&state=PUBLISHED
AmsApi            --> PAPayloadGeneratorMain : [{ id, hiveTableName, sadId, ... }, ...]
loop for each PA
  PAPayloadGeneratorMain -> HiveMetastore : SELECT consumer_id FROM <pa_hive_table>
  HiveMetastore    --> PAPayloadGeneratorMain : DataFrame (member list)
  PAPayloadGeneratorMain -> Cassandra     : Write (consumer_id, pa_id) to user_pa_v1 [TTL=172800s]
  Cassandra        --> PAPayloadGeneratorMain : ACK
end
PAPayloadGeneratorMain -> AmsApi         : PUT /published-audience/update-record-count
AmsApi            --> PAPayloadGeneratorMain : 204 OK
```

## Related

- Architecture dynamic view: `dynamic-payload_generation_flow`
- Related flows: [Attribute Payload Upload](attribute-payload-upload.md), [SAD Aggregation](sad-aggregation.md)
