---
service: "cls-optimus-jobs"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for CLS Optimus Jobs.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Billing Data Ingestion](billing-ingestion.md) | batch | Daily Optimus schedule or manual trigger | Exports NA and EMEA billing address records from Teradata, stages to HDFS, loads into `cls_billing_address_na` / `cls_billing_address_emea` Hive tables. |
| [Shipping Data Ingestion](shipping-ingestion.md) | batch | Daily Optimus schedule or manual trigger | Exports NA and EMEA shipping order records from Teradata via SQLExport, transfers files to HDFS, loads into `cls_shipping_na` / `cls_shipping_emea` Hive tables. |
| [CDS Data Ingestion](cds-ingestion.md) | batch | Daily Optimus schedule or manual trigger | Exports user profile location data from Teradata `user_gp.user_profile_locations` and transforms Janus consumer account events into `cls_user_profile_locations_na`. |
| [Non-Ping Coalesce](nonping-coalesce.md) | batch | Daily Optimus schedule or manual trigger | Merges billing, shipping, and CDS records from source Hive tables through normalisation and lat/lng enrichment into the unified `coalesce_nonping` target table. |
| [Backfill Load](backfill-load.md) | batch | Manual trigger | Full historical load variants of billing, shipping, and coalesce jobs that process all available records without a date filter; writes to `coalesce_nonping_staging`. |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 5 |

## Cross-Service Flows

The non-ping coalesce flow spans `continuumClsOptimusJobs` and `continuumClsHiveWarehouse` as documented in the architecture dynamic view `dynamic-cls-optimus-nonping-coalesce`. Source data originates from Teradata transactional databases (billing and shipping) and the Janus event platform (`grp_gdoop_pde.janus_all`), both of which are external to the federated architecture model.
