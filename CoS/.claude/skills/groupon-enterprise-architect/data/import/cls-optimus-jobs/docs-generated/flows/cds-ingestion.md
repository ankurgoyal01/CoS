---
service: "cls-optimus-jobs"
title: "CDS Data Ingestion"
generated: "2026-03-03"
type: flow
flow_name: "cds-ingestion"
flow_type: batch
trigger: "Daily Optimus schedule"
participants:
  - "continuumClsOptimusJobs"
  - "continuumClsHiveWarehouse"
architecture_ref: "dynamic-cls-optimus-nonping-coalesce"
---

# CDS Data Ingestion

## Summary

The Consumer Data Service (CDS) ingestion flow populates `grp_gdoop_cls_db.cls_user_profile_locations_na` from two sources: (1) the Teradata `user_gp.user_profile_locations` table containing user-saved profile locations, and (2) the Janus `grp_gdoop_pde.janus_all` event stream containing consumer account location events. Both jobs run daily as delta loads. The resulting table is consumed by the downstream non-ping coalesce flow to merge CDS location signals with billing and shipping data.

## Trigger

- **Type**: schedule
- **Source**: Optimus scheduler for the `cls_cds` user group at `https://optimus.groupondev.com/#/groups/cls_cds`
- **Frequency**: Daily

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Optimus Control Plane | Schedules job, injects date parameters | `optimusControlPlane_1bb5a5e5` (stub) |
| CLS Optimus Jobs — CDS Ingestion | Orchestrates all task steps | `continuumClsOptimusJobs` / `clsOptimus_cdsIngestionJobs` |
| Teradata NA (`user_gp.user_profile_locations`) | Source of user profile location records | Not in federated model |
| Janus All Dataset (`grp_gdoop_pde.janus_all`) | Source of consumer account event-based location data | `janusAllDataset_57a5c2d1` (stub) |
| HDFS Landing Zone | Intermediate file staging for CDS Teradata export | `hdfsLandingZone_790f81de` (stub) |
| CLS Hive Warehouse | Target database for loaded CDS records | `continuumClsHiveWarehouse` |

## Steps

### CDS NA Delta Job (`CDS_Data_from_NA_delta`)

1. **Clean HDFS landing path**: Executes `dfs -rm -f -skipTrash /user/grp_gdoop_cls/optimus/cds/na/*.txt` via HQLExecute.
   - From: `clsOptimus_cdsIngestionJobs`
   - To: HDFS Landing Zone
   - Protocol: HDFS DFS command via HQLExecute.py

2. **Export from Teradata NA**: Queries `user_gp.user_profile_locations` filtered by `updated_at >= start_date AND updated_at < end_date`; extracts `id`, `uuid`, `name`, `lat`, `lng`, `neighborhood`, `profile_id`, `SOURCE`, `status`, `created_at`, `updated_at`, `city`, `state`, `zipcode`; writes tilde-delimited file to HDFS `/user/grp_gdoop_cls/optimus/cds/na/`.
   - From: `clsOptimus_cdsIngestionJobs`
   - To: Teradata NA
   - Protocol: Optimus `Export to HDFS`

3. **Create external staging table**: Executes `CREATE EXTERNAL TABLE IF NOT EXISTS grp_gdoop_cls_db.user_profile_locations_tempTable` pointing to `/user/grp_gdoop_cls/optimus/cds/na/`; tilde-delimited TextInputFormat.
   - From: `clsOptimus_hqlExecutionTasks`
   - To: `continuumClsHiveWarehouse`
   - Protocol: Hive SQL via HQLExecute.py

4. **Load into target table**: Executes `INSERT INTO grp_gdoop_cls_db.cls_user_profile_locations_na PARTITION(cds_country_code) SELECT ... FROM grp_gdoop_cls_db.user_profile_locations_tempTable` with `record_date = '${record_date}'` and hardcoded `country_code = 'US'`.
   - From: `clsOptimus_hqlExecutionTasks`
   - To: `continuumClsHiveWarehouse`
   - Protocol: Hive SQL via HQLExecute.py

### CDS Janus NA Delta Job (`CDS_Data_NA_from_janus_delta`)

1. **Preparation**: Drops and recreates `grp_gdoop_cls_db.cls_user_profile_locations_na_temp` as an empty ORC managed table.
   - From: `clsOptimus_hqlExecutionTasks`
   - To: `continuumClsHiveWarehouse`
   - Protocol: Hive SQL via HQLExecute.py (DSN: `cds_hive_access_underjob`)

2. **Transform from Janus**: Queries `grp_gdoop_pde.janus_all` where `ds = '${janus_record_date}'`, `event = 'consumerAccount'`, `postalcode IS NOT NULL`, `country IN ('US', 'CA')`; applies `ROW_NUMBER() OVER (PARTITION BY consumerId, locationtypename, postalcode ORDER BY eventtime DESC)` to deduplicate; inserts rank=1 records into the temp table with `record_date = '${record_date}'`.
   - From: `clsOptimus_cdsIngestionJobs`
   - To: `continuumClsHiveWarehouse`
   - Protocol: Hive SQL via HQLExecute.py

3. **Load into target table**: Executes `INSERT INTO grp_gdoop_cls_db.cls_user_profile_locations_na PARTITION(cds_country_code) SELECT ... FROM grp_gdoop_cls_db.cls_user_profile_locations_na_temp`.
   - From: `clsOptimus_hqlExecutionTasks`
   - To: `continuumClsHiveWarehouse`
   - Protocol: Hive SQL via HQLExecute.py

4. **Cleanup**: Removes `${local_dir}` via ScriptTask `__end__`.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Teradata export fails | `Export to HDFS` step fails; downstream Hive load blocked | PagerDuty alert; operator re-runs with corrected date params |
| Janus dataset partition missing | `cds_na_transform` returns zero rows; temp table empty | Operator verifies `janus_all` data for `janus_record_date`; runs once data is available |
| Duplicate `cds_country_code` partition | Dynamic partition insert fails if strict mode activates | Ensure `hive.exec.dynamic.partition.mode=nostrict` is set; re-run |
| Temp table from previous failed run | `DROP TABLE IF EXISTS ... PURGE` at `cds_na_prepration` clears stale data | No action needed — self-healing |

## Sequence Diagram

```
Optimus Scheduler -> clsOptimus_cdsIngestionJobs: Trigger (start_date, end_date, record_date OR janus_record_date)

--- CDS_Data_from_NA_delta path ---
clsOptimus_cdsIngestionJobs -> HDFS Landing Zone: Clean /optimus/cds/na/ (dfs -rm)
clsOptimus_cdsIngestionJobs -> Teradata NA: Export user_profile_locations (updated_at filter)
Teradata NA --> HDFS Landing Zone: Tilde-delimited file
clsOptimus_hqlExecutionTasks -> continuumClsHiveWarehouse: CREATE EXTERNAL TABLE user_profile_locations_tempTable
clsOptimus_hqlExecutionTasks -> continuumClsHiveWarehouse: INSERT INTO cls_user_profile_locations_na PARTITION(cds_country_code='US')

--- CDS_Data_NA_from_janus_delta path ---
clsOptimus_hqlExecutionTasks -> continuumClsHiveWarehouse: DROP + CREATE cls_user_profile_locations_na_temp
clsOptimus_cdsIngestionJobs -> continuumClsHiveWarehouse: SELECT from janus_all (dedup by consumerId/locationtype/postalcode)
clsOptimus_hqlExecutionTasks -> continuumClsHiveWarehouse: INSERT INTO cls_user_profile_locations_na PARTITION(cds_country_code)
continuumClsHiveWarehouse --> clsOptimus_cdsIngestionJobs: Load complete
clsOptimus_cdsIngestionJobs -> Optimus worker local_dir: Cleanup (rm -rf)
```

## Related

- Architecture dynamic view: `dynamic-cls-optimus-nonping-coalesce`
- Related flows: [Non-Ping Coalesce](nonping-coalesce.md) — consumes `cls_user_profile_locations_na`
