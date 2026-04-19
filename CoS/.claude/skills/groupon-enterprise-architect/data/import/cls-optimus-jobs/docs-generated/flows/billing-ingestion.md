---
service: "cls-optimus-jobs"
title: "Billing Data Ingestion"
generated: "2026-03-03"
type: flow
flow_name: "billing-ingestion"
flow_type: batch
trigger: "Daily Optimus schedule (delta) or manual trigger (backfill)"
participants:
  - "continuumClsOptimusJobs"
  - "continuumClsHiveWarehouse"
architecture_ref: "dynamic-cls-optimus-nonping-coalesce"
---

# Billing Data Ingestion

## Summary

The billing data ingestion flow extracts customer billing address records from Teradata (NA via `user_gp.user_billing_records`; EMEA via the EMEA billing system's `billing_address` and `billing_record` tables) and loads them into partitioned Hive tables within `grp_gdoop_cls_db`. Delta variants process the previous day's updated records; backfill variants process the full historical dataset. The resulting tables (`cls_billing_address_na`, `cls_billing_address_emea`) feed the coalesce flow downstream.

## Trigger

- **Type**: schedule (delta) / manual (backfill)
- **Source**: Optimus scheduler for the `cls_billing` user group at `https://optimus.groupondev.com/#/groups/cls_billing`
- **Frequency**: Daily (delta); on-demand (backfill)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Optimus Control Plane | Schedules job, injects date parameters, monitors execution | `optimusControlPlane_1bb5a5e5` (stub) |
| CLS Optimus Jobs — Billing Ingestion | Orchestrates all task steps: clean, export, stage, load | `continuumClsOptimusJobs` / `clsOptimus_billingIngestionJobs` |
| Teradata NA (`user_gp`) | Source of NA billing address records | Not in federated model |
| Teradata EMEA (billing system) | Source of EMEA billing address records | Not in federated model |
| HDFS Landing Zone | Intermediate file staging | `hdfsLandingZone_790f81de` (stub) |
| CLS Hive Warehouse | Target database for loaded records | `continuumClsHiveWarehouse` |

## Steps

### NA Billing Delta Job (`cls-billing-na-delta`)

1. **Clean HDFS landing path**: Removes existing files from `/user/grp_gdoop_cls/optimus/billing/na/` via `dfs -rm -f -skipTrash`.
   - From: `clsOptimus_billingIngestionJobs`
   - To: `hdfsLandingZone_790f81de`
   - Protocol: HDFS DFS command via HQLExecute.py

2. **Export from Teradata NA**: Queries `user_gp.user_billing_records` for records where `updated_at >= start_date AND updated_at < end_date`; applies `regexp_replace` to sanitise city/state fields; writes tilde-delimited file to HDFS `/user/grp_gdoop_cls/optimus/billing/na/`.
   - From: `clsOptimus_billingIngestionJobs`
   - To: Teradata NA
   - Protocol: Optimus `SQLExport` / HDFS transfer

3. **Create external staging table**: Executes `CREATE TABLE IF NOT EXISTS grp_gdoop_cls_db.cls_billing_address_na_tmp` as an external table pointing to the HDFS landing path; field delimiter is tilde (`~`).
   - From: `clsOptimus_hqlExecutionTasks`
   - To: `continuumClsHiveWarehouse`
   - Protocol: Hive SQL via HQLExecute.py

4. **Load into target table**: Executes `INSERT INTO grp_gdoop_cls_db.cls_billing_address_na PARTITION(record_date) SELECT ... FROM grp_gdoop_cls_db.cls_billing_address_na_tmp` using `${record_date}` as the partition value.
   - From: `clsOptimus_hqlExecutionTasks`
   - To: `continuumClsHiveWarehouse`
   - Protocol: Hive SQL via HQLExecute.py

### EMEA Billing Delta Job (`cls-billing-emea-delta` / `cls_billing_emea-delta`)

Steps mirror the NA flow with EMEA-specific sources:
- Source table: EMEA `billing_address` JOIN `billing_record` (delta filter: `br.auto_last_modified`)
- HDFS path: `/user/grp_gdoop_cls/optimus/billing/emea/`
- Target: `grp_gdoop_cls_db.cls_billing_address_emea PARTITION(record_date)`

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Teradata connection fails | Optimus marks `Export to HDFS` task as failed; downstream tasks blocked | PagerDuty alert to `consumer-location-service@groupon.pagerduty.com`; operator re-runs job |
| HDFS path cannot be cleaned | `cls-billing-na-clean` Hive Execute task fails | Job aborts; stale files may remain; operator removes manually and re-runs |
| Hive `INSERT INTO` fails | `cls-billing-insert-target` task fails | Target partition not updated; operator checks Hive logs and re-runs job |
| OOM in Tez container | Hive task fails with OOM error | Operator may need to reduce query scope or increase container memory before re-running |

## Sequence Diagram

```
Optimus Scheduler -> clsOptimus_billingIngestionJobs: Trigger job with date params
clsOptimus_billingIngestionJobs -> HDFS Landing Zone: Clean existing files (dfs -rm)
clsOptimus_billingIngestionJobs -> Teradata NA/EMEA: Export billing records (updated_at filter)
Teradata NA/EMEA --> clsOptimus_billingIngestionJobs: Tilde-delimited file written to ${local_dir}
clsOptimus_billingIngestionJobs -> HDFS Landing Zone: Copy file (RemoteHadoopClient copyfromlocal)
clsOptimus_hqlExecutionTasks -> continuumClsHiveWarehouse: CREATE EXTERNAL TABLE (tmpTbl -> HDFS path)
clsOptimus_hqlExecutionTasks -> continuumClsHiveWarehouse: INSERT INTO cls_billing_address_na PARTITION(record_date)
continuumClsHiveWarehouse --> clsOptimus_billingIngestionJobs: Load complete
clsOptimus_billingIngestionJobs -> Optimus worker local_dir: Cleanup (rm -rf)
```

## Related

- Architecture dynamic view: `dynamic-cls-optimus-nonping-coalesce`
- Related flows: [Non-Ping Coalesce](nonping-coalesce.md) — consumes `cls_billing_address_na` / `cls_billing_address_emea`
- [Backfill Load](backfill-load.md) — full-history variant of this flow
