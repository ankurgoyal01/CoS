---
service: "AudiencePayloadSpark"
title: "SAD Aggregation"
generated: "2026-03-03"
type: flow
flow_name: "sad-aggregation"
flow_type: batch
trigger: "Manual Fabric command or cron schedule"
participants:
  - "continuumAudiencePayloadOps"
  - "continuumAudiencePayloadSpark"
  - "amsApi"
  - "hiveMetastore"
  - "cassandraKeyspaces"
  - "gcpBigtable"
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumAudiencePayloadSpark", "continuumAudiencePayloadOps"]
architecture_ref: "dynamic-payload_generation_flow"
---

# SAD Aggregation

## Summary

The SAD (Scheduled Audience Definition) aggregation flow performs a distributed map-reduce over PA membership Hive tables within a given time window, aggregating per-consumer `(pa_id; sad_id; custompayload; labels)` entries into compact composite records. The results are written to Cassandra SAD tables (`user_sad_v1`, `bcookie_sad_v1`) and to AWS Keyspaces (`audience_service` keyspace). A NonSAD variant writes to PA aggregate tables (`user_pa_agg`, `bcookie_pa_agg`). Pre-flight validation checks for unfinished SAD PAs and duplicate PA entries before writing begins.

## Trigger

- **Type**: manual / schedule
- **Source**: `continuumAudiencePayloadOps` — Fabric task `upload_pas_agg`
- **Frequency**: Typically daily; configurable `--number-of-prev-days` window

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Fabric scripts (`continuumAudiencePayloadOps`) | Submits `spark-submit` job | `continuumAudiencePayloadOps` |
| `PAPayloadAggregatorMain` | Spark entrypoint; parses CLI args, selects aggregation path (`sad`, `nonsad`, or `all`) | `paPayloadAggregatorMain` |
| `PAPayloadAggregator` / `PAPayloadAggregatorUnified` | Core aggregation engine; validates, aggregates, writes | `payloadAggregationEngine` |
| AMS API | Returns PA details (id, SAD id, labels, Hive table name) for the time window | `amsApi` |
| Hive Metastore | Per-PA audience Hive tables; SAD aggregation output staging tables | `hiveMetastore` |
| `CassandraWriter` | Writes aggregated SAD/NonSAD records to Cassandra | `cassandraAccessLayer` |
| `SADMetadataWriterBigtable` | Writes SAD metadata records to Bigtable | `bigtableAccessLayer` |
| AWS Keyspaces (via `CassandraClientFactory`) | Persists SAD aggregation results in cloud-native Cassandra-compatible store | `cassandraKeyspaces` |

## Steps

1. **Submit job**: Operator runs `fab production:na upload_pas_agg:users,-7,sad`.
   - From: `fabricTasks`
   - To: `submitPayloadScript`
   - Protocol: direct

2. **Build spark-submit command**: `CommandBuilder.upload_sads_by_days()` (or `upload_nonsads_by_days()`) assembles the invocation for `PAPayloadAggregatorMain`.
   - From: `submitPayloadScript`
   - To: YARN cluster
   - Protocol: spark-submit

3. **Pre-flight validation**: Before writing, `PAPayloadAggregator.findUnfinishedSADPA()` queries AMS API to detect any SAD PAs still in `PUBLICATION_IN_PROGRESS` state within the window. `findSADWithDupPA()` checks for SADs with duplicate available PAs. Either finding throws an exception, halting the job.
   - From: `payloadAggregationEngine`
   - To: `amsApi`
   - Protocol: HTTP

4. **Search AMS API for SAD PA list**: Calls `GET {amsHost}/searchPublishedAudience?sad=true&state=REJECTED&...` to get all SAD PAs in the aggregation window.
   - From: `payloadAggregationEngine` (`AudienceUtil.getPublishedAudiences`)
   - To: `amsApi`
   - Protocol: HTTP

5. **Load PA Hive tables and aggregate**: For each SAD, loads its per-PA Hive tables and performs a Spark map-reduce to merge all `(pa_id; sad_id; custompayload; labels)` into one row per consumer. For `all` mode, also processes NonSAD PAs.
   - From: `payloadAggregationEngine`
   - To: `hiveMetastore`
   - Protocol: Spark SQL

6. **Write SAD aggregation to Cassandra**: Writes `(consumer_id, sad_info_composite)` rows to `user_sad_v1` (or `bcookie_sad_v1`) keyed by SAD send date.
   - From: `cassandraAccessLayer`
   - To: `cassandraKeyspaces` (Cassandra cluster)
   - Protocol: Spark Cassandra Connector

7. **Write SAD metadata to Bigtable**: Persists SAD metadata (PA counts, record counts) via `SADMetadataWriterBigtable`.
   - From: `bigtableAccessLayer`
   - To: `gcpBigtable`
   - Protocol: gRPC (bigtable_client)

8. **Erase stale records**: Identifies consumers in the previous aggregation but not in the current run (`getOvertimeData`) and deletes their rows from Cassandra.
   - From: `cassandraAccessLayer`
   - To: `cassandraKeyspaces`
   - Protocol: Spark Cassandra Connector

9. **Stop SparkSession**: `spark.stop()` is called in `finally` block to prevent spurious retry on YARN.
   - From: `paPayloadAggregatorMain`
   - Protocol: Spark API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unfinished SAD PAs detected | Pre-flight check throws exception before any writes | Job fails cleanly; re-run after PA publication completes |
| Duplicate PAs in SAD | Pre-flight check throws exception | Job fails; investigate AMS SAD definition |
| AMS API unavailable | Retry with exponential backoff (3 attempts) | Job fails if retries exhausted |
| Cassandra write failure | Exception propagated; `spark.stop()` ensures clean shutdown | YARN reports failure; operator re-runs job |
| `spark.stop()` in finally | Always executed — prevents double-attempt on YARN | Ensures exactly-one YARN execution attempt |

## Sequence Diagram

```
Operator          -> fabricTasks          : fab production:na upload_pas_agg:users,-7,sad
fabricTasks       -> submitPayloadScript  : CommandBuilder.upload_sads_by_days()
submitPayloadScript -> PAPayloadAggregatorMain : spark-submit --env production-na --pa-type sad --number-of-prev-days -7
PAPayloadAggregatorMain -> AmsApi         : GET /searchPublishedAudience (validate unfinished/duplicate SAD PAs)
AmsApi            --> PAPayloadAggregatorMain : PA list (validated)
PAPayloadAggregatorMain -> AmsApi         : GET /searchPublishedAudience?sad=true (aggregation window)
AmsApi            --> PAPayloadAggregatorMain : [{ id, hiveTableName, sadId, labels, ... }, ...]
loop for each SAD PA
  PAPayloadAggregatorMain -> HiveMetastore : SELECT consumer_id, pa_data FROM <pa_hive_table>
  HiveMetastore    --> PAPayloadAggregatorMain : DataFrame
end
PAPayloadAggregatorMain -> PAPayloadAggregator : aggregate (map-reduce by consumer_id)
PAPayloadAggregator -> Cassandra           : Write (consumer_id, sad_composite) to user_sad_v1
Cassandra         --> PAPayloadAggregator  : ACK
PAPayloadAggregator -> BigtableHandler     : Write SAD metadata
BigtableHandler   --> PAPayloadAggregator  : ACK
PAPayloadAggregator -> Cassandra           : Erase stale (overtime) consumer rows
Cassandra         --> PAPayloadAggregator  : ACK
PAPayloadAggregatorMain -> YARN            : spark.stop()
```

## Related

- Architecture dynamic view: `dynamic-payload_generation_flow`
- Related flows: [PA Membership Upload](pa-membership-upload.md), [Hive to Keyspaces Retry](hive-to-keyspaces-retry.md)
