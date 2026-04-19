---
service: "groupon-monorepo"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for the Encore Platform.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Deal Creation and Publishing](deal-creation-publishing.md) | synchronous | User action in admin UI | End-to-end deal lifecycle from creation through versioning, approval, and publishing to Continuum |
| [Salesforce Account Sync](salesforce-account-sync.md) | asynchronous | Scheduled cron + on-demand | Bidirectional sync of merchant accounts between Encore and Salesforce CRM |
| [AI Deal Content Generation](ai-deal-content-generation.md) | asynchronous | User action in AIDG UI | AI-driven deal content generation using LLM and Python ML services |
| [Checkout Event Processing](checkout-event-processing.md) | event-driven | Kafka message | Janus checkout events consumed from Kafka, processed, and persisted |
| [Deal Search and Recommendations](deal-search-recommendations.md) | synchronous | API request | Deal search flow through Go backend with query preprocessing, Vespa search, and deal enrichment |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- **Deal Sync to Continuum**: Spans `deal` service, `deal_sync` service, `dmapi` wrapper, and external Continuum DMAPI. Tracked via `deal_sync` database state.
- **AIDG Pipeline**: Spans AIDG frontend, AIDG backend service, AI gateway, Python microservices, Salesforce, and MongoDB. Coordinated via Pub/Sub topics.
- **Checkout Event Pipeline**: Spans external Kafka cluster, `kafka` bridge service, `checkout-events` service, and `checkoutDb` database.
- **Notification Delivery**: Spans any triggering service, `notifications` service (Pub/Sub), `email` service (SendGrid), `sms` service (Twilio).
