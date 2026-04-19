---
service: "seo-deal-redirect"
title: "Expired-to-Live Deal Mapping"
generated: "2026-03-03"
type: flow
flow_name: "expired-to-live-mapping"
flow_type: batch
trigger: "Executed as tasks within the daily redirect pipeline DAG"
participants:
  - "continuumSeoDealRedirectJobs"
  - "continuumSeoHiveWarehouse"
architecture_ref: "components-seoDealRedirectJobs"
---

# Expired-to-Live Deal Mapping

## Summary

This flow implements the core business logic of the SEO Deal Redirect service: matching each expired (closed) deal to the most suitable active (launched) deal from the same merchant. Matching applies a hierarchy of criteria — same merchant, then geographic proximity, then category similarity — and assigns a confidence level of 100 to all algorithmic matches. Manual redirects are unioned in as additional rows. The output is the `daily_expired_to_live_deal_mapping` Hive table.

## Trigger

- **Type**: batch task (sub-flow within the daily pipeline)
- **Source**: Airflow DAG task `map_expired_to_live` (and optionally `map_expired_to_live_pre_2019` / `map_expired_to_live_pre_2019_intl`)
- **Frequency**: Daily, as part of the [Daily Redirect Pipeline](daily-redirect-pipeline.md)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Hive ETL Scripts | Executes HQL matching logic | `hiveEtlScripts` (component of `continuumSeoDealRedirectJobs`) |
| SEO Hive Warehouse | Source (`daily_deals`) and destination (`daily_expired_to_live_deal_mapping`) | `continuumSeoHiveWarehouse` |

## Steps

1. **Read expired deals**: Queries `grp_gdoop_seo_db.daily_deals` for all rows with `status = 'closed'` (expired deals) that are not in the exclusion list.
   - From: `hiveEtlScripts`
   - To: `continuumSeoHiveWarehouse`
   - Protocol: HiveQL SELECT

2. **Read live deals**: Queries `grp_gdoop_seo_db.daily_deals` for all rows with `status = 'launched'` (active deals).
   - From: `hiveEtlScripts`
   - To: `continuumSeoHiveWarehouse`
   - Protocol: HiveQL SELECT

3. **Apply matching criteria**: Joins expired deals to live deals on:
   - **Required**: `lv.merchant_id = ex.merchant_id` (same merchant)
   - **Location** (at least one): `(lv.deal_lat = ex.deal_lat AND lv.deal_lng = ex.deal_lng) OR ex.locality = lv.locality`
   - **Category** (at least one): `(lv.pds_cat_id = ex.pds_cat_id) OR (lv.grt_l2_cat_id = ex.grt_l2_cat_id)`
   - Assigns `confidence_level = 100` to all algorithmic matches
   - From: `hiveEtlScripts`
   - To: `continuumSeoHiveWarehouse`
   - Protocol: HiveQL JOIN

4. **Include manual redirects**: Unions rows from `grp_gdoop_seo_db.manual_redirects` into the result set. Manual redirects override algorithmic matches during deduplication (higher or equal confidence).
   - From: `hiveEtlScripts`
   - To: `continuumSeoHiveWarehouse`
   - Protocol: HiveQL UNION

5. **Include goods database redirects**: Unions existing redirect mappings from `svc_goods_bundling_db` (NA) and `grp_gdoop_gods_db` (EMEA) into the result set.
   - From: `hiveEtlScripts`
   - To: `continuumSeoHiveWarehouse`
   - Protocol: HiveQL UNION

6. **Write mapping table**: Inserts the combined result set into `grp_gdoop_seo_db.daily_expired_to_live_deal_mapping` partitioned by `dt = run_date`.
   - From: `hiveEtlScripts`
   - To: `continuumSeoHiveWarehouse`
   - Protocol: HiveQL INSERT OVERWRITE

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No active deal found for an expired deal | No row is written for that expired deal | Deal receives no redirect; shows "deal unavailable" page |
| EDW source table unavailable | Hive query fails; Airflow task fails | DAG run aborts at this task; re-run required |
| Merchant with multiple locations | Multiple candidate rows per expired deal | Downstream deduplication step selects the best match |
| Manual redirect references a deal not in `daily_deals` | Row is still written (from manual_redirects table); URL is constructed from permalink | Redirect may point to a deal not currently active |

## Sequence Diagram

```
hiveEtlScripts -> continuumSeoHiveWarehouse: SELECT closed deals from daily_deals (expired)
hiveEtlScripts -> continuumSeoHiveWarehouse: SELECT launched deals from daily_deals (live)
hiveEtlScripts -> continuumSeoHiveWarehouse: JOIN on merchant_id + location/category criteria
hiveEtlScripts -> continuumSeoHiveWarehouse: UNION with manual_redirects
hiveEtlScripts -> continuumSeoHiveWarehouse: UNION with goods_db / goods_emea_db redirects
hiveEtlScripts -> continuumSeoHiveWarehouse: INSERT INTO daily_expired_to_live_deal_mapping PARTITION(dt=run_date)
```

## Related

- Parent flow: [Daily Redirect Pipeline](daily-redirect-pipeline.md)
- Next flow: [Deduplication and Cycle Removal](deduplication-and-cycle-removal.md)
- Architecture ref: `hiveEtlScripts` component within `continuumSeoDealRedirectJobs`
