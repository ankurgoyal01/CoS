---
service: "audienceDerivationSpark"
title: "Nightly Audience Derivation"
generated: "2026-03-03"
type: flow
flow_name: "nightly-audience-derivation"
flow_type: scheduled
trigger: "Cron schedule (daily per region) or manual spark-submit"
participants:
  - "continuumAudienceDerivationOps"
  - "continuumAudienceDerivationSpark"
  - "hdfsStorage"
  - "hiveMetastore"
  - "yarnCluster"
  - "amsApi"
architecture_ref: "dynamic-nightly_derivation_flow"
---

# Nightly Audience Derivation

## Summary

The nightly audience derivation flow is the primary batch pipeline of this service. It transforms raw Groupon EDW/Hive source tables into enriched audience system tables (`users_derived_{timestamp}` and `bcookie_derived_{timestamp}`) for NA and EMEA regions. The operations container submits a Spark job that reads YAML-defined SQL transformation sequences from HDFS, executes them as a chain of Spark SQL tempviews against Hive source data, and writes the final derived table back to Hive. After derivation, field metadata is synchronized to the AMS database.

## Trigger

- **Type**: schedule
- **Source**: Crontab on `cerebro-audience-job-submitter1.snc1` (production) executing `submit_derivation.py`
- **Frequency**: Daily — four runs per day:
  - NA bcookie: 10:14 UTC
  - NA users: 10:15 UTC
  - EMEA bcookie: 19:01 UTC
  - EMEA users: 19:02 UTC

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operations Scripts | Submits Spark job; uploads YAML config to HDFS | `continuumAudienceDerivationOps` |
| Audience Derivation Spark App | Executes derivation SQL pipeline; writes output tables | `continuumAudienceDerivationSpark` |
| HDFS | Stores YAML derivation config; backs Hive table data | `hdfsStorage` |
| Hive Metastore | Provides source table reads; receives derived table writes | `hiveMetastore` |
| YARN Cluster | Schedules and executes Spark application | `yarnCluster` |
| AMS API | Provides current system table name; receives field metadata sync | `amsApi` |

## Steps

1. **Config upload (deploy phase)**: Operator or automated deploy uploads YAML config directories to HDFS.
   - From: `continuumAudienceDerivationOps` (`fabfile.py` deploy task)
   - To: `hdfsStorage` at `hdfs://cerebro-namenode/user/audiencedeploy/derivation/{stage}/{configDir}/`
   - Protocol: `hdfs dfs -put`

2. **Job submission**: Cron triggers `submit_derivation.py` which constructs and executes a `spark-submit` command targeting `AudienceDerivationMain`.
   - From: `continuumAudienceDerivationOps` (`submit_derivation.py`)
   - To: `continuumAudienceDerivationSpark` (YARN application)
   - Protocol: spark-submit (`--master yarn --deploy-mode cluster`)

3. **Spark application start**: YARN allocates driver and executor containers; Spark application initializes with Hive support.
   - From: `continuumAudienceDerivationSpark`
   - To: `yarnCluster`
   - Protocol: Apache Spark on YARN

4. **YAML config load**: `AudienceDerivationMain` reads ordered YAML derivation config files from HDFS to build the tempview step sequence.
   - From: `continuumAudienceDerivationSpark`
   - To: `hdfsStorage`
   - Protocol: HDFS read

5. **AMS table name fetch**: Spark app queries AMS API to retrieve the current system table name prefix for output naming.
   - From: `continuumAudienceDerivationSpark`
   - To: `amsApi`
   - Protocol: HTTP / gRPC

6. **Source table reads**: `TableBuilder` / `AudienceDerivation` executes the first tempview step, reading from the designated source Hive table (e.g., `prod_groupondw.user_entity_attribute_02`).
   - From: `continuumAudienceDerivationSpark` (Spark SQL)
   - To: `hiveMetastore`
   - Protocol: Spark SQL with Hive support

7. **Sequential tempview execution**: For each numbered YAML step, the engine registers a Spark SQL tempview by executing the step's SQL query against the previous tempview or source table. Steps execute in numeric order (e.g., steps 01–17 for NA users, 01–38 for EMEA users).
   - From: `continuumAudienceDerivationSpark` (TableBuilder)
   - To: In-memory Spark SQL context
   - Protocol: Spark SQL

8. **Derived table write**: After all tempview steps complete, executes `CREATE TABLE {timestamp_name}` DDL followed by `INSERT OVERWRITE TABLE ... SELECT * FROM {final_tempview}` to persist the derived output.
   - From: `continuumAudienceDerivationSpark`
   - To: `hiveMetastore` (backed by `hdfsStorage`)
   - Protocol: Spark SQL with Hive support (dynamic partitioning by `user_category`, `user_brand_affiliation` or `country_iso_code_2`)

9. **AMS field sync**: After successful derivation, `FieldSyncMain` reads the derived table schema from Hive and pushes field metadata updates to AMS, adding new fields and updating existing ones.
   - From: `continuumAudienceDerivationSpark` (`FieldSyncMain`)
   - To: `amsApi`
   - Protocol: HTTP / gRPC

10. **Job completion**: Spark application exits; YARN records finalStatus as SUCCEEDED; cron log entry written.
    - From: `yarnCluster`
    - To: Cron log at `/home/audiencedeploy/ams/derivation/derivation_cron.log`

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| YAML config not found on HDFS | Spark job throws exception at startup | Job fails; YARN finalStatus = FAILED; cron log captures error |
| Source Hive table missing or schema changed | SparkSQL AnalysisException during tempview step | Job fails at the failing step; no partial write to Hive |
| YARN resource unavailability | spark-submit fails or job is queued | Job waits in YARN queue or fails; re-submit manually |
| AMS API unavailable at step 5 | HTTP/gRPC exception; job may fail or proceed with default table name | Depends on implementation; AMS sync step would fail at step 9 |
| AMS field sync failure (step 9) | Post-derivation step fails | Derived table is already written; field sync can be re-run manually via `fab sync_ams_fields` |
| Job preempted by YARN | YARN KILLED state | Re-submit manually; no automatic retry |

## Sequence Diagram

```
submit_derivation.py -> YARN: spark-submit AudienceDerivationMain (--master yarn)
YARN -> AudienceDerivationSpark: allocate driver + executors
AudienceDerivationSpark -> HDFS: read YAML config files
AudienceDerivationSpark -> AMS API: fetch current system table name
AudienceDerivationSpark -> HiveMetastore: read source tables (tempview step 01)
AudienceDerivationSpark -> AudienceDerivationSpark: execute tempview steps 02..N (SQL chain)
AudienceDerivationSpark -> HiveMetastore: CREATE TABLE + INSERT OVERWRITE (derived output)
AudienceDerivationSpark -> AMS API: sync field metadata (FieldSyncMain)
AudienceDerivationSpark --> YARN: job SUCCEEDED
YARN --> cron log: exit 0
```

## Related

- Architecture dynamic view: `dynamic-nightly_derivation_flow`
- Related flows: [AMS Field Sync](ams-field-sync.md), [LINK SAD Base Table Generation](link-sad-base-table-generation.md)
- See [Configuration](../configuration.md) for YAML config schema
- See [Data Stores](../data-stores.md) for derived table schemas
