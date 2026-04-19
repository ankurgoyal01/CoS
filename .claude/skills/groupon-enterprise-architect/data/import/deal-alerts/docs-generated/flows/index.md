---
service: "deal-alerts"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Deal Alerts.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Deal Snapshot Ingestion](deal-snapshot-ingestion.md) | batch | Schedule / Webhook | Pages MDS API, normalizes deals, upserts snapshots, computes deltas, and generates alerts via PL/pgSQL. |
| [External Alert Import](external-alert-import.md) | scheduled | Daily schedule | Pulls alert signals from BigQuery and maps them into internal alert records. |
| [Action Orchestration](action-orchestration.md) | batch | Schedule | Selects pending alerts, applies filters and severity rules, assigns and executes actions (Salesforce tasks, chat). |
| [SoldOut Notification Pipeline](soldout-notification-pipeline.md) | batch | Schedule | Processes SoldOut alerts, resolves merchant contacts, selects templates, creates notification records, and sends SMS via Twilio. |
| [Daily Email Summary](daily-email-summary.md) | scheduled | Daily schedule | Aggregates alert action outcomes and generates per-recipient summary emails. |
| [Attribution Correlation](attribution-correlation.md) | batch | Schedule | Correlates inventory replenishment deltas with Salesforce tasks and SMS replies to produce attribution records. |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 6 |

## Cross-Service Flows

- **Deal Alert Lifecycle**: Spans MDS, Deal Alerts Workflows, Deal Alerts DB, Salesforce, BigQuery, and Twilio. Documented in the dynamic architecture view `dynamic-deal-alerts-continuumDealAlertsDb_alertLifecycle`.
