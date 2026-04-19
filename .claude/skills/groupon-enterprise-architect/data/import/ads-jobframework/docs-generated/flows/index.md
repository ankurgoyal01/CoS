---
service: "ads-jobframework"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Ads Job Framework.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [CitrusAd Impression Reporting](citrusad-impression-reporting.md) | batch | Scheduled (hourly) | Queries `junoHourly` for sponsored ad impressions in the last hour and posts HTTP callbacks to CitrusAd |
| [CitrusAd Click Reporting](citrusad-click-reporting.md) | batch | Scheduled (hourly) | Queries `junoHourly` for sponsored ad clicks in a configurable delay window and posts HTTP callbacks to CitrusAd |
| [Customer Feed Export](customer-feed-export.md) | batch | Scheduled (daily) | Reads global user attributes, hashes consumer IDs, and writes a demographic TSV feed to GCS for CitrusAd ingestion |
| [Order Feed Export](order-feed-export.md) | batch | Scheduled (daily) | Reads transaction data, hashes customer/session IDs, and writes order TSV feed to GCS for CitrusAd conversion attribution |
| [PPID Audience Export](ppid-audience-export.md) | batch | Scheduled | Reads PPID audience from Teradata, SHA-256 hashes cookie identifiers, and writes CSV to GCS for DFP targeting |
| [Uplift Model Prediction](uplift-model-prediction.md) | batch | Scheduled | Runs Random Forest inference on order and user attribute data to generate a blocklist of low-uplift users |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 6 |

## Cross-Service Flows

All flows in ads-jobframework are self-contained batch jobs submitted to YARN. They interact with external systems (CitrusAd, DoubleClick, GCS, Teradata) via outbound calls but are not triggered by or coordinated with other Groupon services in real time. Orchestration is managed externally via Airflow (Cloud Composer). See the central architecture model for cross-service data dependency diagrams.
