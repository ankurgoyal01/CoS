---
service: "audienceDerivationSpark"
title: "LINK SAD Base Table Generation"
generated: "2026-03-03"
type: flow
flow_name: "link-sad-base-table-generation"
flow_type: scheduled
trigger: "Cron or manual spark-submit via submit_link_sad_base_table_generation.py"
participants:
  - "continuumAudienceDerivationOps"
  - "continuumAudienceDerivationSpark"
  - "hdfsStorage"
  - "hiveMetastore"
  - "yarnCluster"
architecture_ref: "audienceDerivationSparkComponents"
---

# LINK SAD Base Table Generation

## Summary

The LINK SAD Base Table Generation flow produces pre-computed base-table datasets used to optimize LINK SAD (deal targeting/segmentation) operations. The `LinkSadBaseTableGeneratorMain` Spark entrypoint reads the latest system table data from Hive, applies transformation logic via the `LinkSadBaseTableGenerator` engine, and writes the resulting base-table dataset back to Hive. This flow is triggered by a dedicated submit script (`submit_link_sad_base_table_generation.py`) and runs separately from the standard users/bcookie derivation pipeline.

## Trigger

- **Type**: schedule or manual
- **Source**: `submit_link_sad_base_table_generation.py` (executed by cron or manually); Fabric task `fabricTasksAud` via `linkSadSubmitWrapper`
- **Frequency**: Scheduled (cadence not explicitly documented in crontab examples in README; run after users derivation completes)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operations Scripts | Constructs and executes spark-submit for LINK SAD job | `continuumAudienceDerivationOps` (`linkSadSubmitWrapper`) |
| Audience Derivation Spark App | Executes LINK SAD base-table build logic | `continuumAudienceDerivationSpark` (`linkSadBaseTableMain`, `linkSadGeneratorEngine`) |
| HDFS | Config and table data backing store | `hdfsStorage` |
| Hive Metastore | Source system tables and output base table | `hiveMetastore` |
| YARN Cluster | Executes Spark application | `yarnCluster` |

## Steps

1. **Submit LINK SAD job**: `submit_link_sad_base_table_generation.py` constructs and executes a `spark-submit` command targeting `LinkSadBaseTableGeneratorMain` with `--stage` and `--region` arguments.
   - From: `continuumAudienceDerivationOps` (`linkSadSubmitWrapper`)
   - To: YARN
   - Protocol: spark-submit

2. **Spark application start**: YARN allocates driver and executor containers; `LinkSadBaseTableGeneratorMain` initializes.
   - From: `continuumAudienceDerivationSpark`
   - To: `yarnCluster`
   - Protocol: Apache Spark on YARN

3. **Read latest system tables**: `LinkSadBaseTableGenerator` reads the most recent users derived system tables from Hive for the target region.
   - From: `continuumAudienceDerivationSpark`
   - To: `hiveMetastore`
   - Protocol: Spark SQL with Hive support

4. **Build base-table datasets**: Applies LINK SAD-specific transformation logic (deal-bucket assignment and segmentation optimization) to produce the base-table output.
   - From: `continuumAudienceDerivationSpark` (`LinkSadBaseTableGenerator`)
   - To: In-memory Spark computation
   - Protocol: Spark SQL / Dataset transformations

5. **Write LINK SAD base table**: Persists the generated base-table dataset to Hive.
   - From: `continuumAudienceDerivationSpark`
   - To: `hiveMetastore` (backed by `hdfsStorage`)
   - Protocol: Spark SQL with Hive support

6. **Job completion**: Spark application exits; YARN records finalStatus as SUCCEEDED.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Source system table not yet available | Spark job fails with table-not-found exception | Re-submit after users derivation completes |
| YARN resource contention | Job waits in queue or is preempted | Re-submit during off-peak hours |
| Hive write failure | Spark job fails | Partial write may exist; re-run overwrites via INSERT OVERWRITE |

## Sequence Diagram

```
submit_link_sad_base_table_generation.py -> YARN: spark-submit LinkSadBaseTableGeneratorMain
YARN -> AudienceDerivationSpark: allocate driver + executors
AudienceDerivationSpark -> HiveMetastore: read latest users_derived system tables
AudienceDerivationSpark -> AudienceDerivationSpark: build LINK SAD base-table datasets
AudienceDerivationSpark -> HiveMetastore: write LINK SAD base table
AudienceDerivationSpark --> YARN: job SUCCEEDED
```

## Related

- Architecture component view: `audienceDerivationSparkComponents`
- Related flows: [Nightly Audience Derivation](nightly-audience-derivation.md)
- Fabric trigger: `fab {stage}:{region} kickoff` (or direct `submit_link_sad_base_table_generation.py`)
