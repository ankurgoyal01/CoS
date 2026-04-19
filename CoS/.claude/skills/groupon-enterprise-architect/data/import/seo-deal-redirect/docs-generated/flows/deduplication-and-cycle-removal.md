---
service: "seo-deal-redirect"
title: "Deduplication and Cycle Removal"
generated: "2026-03-03"
type: flow
flow_name: "deduplication-and-cycle-removal"
flow_type: batch
trigger: "Executed as tasks within the daily redirect pipeline DAG after expired-to-live mapping"
participants:
  - "continuumSeoDealRedirectJobs"
  - "continuumSeoHiveWarehouse"
architecture_ref: "components-seoDealRedirectJobs"
---

# Deduplication and Cycle Removal

## Summary

After the expired-to-live mapping step produces a raw set of candidate redirect pairs (including duplicates and possible loops), this flow applies two data quality passes. First, deduplication selects the single best redirect for each expired deal UUID based on recency and confidence level. Second, cycle detection removes any redirects that would create a loop (A → B → C → A), ensuring that the final mapping is a directed acyclic graph safe for HTTP redirect chains.

## Trigger

- **Type**: batch task (sub-flow within the daily pipeline)
- **Source**: Airflow DAG tasks `dedup_expired_to_live` then `remove_cycles_expired_to_live`
- **Frequency**: Daily, as part of the [Daily Redirect Pipeline](daily-redirect-pipeline.md), after [Expired-to-Live Mapping](expired-to-live-mapping.md)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Hive ETL Scripts | Executes HQL deduplication and cycle-removal logic | `hiveEtlScripts` (component of `continuumSeoDealRedirectJobs`) |
| SEO Hive Warehouse | Source and destination for all staging tables | `continuumSeoHiveWarehouse` |

## Steps

### Phase 1: Deduplication

1. **Remove stale deduped records**: Deletes from `grp_gdoop_seo_db.daily_expired_to_live_deduped` any rows where `dt <= run_date` (clears the current partition for idempotent re-runs).
   - From: `hiveEtlScripts`
   - To: `continuumSeoHiveWarehouse`
   - Protocol: HiveQL DELETE / INSERT OVERWRITE

2. **Select best redirect per expired deal**: Groups all rows in `daily_expired_to_live_deal_mapping` by `expired_uuid`. For each expired deal, selects the row with:
   - The **most recent `dt`** (latest match date takes precedence)
   - The **highest `confidence_level`** (manual redirects can have higher confidence than algorithmic matches)
   - Implemented via inner join + GROUP BY + MAX aggregation
   - From: `hiveEtlScripts`
   - To: `continuumSeoHiveWarehouse`
   - Protocol: HiveQL SELECT with GROUP BY / RANK

3. **Write deduplicated mapping**: Inserts the single-winner rows into `grp_gdoop_seo_db.daily_expired_to_live_deduped` partitioned by `dt = run_date`.
   - From: `hiveEtlScripts`
   - To: `continuumSeoHiveWarehouse`
   - Protocol: HiveQL INSERT INTO PARTITION

### Phase 2: Cycle Removal

4. **Detect cycles**: Queries `daily_expired_to_live_deduped` to identify `live_uuid` values that also appear as `expired_uuid` in another row (direct cycle detection). The HQL selects only rows where the `live_uuid` is **not** a `expired_uuid` in any other mapping row for the same date.
   - From: `hiveEtlScripts`
   - To: `continuumSeoHiveWarehouse`
   - Protocol: HiveQL SELECT with NOT IN / anti-join

5. **Write cycle-free mapping**: Inserts the validated rows into `grp_gdoop_seo_db.daily_expired_to_live_no_cycles` partitioned by `dt = run_date`. This table is the clean input for the API upload table population step.
   - From: `hiveEtlScripts`
   - To: `continuumSeoHiveWarehouse`
   - Protocol: HiveQL INSERT INTO PARTITION

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Cycle detected | Row with the cycle-forming `live_uuid` is excluded from `daily_expired_to_live_no_cycles` | Expired deal receives no redirect rather than a looping redirect |
| Multiple candidates with equal recency and confidence | HiveQL grouping applies a deterministic tie-breaker (implementation-dependent on Hive executor order) | One redirect is selected; the other is silently dropped |
| Empty `daily_expired_to_live_deal_mapping` | Deduplication produces an empty table; cycle removal also produces empty output | No redirects are uploaded to the API for this run |
| Hive query failure | Airflow task fails; downstream tasks (API upload) do not run | Pipeline aborted; manual re-run required |

## Sequence Diagram

```
hiveEtlScripts -> continuumSeoHiveWarehouse: SELECT from daily_expired_to_live_deal_mapping (dt <= run_date)
hiveEtlScripts -> continuumSeoHiveWarehouse: GROUP BY expired_uuid, MAX(dt), MAX(confidence_level)
hiveEtlScripts -> continuumSeoHiveWarehouse: INSERT INTO daily_expired_to_live_deduped PARTITION(dt=run_date)
hiveEtlScripts -> continuumSeoHiveWarehouse: SELECT from daily_expired_to_live_deduped WHERE live_uuid NOT IN (SELECT expired_uuid ...)
hiveEtlScripts -> continuumSeoHiveWarehouse: INSERT INTO daily_expired_to_live_no_cycles PARTITION(dt=run_date)
```

## Related

- Parent flow: [Daily Redirect Pipeline](daily-redirect-pipeline.md)
- Previous flow: [Expired-to-Live Mapping](expired-to-live-mapping.md)
- Next flow: [API Upload](api-upload.md)
- Architecture ref: `hiveEtlScripts` component within `continuumSeoDealRedirectJobs`
