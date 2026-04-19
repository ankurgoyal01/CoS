---
service: "afgt"
title: "Teradata to Hive Data Transfer"
generated: "2026-03-03"
type: flow
flow_name: "teradata-to-hive-transfer"
flow_type: batch
trigger: "Triggered within afgt_sb_td DAG after rma_promos staging stage completes"
participants:
  - "continuumAfgtDataprocBatch"
  - "continuumAfgtHiveDataset"
  - "edw"
architecture_ref: "dynamic-afgt_td_to_hive_load"
---

# Teradata to Hive Data Transfer

## Summary

This flow covers the data extraction and loading sub-flow within the `afgt_sb_td` DAG that transfers the enriched financial analytics data from the Teradata staging table (`sb_rmaprod.analytics_fgt_transfer_gcp`) into the IMA Hive data lake. It uses a BTEQ extraction step to populate the Teradata transfer table, then uses Apache Sqoop for the parallel bulk import into Hive on GCS, followed by a Hive Tez job to produce the final partitioned analytics table enriched with RFM segments.

## Trigger

- **Type**: event (Airflow task dependency)
- **Source**: `rma_promos` task success within `afgt_sb_td` DAG; the `afgt_td_tmp` task (BTEQ extraction) runs first, and `afgt_sqoop_tmp` only starts once `afgt_td_tmp` completes
- **Frequency**: Daily (as part of the main pipeline)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| AFGT Dataproc Batch Jobs | Executes BTEQ extraction, Sqoop import, and Hive load jobs | `continuumAfgtDataprocBatch` |
| Teradata EDW | Source — provides `sb_rmaprod.analytics_fgt_transfer_gcp` staging data | `edw` |
| AFGT Hive Dataset | Destination — receives data into `ima.analytics_fgt_tmp_zo` and `ima.analytics_fgt` | `continuumAfgtHiveDataset` |

## Steps

1. **Populate Teradata transfer table** (`afgt_td_tmp`): Runs `afgt_td_extract.sh` as a Dataproc Pig shell job via BTEQ.
   - Deletes all rows from `sb_rmaprod.analytics_fgt_transfer_gcp`
   - Inserts rows from `sb_rmaprod.analytics_fgt` where `transaction_date` is between `start_date` and `end_date` (pipeline run window, default T-14 to T-1)
   - Also inserts a deactivation backfill window: `transaction_date` between `start_date - 386` days and `end_date - 364` days (approximately one year prior)
   - From: `continuumAfgtDataprocBatch` (`afgtTdExtractionScriptRunner`)
   - To: `edw` (`sb_rmaprod.analytics_fgt_transfer_gcp`)
   - Protocol: BTEQ / JDBC (port 1025, DSN `teradata.groupondev.com`, user `ub_ma_emea`)

2. **Clear Hive staging directory**: Before Sqoop import, `td_to_hive.sh` removes existing data from the Hive staging table directory on GCS:
   `hadoop fs -rm -r -skipTrash {ima_bucket}/user/grp_gdoop_ima/ima_hiveDB.db/analytics_fgt_tmp_zo`
   - From: `continuumAfgtDataprocBatch` (`afgtSqoopImportRunner`)
   - To: `continuumAfgtHiveDataset` (GCS path)
   - Protocol: Hadoop FS / GCS

3. **Sqoop import from Teradata to Hive** (`afgt_sqoop_tmp`): Runs `td_to_hive.sh` as a Dataproc Pig shell job. Executes:
   ```
   sqoop import
     --connect jdbc:teradata://{TD_DSN_NAME}/DATABASE=sb_rmaprod,CHARSET=UTF8,DBS_PORT=1025
     --driver com.teradata.jdbc.TeraDriver
     --connection-manager org.apache.sqoop.manager.GenericJdbcManager
     --query "SELECT * from sb_rmaprod.analytics_fgt_transfer_gcp where 1=1 AND $CONDITIONS"
     --split-by transaction_date
     --num-mappers 20
     --fields-terminated-by "\001"
     --target-dir {ima_bucket}/user/grp_gdoop_ima/ima_hiveDB.db/analytics_fgt_tmp_zo
   ```
   - From: `continuumAfgtDataprocBatch` (`afgtSqoopImportRunner`)
   - To: `continuumAfgtHiveDataset` (`ima.analytics_fgt_tmp_zo`)
   - Protocol: Sqoop JDBC → GCS write (20 parallel map tasks, split by `transaction_date`)

4. **Hive final load** (`hive_load`): Runs `hive_load_final.hql` as a Dataproc Hive job (Tez engine) with script variable `db=ima`.
   - Reads all rows from `ima.analytics_fgt_tmp_zo`
   - Left-joins with `ima.user_rfm_segment_act_react` to enrich with `rfm_code` and `rfm_segment` (using prior-day validity window for countries: 234, 233, 208, 177, 157, 110, 107, 83, 76, 22, 159, 112, 14, 40, 235)
   - Executes `INSERT OVERWRITE TABLE ima.analytics_fgt PARTITION(transaction_date, country_id)` using dynamic partitioning
   - Tez settings: `hive.exec.max.dynamic.partitions=10000`, vectorized execution enabled, parallel execution enabled, compressed output
   - From: `continuumAfgtDataprocBatch` (`afgtHiveLoadRunner`)
   - To: `continuumAfgtHiveDataset` (`ima.analytics_fgt`)
   - Protocol: Hive (Tez) / GCS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| BTEQ extraction failure (`afgt_td_tmp`) | Airflow marks task failed; retry once after 1800s | `afgt_sqoop_tmp` blocked; Google Chat alert fired |
| Sqoop mapper failure | Sqoop returns non-zero exit code | `afgt_sqoop_tmp` task fails; `hive_load` blocked; partial GCS data must be cleaned manually before retry |
| Stale data in `analytics_fgt_transfer_gcp` | BTEQ `DELETE` at start of extraction ensures clean slate | Previous run's data removed before fresh insert |
| Hive dynamic partition overwrite error | `INSERT OVERWRITE` semantics replace existing partitions atomically | Existing `ima.analytics_fgt` partitions for the date window are replaced; no duplicate rows |
| Dataproc Metastore unavailable | Hive job fails to access schema | `hive_load` task fails; must resolve Metastore service before retry |

## Sequence Diagram

```
afgt_sb_td DAG       -> Dataproc cluster       : Submit afgt_td_extract.sh (Pig/BTEQ)
Dataproc cluster     -> Teradata EDW            : DELETE sb_rmaprod.analytics_fgt_transfer_gcp
Dataproc cluster     -> Teradata EDW            : INSERT INTO analytics_fgt_transfer_gcp (date window + deact backfill)
Teradata EDW        --> Dataproc cluster        : Transfer table populated
afgt_sb_td DAG       -> Dataproc cluster        : Submit td_to_hive.sh (Pig/Sqoop)
Dataproc cluster     -> GCS (IMA)               : hadoop fs -rm analytics_fgt_tmp_zo
Dataproc cluster     -> Teradata EDW            : Sqoop JDBC SELECT analytics_fgt_transfer_gcp
Teradata EDW        --> GCS (IMA)               : 20 parallel mappers write analytics_fgt_tmp_zo (delimiter \001)
afgt_sb_td DAG       -> Dataproc cluster        : Submit hive_load_final.hql (Hive/Tez)
Dataproc cluster     -> GCS (IMA)               : READ ima.analytics_fgt_tmp_zo + JOIN user_rfm_segment_act_react
Dataproc cluster     -> GCS (IMA)               : INSERT OVERWRITE ima.analytics_fgt PARTITION(transaction_date,country_id)
GCS (IMA)           --> afgt_sb_td DAG          : Hive load complete
```

## Related

- Architecture dynamic view: `dynamic-afgt_td_to_hive_load` (disabled in federation)
- Parent flow: [Daily AFGT TD Pipeline](daily-afgt-td-pipeline.md)
- Related flows: [Precheck and Cluster Bootstrap](precheck-and-cluster-bootstrap.md)
- See [Data Stores](../data-stores.md) for full schema details of `ima.analytics_fgt` and `ima.analytics_fgt_tmp_zo`
