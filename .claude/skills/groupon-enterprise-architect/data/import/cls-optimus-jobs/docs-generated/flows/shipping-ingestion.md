---
service: "cls-optimus-jobs"
title: "Shipping Data Ingestion"
generated: "2026-03-03"
type: flow
flow_name: "shipping-ingestion"
flow_type: batch
trigger: "Daily Optimus schedule (delta) or manual trigger (backfill)"
participants:
  - "continuumClsOptimusJobs"
  - "continuumClsHiveWarehouse"
architecture_ref: "dynamic-cls-optimus-nonping-coalesce"
---

# Shipping Data Ingestion

## Summary

The shipping data ingestion flow exports shipping order records from Teradata (NA via `user_gp.orders` joined with `user_gp.parent_orders`; EMEA via `user_edwprod.orders` joined with `user_edwprod.parent_orders`) to local files, transfers them to HDFS, creates an external Hive table over the HDFS files, then inserts records into the partitioned `cls_shipping_na` and `cls_shipping_emea` Hive tables. Delta variants use an `updated_at` date filter; backfill variants load all available records. These tables are consumed by the downstream coalesce flow.

## Trigger

- **Type**: schedule (delta) / manual (backfill)
- **Source**: Optimus scheduler for the `cls_shipping` user group at `https://optimus.groupondev.com/#/groups/cls_shipping`
- **Frequency**: Daily (delta); on-demand (backfill)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Optimus Control Plane | Schedules job, injects date parameters | `optimusControlPlane_1bb5a5e5` (stub) |
| CLS Optimus Jobs — Shipping Ingestion | Orchestrates all task steps | `continuumClsOptimusJobs` / `clsOptimus_shippingIngestionJobs` |
| Teradata NA (`user_gp`) | Source of NA order and shipping records | Not in federated model |
| Teradata EMEA (`user_edwprod`) | Source of EMEA order and shipping records | Not in federated model |
| HDFS Transfer Tasks | Copies local Teradata export to HDFS | `clsOptimus_hdfsTransferTasks` |
| HDFS Landing Zone | Intermediate file staging for shipping files | `hdfsLandingZone_790f81de` (stub) |
| CLS Hive Warehouse | Target database for loaded records | `continuumClsHiveWarehouse` |

## Steps

### NA Shipping Delta Job (`Shipping_data_from_NA_delta`)

1. **Clean HDFS landing path**: Executes `dfs -rm -f -skipTrash /user/grp_gdoop_cls/optimus/shipping/na/*.txt` via HQLExecute using DSN `shipping_hive_access_underjob`.
   - From: `clsOptimus_shippingIngestionJobs`
   - To: HDFS Landing Zone
   - Protocol: HDFS DFS command via HQLExecute.py

2. **Export from Teradata NA**: Queries `user_gp.orders` joined with `user_gp.parent_orders` filtered by `o.updated_at >= start_date AND o.updated_at < end_date`; extracts `uuid`, `consumer_id`, `shipping_city`, `shipping_state`, `shipping_country`, `country_code`, `shipping_zip`, `created_at`, `updated_at`; writes tilde-delimited output to `${local_dir}/Step2.txt`.
   - From: `clsOptimus_shippingIngestionJobs`
   - To: Teradata NA (`shipping_Data_Jobs` DSN)
   - Protocol: Optimus `SQLExport` (adapter: Teradata)

3. **Transfer file to HDFS**: Copies `${local_dir}/Step2.txt` to `hdfs://cerebro-namenode-vip/user/grp_gdoop_cls/optimus/shipping/na/` using `RemoteHadoopClient.py` with `copyfromlocal` action.
   - From: `clsOptimus_hdfsTransferTasks`
   - To: HDFS Landing Zone
   - Protocol: HDFS (`RemoteHadoopClient.py`)

4. **Create external staging table**: Executes `CREATE EXTERNAL TABLE IF NOT EXISTS grp_gdoop_cls_db.cls_shipping_na_ext` pointing to `/user/grp_gdoop_cls/optimus/shipping/na`; tilde-delimited TextInputFormat.
   - From: `clsOptimus_hqlExecutionTasks`
   - To: `continuumClsHiveWarehouse`
   - Protocol: Hive SQL via HQLExecute.py

5. **Load into target table**: Executes `INSERT INTO grp_gdoop_cls_db.cls_shipping_na PARTITION(country_code) SELECT orders_uuid, consumer_id, shipping_city, shipping_state, shipping_country, shipping_zip, created_at, updated_at, '${record_date}', country_code FROM grp_gdoop_cls_db.cls_shipping_na_ext`.
   - From: `clsOptimus_hqlExecutionTasks`
   - To: `continuumClsHiveWarehouse`
   - Protocol: Hive SQL via HQLExecute.py

6. **Cleanup local sandbox**: Removes `${local_dir}` via `rm -rf` ScriptTask.
   - From: `clsOptimus_shippingIngestionJobs`
   - To: Optimus worker local disk

### EMEA Shipping Delta Job (`Shipping_data_from_EMEA_delta`)

Steps mirror the NA flow with EMEA-specific sources:
- Source: `user_edwprod.orders` JOIN `user_edwprod.parent_orders` (date filter on `o.updated_at`)
- HDFS path: `/user/grp_gdoop_cls/optimus/shipping/emea/`
- Staging table: `grp_gdoop_cls_db.cls_shipping_emea_ext`
- Target: `grp_gdoop_cls_db.cls_shipping_emea PARTITION(country_code)`

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Teradata `SQLExport` fails | Task fails; HDFS transfer task blocked | PagerDuty alert; operator re-runs job with same date params |
| HDFS `copyfromlocal` fails | `Step2_move` fails; Hive external table task blocked | Check HDFS connectivity; verify local file exists; re-run from job start |
| External table creation fails | `Step3` HQL task fails | Check Hive metastore connectivity; re-run |
| INSERT into target fails | `Step4` HQL task fails | Check Tez logs; verify partition does not already exist with conflicting data; re-run |

## Sequence Diagram

```
Optimus Scheduler -> clsOptimus_shippingIngestionJobs: Trigger job (start_date, end_date, record_date)
clsOptimus_shippingIngestionJobs -> HDFS Landing Zone: Clean shipping HDFS path (dfs -rm)
clsOptimus_shippingIngestionJobs -> Teradata NA/EMEA: SQLExport orders with date filter
Teradata NA/EMEA --> clsOptimus_shippingIngestionJobs: Tilde-delimited file at ${local_dir}/Step2.txt
clsOptimus_hdfsTransferTasks -> HDFS Landing Zone: copyfromlocal Step2.txt
clsOptimus_hqlExecutionTasks -> continuumClsHiveWarehouse: CREATE EXTERNAL TABLE cls_shipping_na_ext
clsOptimus_hqlExecutionTasks -> continuumClsHiveWarehouse: INSERT INTO cls_shipping_na PARTITION(country_code)
continuumClsHiveWarehouse --> clsOptimus_shippingIngestionJobs: Load complete
clsOptimus_shippingIngestionJobs -> Optimus worker local_dir: Cleanup (rm -rf)
```

## Related

- Architecture dynamic view: `dynamic-cls-optimus-nonping-coalesce`
- Related flows: [Non-Ping Coalesce](nonping-coalesce.md) — consumes `cls_shipping_na` / `cls_shipping_emea`
- [Backfill Load](backfill-load.md) — full-history variant
