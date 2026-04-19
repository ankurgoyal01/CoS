---
service: "seo-deal-redirect"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for SEO Deal Redirect.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Daily Redirect Pipeline](daily-redirect-pipeline.md) | batch / scheduled | Airflow cron `0 5 15 * *` | End-to-end DAG run: cluster provision, Hive ETL, URL construction, API upload, cluster teardown |
| [Expired-to-Live Mapping](expired-to-live-mapping.md) | batch | Triggered as task within daily pipeline | Algorithmic matching of closed deals to launched deals from the same merchant by location and category |
| [Deduplication and Cycle Removal](deduplication-and-cycle-removal.md) | batch | Triggered as task within daily pipeline | Removes duplicate redirect mappings and prevents redirect loops before final table population |
| [API Upload](api-upload.md) | batch | Triggered as task within daily pipeline | Diffs current vs. previous redirect mappings and publishes new/changed records to the SEO Deal API |
| [Non-Active Merchant Deals](non-active-merchant-deals.md) | batch / scheduled | Separate cron schedule within DAG | Identifies merchants with no active deals, enriches with taxonomy/location data, generates redirect URLs, and calls SEO Deal API |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 5 |

## Cross-Service Flows

The [API Upload](api-upload.md) and [Non-Active Merchant Deals](non-active-merchant-deals.md) flows cross service boundaries, making HTTPS PUT requests to `seo-deal-api`, which in turn updates the Deal Catalog. These cross-service interactions are documented in the `seoDealApi` stub relationship in the architecture DSL (`architecture/models/relations.dsl`).
