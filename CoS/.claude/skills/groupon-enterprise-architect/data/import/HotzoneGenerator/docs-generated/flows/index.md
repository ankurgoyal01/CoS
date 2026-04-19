---
service: "HotzoneGenerator"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for HotzoneGenerator.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Hotzone Generation (Config Mode)](hotzone-generation.md) | scheduled | Daily cron at 22:00 UTC | Reads active campaign configs, fetches and filters deals from MDS, enriches with open hours and inventory IDs, and inserts hotzones via the Proximity API |
| [New Deal Hotzone Generation](new-deal-hotzone-generation.md) | scheduled | Daily cron at 22:00 UTC (runs within the main job) | Fetches deals launched in the last 7 days from MDS and inserts them as HOTZONE_NEWDEAL type hotzones |
| [Auto Campaign Generation](auto-campaign-generation.md) | scheduled | Weekly cron (Tuesdays) or `createAuto` flag | Fetches trending deal-cluster categories per country/division, resolves taxonomy names, and POSTs new campaign configurations to the Proximity API |
| [Weekly Email Dispatch](weekly-email-dispatch.md) | scheduled | Weekly cron (Fridays 15:00 UTC NA / 07:00 UTC EMEA) | Queries weekly consumer IDs from PostgreSQL and triggers per-consumer proximity email via the Proximity API |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 4 |

## Cross-Service Flows

The hotzone generation flow spans `continuumHotzoneGeneratorJob`, `continuumMarketingDealService`, `continuumTaxonomyService`, `continuumDealCatalogService`, and `apiProxy`. This is captured in the architecture dynamic view `dynamic-hotzoneGenerationFlow` (see `architecture/views/dynamics/hotzone-generation-flow.dsl`).
