---
service: "cls-optimus-jobs"
title: "Backfill Load"
generated: "2026-03-03"
type: flow
flow_name: "backfill-load"
flow_type: batch
trigger: "Manual trigger via Optimus UI"
participants:
  - "continuumClsOptimusJobs"
  - "continuumClsHiveWarehouse"
architecture_ref: "dynamic-cls-optimus-nonping-coalesce"
---

# Backfill Load

## Summary

The backfill load flow is the full-history variant of the ingestion and coalesce pipelines. Backfill jobs process all available records without a date range filter, loading the complete historical dataset into Hive. Billing and shipping backfill ingestion jobs write to the same target tables as delta jobs (`cls_billing_address_na`, `cls_shipping_na`, etc.). Coalesce backfill jobs write to `grp_gdoop_cls_db.coalesce_nonping_staging` rather than the live `coalesce_nonping` table, allowing validation before promoting data to production. Backfill jobs are triggered manually through the Optimus UI when historical data needs to be reloaded (e.g., after schema changes, data corrections, or new pipeline onboarding).

## Trigger

- **Type**: manual
- **Source**: Operator-initiated via Optimus UI
- **Frequency**: On-demand only (not scheduled)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator | Initiates backfill via Optimus UI; sets `record_date` parameter | Human |
| Optimus Control Plane | Executes job steps on the Optimus worker | `optimusControlPlane_1bb5a5e5` (stub) |
| CLS Optimus Jobs — All ingestion and coalesce components | Orchestrates backfill job execution | `continuumClsOptimusJobs` |
| Teradata NA / EMEA | Source of full historical billing and shipping records (no date filter) | Not in federated model |
| HDFS Landing Zone | Intermediate staging for Teradata exports | `hdfsLandingZone_790f81de` (stub) |
| CLS Hive Warehouse | Target database for all backfill records | `continuumClsHiveWarehouse` |

## Backfill Job Variants

| Backfill Job File | Optimus Group | Source | Target |
|-------------------|--------------|--------|--------|
| `cls-billing-na-backfill` | `cls_billing` | `user_gp.user_billing_records` (no date filter) | `grp_gdoop_cls_db.cls_billing_address_na PARTITION(record_date=current_date)` |
| `cls-billing-emea-backfill` | `cls_billing` | EMEA `billing_address` JOIN `billing_record` (no date filter) | `grp_gdoop_cls_db.cls_billing_address_emea PARTITION(record_date=current_date)` |
| `Shipping_data_from_NA_backfill` | `cls_shipping` | `user_gp.orders` JOIN `user_gp.parent_orders` (no date filter) | `grp_gdoop_cls_db.cls_shipping_na PARTITION(country_code)` |
| `Shipping_data_from_EMEA_backfill` | `cls_shipping` | `user_edwprod.orders` JOIN `user_edwprod.parent_orders` (no date filter) | `grp_gdoop_cls_db.cls_shipping_emea PARTITION(country_code)` |
| `coalesce_billing_na.yml` | `coalesce_nonping` | `grp_gdoop_cls_db.cls_billing_address_na` (no date filter) | `grp_gdoop_cls_db.coalesce_nonping_staging PARTITION(country_code, record_month)` |
| `coalesce_billing_emea.yml` | `coalesce_nonping` | `grp_gdoop_cls_db.cls_billing_address_emea` (no date filter) | `grp_gdoop_cls_db.coalesce_nonping_staging PARTITION(country_code, record_month)` |
| `coalesce_shipping_na.yml` | `coalesce_nonping` | `grp_gdoop_cls_db.cls_shipping_na` (no date filter) | `grp_gdoop_cls_db.coalesce_nonping_staging PARTITION(country_code, record_month)` |
| `coalesce_shipping_emea.yml` | `coalesce_nonping` | `grp_gdoop_cls_db.cls_shipping_emea` (no date filter) | `grp_gdoop_cls_db.coalesce_nonping_staging PARTITION(country_code, record_month)` |

## Steps (Billing NA Backfill Example)

1. **Initialise environment** (`__start__` ScriptTask): Creates sandbox directory; emits date context JSON. No `start_date` / `end_date` parameters — full table is processed.
   - From: `clsOptimus_coalesceJobs`
   - To: Optimus worker

2. **Clean HDFS**: Removes existing files from billing/na HDFS path.
   - From: `clsOptimus_billingIngestionJobs`
   - To: HDFS Landing Zone

3. **Export full dataset**: Queries `user_gp.user_billing_records` without date filter; exports all records to HDFS `/user/grp_gdoop_cls/optimus/billing/na/`.
   - From: `clsOptimus_billingIngestionJobs`
   - To: Teradata NA

4. **Create external table**: Creates `cls_billing_address_na_tmpTbl` external table over HDFS path.
   - From: `clsOptimus_hqlExecutionTasks`
   - To: `continuumClsHiveWarehouse`

5. **Load into target**: Inserts all records from `cls_billing_address_na_tmpTbl` into `cls_billing_address_na PARTITION(record_date=current_date)`.
   - From: `clsOptimus_hqlExecutionTasks`
   - To: `continuumClsHiveWarehouse`

For the coalesce backfill variant, steps 2 and 3 above are replaced by the prepare/transform/insert pattern described in [Non-Ping Coalesce](nonping-coalesce.md), with the key difference that the INSERT target is `coalesce_nonping_staging` instead of `coalesce_nonping`, and no `record_date` date filter is applied in the transform step.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Large dataset causes Tez OOM | Job fails mid-execution | Check if partial data was loaded; drop affected partitions; re-run with reduced date range using specific `record_date` params |
| Backfill writes duplicate records to target | No deduplication in INSERT — records are appended | Drop the specific partition before re-running: `ALTER TABLE coalesce_nonping_staging DROP PARTITION(...)` |
| Job runs too long and times out | Optimus job timeout reached | Split backfill into date range chunks using `echo '<date>'` param override |

## Sequence Diagram

```
Operator -> Optimus UI: Trigger backfill job manually
Optimus Scheduler -> clsOptimus_billingIngestionJobs: Execute with record_date=current_date
clsOptimus_billingIngestionJobs -> HDFS Landing Zone: Clean HDFS landing path
clsOptimus_billingIngestionJobs -> Teradata NA/EMEA: Export ALL records (no date filter)
Teradata NA/EMEA --> HDFS Landing Zone: Full dataset file
clsOptimus_hqlExecutionTasks -> continuumClsHiveWarehouse: CREATE EXTERNAL TABLE (tmpTbl)
clsOptimus_hqlExecutionTasks -> continuumClsHiveWarehouse: INSERT INTO cls_billing_address_na PARTITION(record_date)
[Coalesce backfill runs separately]
clsOptimus_coalesceJobs -> continuumClsHiveWarehouse: DROP + CREATE coalesce temp table
clsOptimus_dataQualityAndNormalization -> continuumClsHiveWarehouse: Transform (no date filter)
clsOptimus_hqlExecutionTasks -> continuumClsHiveWarehouse: INSERT INTO coalesce_nonping_staging PARTITION(country_code, record_month)
continuumClsHiveWarehouse --> clsOptimus_coalesceJobs: Load complete
Operator -> continuumClsHiveWarehouse: Verify counts; validate staging data
```

## Related

- Architecture dynamic view: `dynamic-cls-optimus-nonping-coalesce`
- Related flows: [Non-Ping Coalesce](nonping-coalesce.md) — delta variant of the coalesce step
- Related flows: [Billing Data Ingestion](billing-ingestion.md) — delta variant
- Related flows: [Shipping Data Ingestion](shipping-ingestion.md) — delta variant
