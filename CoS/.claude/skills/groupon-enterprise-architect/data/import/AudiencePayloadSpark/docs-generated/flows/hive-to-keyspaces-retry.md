---
service: "AudiencePayloadSpark"
title: "Hive to Keyspaces Retry"
generated: "2026-03-03"
type: flow
flow_name: "hive-to-keyspaces-retry"
flow_type: batch
trigger: "Manual operator invocation (recovery / migration)"
participants:
  - "continuumAudiencePayloadOps"
  - "continuumAudiencePayloadSpark"
  - "hiveMetastore"
  - "cassandraKeyspaces"
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumAudiencePayloadSpark", "continuumAudiencePayloadOps"]
architecture_ref: "dynamic-payload_generation_flow"
---

# Hive to Keyspaces Retry

## Summary

The Hive to Keyspaces retry flow provides a recovery and migration path for writing pre-computed SAD aggregation results stored in a Hive table directly to AWS Keyspaces, bypassing the normal `PAPayloadAggregator` pipeline. It uses a mutex locking row in Keyspaces to prevent concurrent runs, loads the specified source Hive table, writes the SAD payload records, removes stale records, and cleans up the lock on completion or failure. This flow is used when a previous SAD aggregation wrote results to Hive but failed before completing the Keyspaces write.

## Trigger

- **Type**: manual
- **Source**: Operator-invoked `spark-submit` targeting `HiveToKeyspaceWriter` (via `submitPayloadScript`)
- **Frequency**: On-demand (recovery/migration use case)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Fabric / manual scripts (`continuumAudiencePayloadOps`) | Submits `spark-submit` job | `continuumAudiencePayloadOps` |
| `HiveToKeyspaceWriter` | Spark entrypoint; validates args, acquires lock, orchestrates writes | `hiveToKeyspaceWriterMain` |
| `PAPayloadAggregator` | Reused aggregation utilities (table existence checks, load, write, erase) | `payloadAggregationEngine` |
| Hive Metastore | Source Hive table (pre-computed SAD aggregation output) | `hiveMetastore` |
| `CassandraClientFactory` | Initialises DataStax Java Driver session to AWS Keyspaces | `cassandraAccessLayer` |
| AWS Keyspaces (`audience_service` keyspace) | Target store for SAD payload records; also holds locking row | `cassandraKeyspaces` |
| `SADMetadataWriter` | Reads/writes the locking row in Keyspaces | `bigtableAccessLayer` (metadata sub-component) |

## Steps

1. **Submit job**: Operator invokes `HiveToKeyspaceWriter` via `submitPayloadScript` with `--send-date <sad_table_name>` and `--source-Hive-Table <hive_table_name>`.
   - From: `submitPayloadScript`
   - To: YARN cluster
   - Protocol: spark-submit

2. **Validate arguments**: Checks that `--send-date` and `--source-Hive-Table` both contain `user_sad`. Throws `RuntimeException` if invalid, preventing accidental writes.
   - From: `hiveToKeyspaceWriterMain`
   - Protocol: in-process validation

3. **Initialise Keyspaces session**: Creates `CassandraClientFactory.get(env, AWSCredentials)` using IAM credentials from JSON config. Executes `USE audience_service`.
   - From: `hiveToKeyspaceWriterMain`
   - To: `cassandraKeyspaces` (AWS Keyspaces endpoint `cassandra.us-west-1.amazonaws.com:9142`)
   - Protocol: DataStax Java Driver (CQL over SSL)

4. **Acquire locking row**: Checks if `writing` metadata row already exists via `SADMetadataWriter.getTableName("writing")`. If present, throws exception. If absent, inserts the locking row `INSERT INTO <sad_table> (id, ...) VALUES ('writing', ...)`.
   - From: `hiveToKeyspaceWriterMain`
   - To: `cassandraKeyspaces`
   - Protocol: CQL

5. **Register shutdown hook**: Registers `sys.addShutdownHook` to delete the locking row and close the session if the JVM exits unexpectedly.
   - From: `hiveToKeyspaceWriterMain`
   - Protocol: JVM shutdown hook

6. **Load source Hive table**: Calls `ppa.hiveTableExists(sourceHiveTable)` and `ppa.loadHiveTable(sourceHiveTable)` to load the pre-computed SAD aggregation DataFrame.
   - From: `payloadAggregationEngine`
   - To: `hiveMetastore`
   - Protocol: Spark SQL

7. **Write SAD records to Keyspaces**: Renames key column to `id` and SAD info column to `<sendDateColumn>`, then calls `ppa.writeToCassandraNew(sadDF, List("id", sendDateColumn))`.
   - From: `payloadAggregationEngine` → `cassandraAccessLayer`
   - To: `cassandraKeyspaces`
   - Protocol: Spark Cassandra Connector / DataStax

8. **Remove stale records**: If the previous-run Hive table (`sendDateColumn` table) exists, computes overtime consumers (`getOvertimeData`) and calls `ppa.eraseInCassandraNew()` to delete them from Keyspaces.
   - From: `payloadAggregationEngine`
   - To: `cassandraKeyspaces`
   - Protocol: CQL via DataStax

9. **Release locking row**: In `finally` block, calls `metadataWriter.deleteMetadata("writing")` and closes the Keyspaces session.
   - From: `hiveToKeyspaceWriterMain`
   - To: `cassandraKeyspaces`
   - Protocol: CQL DELETE

10. **Stop SparkSession**: `spark.stop()` called in outer `finally` to ensure clean YARN exit.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Locking row already exists | Exception thrown immediately | Job halts; operator must manually verify/remove the `writing` row |
| Invalid `--send-date` or `--source-Hive-Table` arg | `RuntimeException` before any Keyspaces connection | Job fails with clear error message |
| JVM crash during write | Shutdown hook deletes locking row and closes session | Lock is released; re-run is safe |
| Source Hive table not found | `hiveTableExists` returns false; `aggDF = emptyDataFrame` | Write is skipped; no Keyspaces mutation |
| Keyspaces write failure | Exception thrown; finally block releases lock | Job fails; lock is cleaned up; safe to retry |

## Sequence Diagram

```
Operator             -> HiveToKeyspaceWriter  : spark-submit --env production-na --send-date user_sad_1679796969 --source-Hive-Table user_sad_1679796969_ts
HiveToKeyspaceWriter -> HiveToKeyspaceWriter  : validate args (must contain 'user_sad')
HiveToKeyspaceWriter -> Keyspaces             : USE audience_service
HiveToKeyspaceWriter -> Keyspaces             : SELECT id FROM <sad_table> WHERE id='writing'
Keyspaces            --> HiveToKeyspaceWriter : [] (no locking row)
HiveToKeyspaceWriter -> Keyspaces             : INSERT INTO <sad_table> (id) VALUES ('writing')
HiveToKeyspaceWriter -> HiveMetastore         : EXISTS/LOAD user_sad_1679796969_ts
HiveMetastore        --> HiveToKeyspaceWriter : DataFrame (SAD records)
HiveToKeyspaceWriter -> Keyspaces             : Write (id, user_sad_1679796969) rows [SAD payload]
Keyspaces            --> HiveToKeyspaceWriter : ACK
HiveToKeyspaceWriter -> HiveMetastore         : EXISTS/LOAD user_sad_1679796969 (previous table)
HiveToKeyspaceWriter -> HiveToKeyspaceWriter  : getOvertimeData(new, old)
HiveToKeyspaceWriter -> Keyspaces             : DELETE stale consumer rows
Keyspaces            --> HiveToKeyspaceWriter : ACK
HiveToKeyspaceWriter -> Keyspaces             : DELETE WHERE id='writing' (release lock)
HiveToKeyspaceWriter -> YARN                  : spark.stop()
```

## Related

- Architecture dynamic view: `dynamic-payload_generation_flow`
- Related flows: [SAD Aggregation](sad-aggregation.md), [PA Membership Upload](pa-membership-upload.md)
