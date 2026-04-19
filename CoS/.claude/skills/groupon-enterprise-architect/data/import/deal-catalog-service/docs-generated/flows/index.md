---
service: "deal-catalog-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Deal Catalog Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Deal Metadata Ingestion](deal-metadata-ingestion.md) | synchronous | Salesforce push / Deal Management API call | Deal metadata is received, validated, persisted, indexed, and published |
| [Deal Browsing and Retrieval](deal-browsing-retrieval.md) | synchronous | Consumer API request | Consumer browses or searches for deals via Lazlo API gateway |
| [Deal Lifecycle Event Publishing](deal-lifecycle-event-publishing.md) | asynchronous | Deal creation or update | Deal lifecycle events published to MBus for downstream consumers |
| [Node Payload Refresh](node-payload-refresh.md) | scheduled | Quartz cron schedule | Scheduled jobs fetch remote node payloads and update node state |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- **Deal Creation & Publishing Flow** (`dynamic-continuum-deal-creation`): Merchant creates a deal via Salesforce; flows through Deal Management API, Deal Catalog, Marketing Deal Service, and inventory services until the deal is live on the platform.
- **Deal Lifecycle -- Browsing and Retrieval** (`dynamic-continuum-deal-catalog`): Consumer browsing flows from Lazlo to Deal Catalog and Relevance API.
- **Online Booking Reservation Flow** (`dynamic-continuum-online-booking`): Online Booking API fetches deal configuration from Deal Catalog as part of reservation creation.
