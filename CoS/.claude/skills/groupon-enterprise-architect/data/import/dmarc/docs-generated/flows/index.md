---
service: "dmarc"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for the DMARC Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Production Polling Cycle](production-polling-cycle.md) | scheduled | 1-minute `time.Ticker` | Periodic fetch of all unread DMARC RUA emails, processing, and log writing in production mode |
| [DMARC Report Processing](dmarc-report-processing.md) | batch | Gmail message with XML attachment | Attachment extraction, XML parsing, GeoIP enrichment, and JSON log output for a single DMARC report email |
| [Staging Single-Message Run](staging-single-message-run.md) | event-driven | `DEPLOY_ENV=staging` at startup | One-shot fetch and processing of a single DMARC report for validation in staging |
| [Gmail OAuth2 Authentication](gmail-oauth2-authentication.md) | synchronous | Service startup | OAuth2 token loading and Gmail service client initialisation |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

The DMARC Processing flow (`dmarcProcessing`) is documented as a dynamic view in the architecture model. It spans the `dmarcService` container and two external dependencies (Gmail API and ELK). See the architecture dynamic view `dmarcProcessing` in the Structurizr workspace for the canonical cross-service sequence.
