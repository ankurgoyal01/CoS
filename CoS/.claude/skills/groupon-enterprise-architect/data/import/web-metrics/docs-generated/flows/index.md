---
service: "web-metrics"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Web Metrics.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [CronJob Startup and Config Loading](crux-data-collection.md) | scheduled | Kubernetes CronJob fires at minutes 10 and 40 each hour | Loads per-service run configuration from file or remote URL and initializes the execution context |
| [CrUX Data Collection](crux-data-collection.md) | scheduled | CronJob invocation for each `cruxRun` entry | Queries Google PageSpeed Insights API per page/platform/environment combination and collects CrUX field data |
| [Metric Transformation and Publishing](metric-publishing.md) | scheduled | Follows CrUX data collection | Transforms raw PSI audit JSON into tagged Influx data points and writes them to the Telegraf gateway |
| [Lighthouse Lab Audit](lighthouse-lab-audit.md) | scheduled | CronJob invocation for each `perfRun` entry (currently disabled in production) | Spawns headless Chrome, runs Lighthouse, extracts audit scores, and publishes lab metric points |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 4 |

## Cross-Service Flows

All flows in this service are self-contained within the CronJob boundary. The only cross-service interactions are:

- Outbound call to `googlePageSpeedInsights` (Google PageSpeed Insights API) — see [CrUX Data Collection](crux-data-collection.md) and [Lighthouse Lab Audit](lighthouse-lab-audit.md)
- Outbound write to `metricsStack` (Telegraf gateway) — see [Metric Transformation and Publishing](metric-publishing.md)

No central architecture dynamic views are currently modeled for this service (`views/dynamics/.gitkeep` is empty).
