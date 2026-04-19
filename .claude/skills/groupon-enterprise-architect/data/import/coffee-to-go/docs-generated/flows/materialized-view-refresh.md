---
service: "coffee-to-go"
title: "Materialized View Refresh Flow"
generated: "2026-03-03"
type: flow
flow_name: "materialized-view-refresh"
flow_type: batch
trigger: "Triggered after data ingestion completes"
participants:
  - "coffeeWorkflows"
  - "coffeeDb"
---

# Materialized View Refresh Flow

## Summary

After data ingestion workflows complete, the materialized view `mv_deals_cache_v6` is refreshed to incorporate newly ingested data. This view joins accounts, opportunities, deal_details, redemption_locations, and prospects into a denormalized, spatially-indexed dataset that powers the deal search API. The refresh is performed by calling the `refresh_deals_cache()` PostgreSQL function.

## Trigger

- **Type**: schedule (post-ingestion)
- **Source**: Triggered after data ingestion workflows complete, or manually
- **Frequency**: After each data ingestion cycle (daily)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| n8n Workflows | Triggers the refresh after data ingestion | `coffeeWorkflows` |
| Coffee DB | Executes the materialized view refresh | `coffeeDb` |

## Steps

1. **Trigger refresh**: After data ingestion completes, the workflow calls the `refresh_deals_cache()` PostgreSQL function.
   - From: `coffeeWorkflows`
   - To: `coffeeDb` (refresh_deals_cache function)
   - Protocol: SQL

2. **Rebuild materialized view**: PostgreSQL rebuilds `mv_deals_cache_v6` by joining data from `accounts`, `opportunities`, `deal_details`, `redemption_locations`, and `prospects`. The view includes spatial geography columns, full-text search vectors, computed activity classifications, and denormalized fields.
   - From: `coffeeDb` (refresh_deals_cache)
   - To: `coffeeDb` (mv_deals_cache_v6)
   - Protocol: Internal PostgreSQL

3. **Rebuild indexes**: PostGIS spatial indexes and GIN full-text search indexes are rebuilt on the refreshed materialized view.
   - From: `coffeeDb`
   - To: `coffeeDb`
   - Protocol: Internal PostgreSQL

4. **New data available for queries**: The API's deal search queries now return data reflecting the latest ingestion.
   - From: `coffeeDb`
   - To: `coffeeApi` (next query)
   - Protocol: PostgreSQL (read-only pool)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Refresh function fails | PostgreSQL error; old materialized view data remains intact | Stale data served until next successful refresh |
| Long-running refresh | May temporarily increase database load | Query performance may degrade during refresh |

## Sequence Diagram

```
CoffeeWorkflows -> CoffeeDb: SELECT refresh_deals_cache()
CoffeeDb -> CoffeeDb: Rebuild mv_deals_cache_v6 (JOIN accounts, opportunities, deals, locations, prospects)
CoffeeDb -> CoffeeDb: Rebuild spatial + FTS indexes
CoffeeDb --> CoffeeWorkflows: Refresh complete
```

## Related

- Related flows: [Data Ingestion from CRM](data-ingestion-crm.md), [Deal Search](deal-search.md)
