---
service: "glive-gia"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 7
---

# Flows

Process and flow documentation for GrouponLive Inventory Admin (GIA).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Deal Creation from DMAPI](deal-creation-from-dmapi.md) | synchronous | Admin user action (multi-step wizard) | Admin creates a live event deal in GIA, pulling deal data from the Deal Management API and persisting the deal through a wizard workflow |
| [Event Management and Bulk Updates](event-management-and-bulk-updates.md) | synchronous | Admin user action | Admin creates, edits, or bulk-updates events on a deal; updates are written to MySQL and optionally pushed to the Inventory Service |
| [Ticketmaster Event Import](ticketmaster-event-import.md) | scheduled | Resque scheduler (cron) | Background job pulls event listings and availability from the Ticketmaster API and updates deal events in GIA |
| [Invoice Creation and Payment](invoice-creation-and-payment.md) | synchronous + asynchronous | Admin user action / background job | Admin triggers invoice generation for a deal; worker creates invoice and payment records in GIA and pushes entries to the Accounting Service |
| [Salesforce Deal Sync](salesforce-deal-sync.md) | scheduled | Resque scheduler (cron) | Background job syncs deal contract data from Salesforce into GIA, creating or updating local deal records |
| [Uninvoiced Deal Detection](uninvoiced-deal-detection.md) | scheduled | Resque scheduler (cron) | Background job scans for deals that should have been invoiced but have not been, generating a report or alert for the operations team |
| [User Role Management](user-role-management.md) | synchronous | Admin user action | Admin creates, updates, or deactivates GIA user accounts and assigns roles; Pundit policies enforce authorization |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 3 |
| Mixed (synchronous trigger + async processing) | 1 |

## Cross-Service Flows

The following flows span GIA and other Continuum platform services:

- [Deal Creation from DMAPI](deal-creation-from-dmapi.md) — crosses into `continuumDealManagementApi` for deal data retrieval
- [Invoice Creation and Payment](invoice-creation-and-payment.md) — crosses into `continuumAccountingService` for ledger entries
- [Salesforce Deal Sync](salesforce-deal-sync.md) — crosses into `salesForce` (external) for contract data
- [Ticketmaster Event Import](ticketmaster-event-import.md) — crosses into Ticketmaster API (external) for event data
- [Event Management and Bulk Updates](event-management-and-bulk-updates.md) — crosses into Inventory Service for availability sync

> Central architecture dynamic views for cross-service flows are defined in `structurizr/import/glive-gia/architecture/views/dynamics.dsl` (currently no dynamic views defined; see architecture IDs for reference).
