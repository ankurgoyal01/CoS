---
service: "contract-data-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Contract Data Service (CoDS).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Contract Term Upsert](contract-term-upsert.md) | synchronous | API call to `POST /v1/contractTerm` | Deduplicate and persist a contract term by hash |
| [Contract Party Upsert](contract-party-upsert.md) | synchronous | API call to `PUT /v1/contractParty` | Insert or update a merchant contract party record |
| [Payment Invoicing Configuration Upsert](payment-invoicing-config-upsert.md) | synchronous | API call to `PUT /v1/paymentInvoicingConfiguration` | Insert or update a payment invoicing configuration |
| [Aggregate Contract Creation](aggregate-contract-creation.md) | synchronous | API call to `POST /v1/contract` | Create a full contract record (party + multiple terms + invoicing config) in one request |
| [Deal Backfill Sync](deal-backfill-sync.md) | synchronous | API call to `GET /v1/backfillDeal/{historicalContractNumber}/{dealUUID}` | Migrate legacy deal/contract data from DMAPI and Deal Catalog into CoDS format |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The Deal Backfill Sync flow spans multiple services:
- [Deal Backfill Sync](deal-backfill-sync.md) — references architecture dynamic view `dynamic-contract-data-service-backfill-sync`
- Participants: `continuumContractDataService`, `continuumDealManagementApi`, `continuumDealCatalogService`
