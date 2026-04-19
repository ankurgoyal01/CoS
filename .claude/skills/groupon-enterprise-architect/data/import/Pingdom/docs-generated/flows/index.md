---
service: "pingdom"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Pingdom.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Daily Uptime Data Collection](daily-uptime-collection.md) | scheduled | Daily cron / management command | Fetches uptime metrics from Pingdom API for all configured tags and persists them to the `pingdom_logs` database table |
| [Uptime Alert Evaluation](uptime-alert-evaluation.md) | scheduled | Daily cron (after data collection completes) | Checks yesterday's uptime data against the configured threshold and raises JSM P3 alerts for services below 99% |
| [Shift Report Generation](shift-report-generation.md) | scheduled | Periodic cron job (every 4 hours) | Queries Pingdom API for recent failures and posts formatted shift report to IMOC Google Chat spaces |
| [Service Metadata Publication](service-metadata-publication.md) | event-driven | Architecture federation sync (daily) | Publishes Pingdom service metadata and monitoring link definitions to the central Groupon architecture model |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 3 |

## Cross-Service Flows

The Daily Uptime Collection and Uptime Alert Evaluation flows are owned by `ein_project` (ProdCAT portal) and are documented here because they directly operate against the Pingdom integration registered by this service. The Shift Report Generation flow is owned by `tdo-team`. Both reference the Pingdom SaaS API endpoint (`https://api.pingdom.com/api/2.1`) associated with this service's registration.
