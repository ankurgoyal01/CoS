---
service: "cls-optimus-jobs"
title: "Non-Ping Coalesce"
generated: "2026-03-03"
type: flow
flow_name: "nonping-coalesce"
flow_type: batch
trigger: "Daily Optimus schedule (delta) or manual trigger"
participants:
  - "continuumClsOptimusJobs"
  - "continuumClsHiveWarehouse"
architecture_ref: "dynamic-cls-optimus-nonping-coalesce"
---

# Non-Ping Coalesce

## Summary

The non-ping coalesce flow unifies location records from billing (NA and EMEA), shipping (NA and EMEA), and CDS (NA) source tables into the `grp_gdoop_cls_db.coalesce_nonping` target table. Each per-source coalesce job reads from its corresponding `cls_*` source table, applies data quality normalisation (UUID validation, postal code cleansing, country code allowlist enforcement), enriches records with latitude/longitude via a join against `country_pincode_lat_lng_lookup_optimized`, then inserts into `coalesce_nonping` (delta) or `coalesce_nonping_staging` (backfill). Five independent jobs run under the `coalesce_nonping` Optimus user group — one per source stream.

## Trigger

- **Type**: schedule (delta) / manual
- **Source**: Optimus scheduler for the `coalesce_nonping` user group at `https://optimus.groupondev.com/#/groups/coalesce_nonping`
- **Frequency**: Daily (delta); on-demand (backfill or specific date reprocessing)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Optimus Control Plane | Schedules job, injects `record_date` parameter | `optimusControlPlane_1bb5a5e5` (stub) |
| CLS Optimus Jobs — Coalesce Jobs | Orchestrates preparation, transform, and insert steps | `continuumClsOptimusJobs` / `clsOptimus_coalesceJobs` |
| Hive Execution Tasks | Executes all HQL statements | `clsOptimus_hqlExecutionTasks` |
| Data Quality and Normalization | Applies UUID, zipcode, country code, and lat/lng rules | `clsOptimus_dataQualityAndNormalization` |
| CLS Hive Warehouse | Source (`cls_billing_address_*`, `cls_shipping_*`, `cls_user_profile_locations_na`) and target (`coalesce_nonping`, `coalesce_nonping_staging`) | `continuumClsHiveWarehouse` |
| Country Pincode Lookup | Provides `rounded_latitude` and `rounded_longitude` for postal code + country code pairs | `countryPincodeLookup_7ecf56f1` (stub) |

## Steps

Each of the five coalesce jobs (`coalesce_billing_na_delta`, `coalesce_billing_emea_delta`, `coalesce_shipping_na_delta`, `coalesce_shipping_emea_delta`, `coalesce_cds_na_delta`) follows the same three-step pattern, illustrated here for the billing NA delta job:

1. **Initialise environment** (`__start__` ScriptTask): Creates `${local_dir}` sandbox and emits a JSON context payload containing current/previous date strings for downstream task reference.
   - From: `clsOptimus_coalesceJobs`
   - To: Optimus worker
   - Protocol: Bash ScriptTask

2. **Prepare temp table** (`billing_na_preparation` LibraryTask): Drops any existing temp table (`DROP TABLE grp_gdoop_cls_db.coalesce_nonping_billing_na_temp PURGE`) and creates a new ORC table partitioned by `country_code, record_month` with the unified schema (`consumer_id`, `bcookie`, `location_tag`, `rounded_latitude`, `rounded_longitude`, `pipeline_source`, `division`, `created_at`, `updated_at`, `nonping_city`, `nonping_state`, `postal_zipcode`, `record_date`).
   - From: `clsOptimus_hqlExecutionTasks`
   - To: `continuumClsHiveWarehouse`
   - Protocol: Hive SQL (HQLExecute.py, DSN: `hive_underjob`)

3. **Transform into temp table** (`billing_na_transform` LibraryTask): Applies data quality rules and inserts into the temp table:
   - UUID filter: `consumer_id rlike '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'`
   - Postal code normalisation: NA — retains 5-digit US zip or 1-4 digit international codes; EMEA — retains alphanumeric postal codes matching `[a-zA-Z0-9 -.:]+`; others set to NULL.
   - Country code enforcement: Validates against a 29-country allowlist (`'US','NO','GR','CH','JP','AE','IT','ES','TR','PL','IE','DK','FI','PT','UK','AR','CA','SE','FR','BE','AT','ZA','GB','BR','DE','AU','NL','IL','NZ'`); defaults to `'US'` (NA) or NULL (EMEA) if not in allowlist.
   - Delta only: Adds `AND record_date = DATE '${record_date}'` filter on source table.
   - From: `clsOptimus_dataQualityAndNormalization`
   - To: `continuumClsHiveWarehouse` (temp table)
   - Protocol: Hive SQL

4. **Enrich and insert into target** (`billing_na_insert` LibraryTask): Joins temp table against `grp_gdoop_cls_db.country_pincode_lat_lng_lookup_optimized` on `(country_code IS NOT NULL AND postal_zipcode = stripped_zipcode AND country_code = country_code)` to resolve `rounded_latitude` and `rounded_longitude`; inserts results into:
   - Delta: `grp_gdoop_cls_db.coalesce_nonping PARTITION(country_code, record_month)` (direct production table)
   - Backfill: `grp_gdoop_cls_db.coalesce_nonping_staging PARTITION(country_code, record_month)`
   - From: `clsOptimus_hqlExecutionTasks`
   - To: `continuumClsHiveWarehouse`
   - Protocol: Hive SQL

5. **Cleanup** (`__end__` ScriptTask): Removes local sandbox directory `${local_dir}` via `rm -rf`.
   - From: `clsOptimus_coalesceJobs`
   - To: Optimus worker

### Source Table Mapping

| Job | Source Table | `pipeline_source` Value | Join Type |
|-----|-------------|------------------------|-----------|
| `coalesce_billing_na_delta` | `grp_gdoop_cls_db.cls_billing_address_na` | `'billing_na'` | LEFT OUTER JOIN on lat/lng lookup |
| `coalesce_billing_emea_delta` | `grp_gdoop_cls_db.cls_billing_address_emea` | `'billing_emea'` | LEFT OUTER JOIN on lat/lng lookup |
| `coalesce_shipping_na_delta` | `grp_gdoop_cls_db.cls_shipping_na` | `'shipping_na'` | LEFT OUTER JOIN on lat/lng lookup |
| `coalesce_shipping_emea_delta` | `grp_gdoop_cls_db.cls_shipping_emea` | `'shipping_emea'` | LEFT OUTER JOIN on lat/lng lookup |
| `coalesce_cds_na_delta` | `grp_gdoop_cls_db.cls_user_profile_locations_na` | `'cds_na'` | INNER JOIN on lat/lng lookup |

> Note: CDS NA coalesce uses INNER JOIN (records without a matching zipcode/country in the lookup are excluded). All other sources use LEFT OUTER JOIN (records without a match retain NULL lat/lng).

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Temp table from previous failed run | `DROP TABLE ... PURGE` in preparation step removes stale temp table | Self-healing — no manual action required |
| UUID filter removes all records | Transform step inserts zero rows; target partition empty but job succeeds | Monitor target table counts; investigate source data quality |
| Country code not in allowlist | Records with invalid country code default to `'US'` (NA) or `NULL` / excluded (EMEA, CDS) | Expected behaviour — allowlist enforced by design |
| Postal code does not match lookup | LEFT OUTER JOIN produces NULL `rounded_latitude` / `rounded_longitude` | Record is still inserted with NULL lat/lng — acceptable for partial location data |
| Hive OOM during transform or insert | Task fails; temp table may be partially populated | Drop temp table manually; re-run job |
| Target partition already populated | Subsequent INSERT INTO appends duplicate records | Operator must DROP the specific partition before re-running: `ALTER TABLE coalesce_nonping DROP IF EXISTS PARTITION(country_code='...', record_month='...')` |

## Sequence Diagram

```
Optimus Scheduler -> clsOptimus_coalesceJobs: Trigger (record_date)
clsOptimus_coalesceJobs -> Optimus worker: __start__ ScriptTask (mkdir sandbox, emit date context)
clsOptimus_hqlExecutionTasks -> continuumClsHiveWarehouse: DROP TABLE coalesce_nonping_<source>_temp PURGE
clsOptimus_hqlExecutionTasks -> continuumClsHiveWarehouse: CREATE TABLE coalesce_nonping_<source>_temp (ORC, partitioned)
clsOptimus_dataQualityAndNormalization -> continuumClsHiveWarehouse: INSERT INTO temp (UUID filter + zipcode norm + country validation FROM cls_<source>)
continuumClsHiveWarehouse --> clsOptimus_hqlExecutionTasks: Temp table populated
clsOptimus_hqlExecutionTasks -> continuumClsHiveWarehouse: INSERT INTO coalesce_nonping PARTITION(country_code, record_month) (temp JOIN country_pincode_lat_lng_lookup_optimized)
continuumClsHiveWarehouse --> clsOptimus_coalesceJobs: Target partition updated
clsOptimus_coalesceJobs -> Optimus worker: __end__ ScriptTask (rm -rf sandbox)
```

## Related

- Architecture dynamic view: `dynamic-cls-optimus-nonping-coalesce`
- Related flows: [Billing Data Ingestion](billing-ingestion.md) — produces `cls_billing_address_na` / `cls_billing_address_emea`
- Related flows: [Shipping Data Ingestion](shipping-ingestion.md) — produces `cls_shipping_na` / `cls_shipping_emea`
- Related flows: [CDS Data Ingestion](cds-ingestion.md) — produces `cls_user_profile_locations_na`
- Related flows: [Backfill Load](backfill-load.md) — backfill variant writing to `coalesce_nonping_staging`
