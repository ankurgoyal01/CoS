---
service: "getaways-partner-integrator"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumGetawaysPartnerIntegratorDb"
    type: "mysql"
    purpose: "Partner mappings, reservations, and SOAP request/response logs"
---

# Data Stores

## Overview

Getaways Partner Integrator owns a single MySQL database (`continuumGetawaysPartnerIntegratorDb`) as its primary persistent store. All state — hotel/room/rate plan mapping records, reservation data, and partner SOAP interaction logs — is persisted here. Access is managed exclusively through the `getawaysPartnerIntegrator_persistenceLayer` component using JDBI3 via `jtier-jdbi3` and `jtier-daas-mysql`.

## Stores

### Getaways Partner Integrator DB (`continuumGetawaysPartnerIntegratorDb`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumGetawaysPartnerIntegratorDb` |
| Purpose | Stores hotel/room/rate plan mappings between Groupon inventory and partner channel managers; persists reservation records; logs SOAP request/response payloads |
| Ownership | owned |
| Migrations path | Not discoverable from architecture inventory — contact Travel team |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Hotel/room/rate plan mappings | Maps Groupon inventory identifiers to channel manager partner identifiers for ARI synchronization | Groupon inventory ID, partner hotel/room/rate IDs, channel manager type, mapping status |
| Reservation records | Stores reservation data received from or confirmed with channel managers | Reservation ID, partner reference, status, dates, guest info |
| SOAP request/response logs | Audit log of all outbound SOAP calls made by `partnerSoapClient` to channel managers | Timestamp, partner, operation, request payload, response payload, status |

#### Access Patterns

- **Read**: Mapping lookups by Groupon inventory ID or partner identifier; reservation queries by reservation ID or status; log retrieval for auditing
- **Write**: Mapping upserts from REST PUT and MBus worker processing; reservation inserts and status updates from SOAP inbound processing; SOAP log inserts after every outbound channel manager call
- **Indexes**: Not discoverable from architecture inventory; expected indexes on hotel/room mapping identifiers and reservation ID

## Caches

> No evidence found of any cache layer (Redis, Memcached, or in-memory) for this service.

## Data Flows

All data flows through the `getawaysPartnerIntegrator_persistenceLayer` component:

- **Inbound SOAP (channel managers)** → `soapApi` → `reservationService` / `getawaysPartnerIntegrator_mappingService` → `getawaysPartnerIntegrator_persistenceLayer` → MySQL (writes reservation records and logs)
- **Inbound Kafka** → `getawaysPartnerIntegrator_kafkaConsumer` → `getawaysPartnerIntegrator_mappingService` → `getawaysPartnerIntegrator_persistenceLayer` → MySQL (updates mappings)
- **Inbound MBus** → `mbusWorker` → `getawaysPartnerIntegrator_mappingService` → `getawaysPartnerIntegrator_persistenceLayer` → MySQL (reads/writes mappings)
- **REST API** → `getawaysPartnerIntegrator_restApi` → `getawaysPartnerIntegrator_mappingService` → `getawaysPartnerIntegrator_persistenceLayer` → MySQL (reads and writes mapping records)
- **Outbound SOAP** → `partnerSoapClient` → `getawaysPartnerIntegrator_persistenceLayer` → MySQL (inserts SOAP request/response logs)
