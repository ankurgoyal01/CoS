---
service: "vss"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Voucher Smart Search (VSS).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Voucher Search](voucher-search.md) | synchronous | HTTP GET/POST from Merchant Centre | Merchant searches vouchers by name, code, or email; VSS queries local MySQL and returns matched voucher-user records |
| [Inventory Unit Ingestion](inventory-unit-ingestion.md) | event-driven | JMS event on `InventoryUnits.Updated` topics | VSS receives inventory update events from VIS v1 and VIS 2.0 and upserts voucher unit data into local MySQL |
| [User Data Sync](user-data-sync.md) | event-driven | JMS events on user account topics | VSS receives user update, email change, and GDPR erasure events and applies changes to voucher-user records in MySQL |
| [Voucher Backfill](voucher-backfill.md) | scheduled | Quartz scheduler (periodic) | Scheduled job fetches voucher units from VIS, enriches with user data, and writes complete records into MySQL |
| [GDPR User Obfuscation](gdpr-user-obfuscation.md) | synchronous | HTTP POST from authorized caller | Caller submits user IDs for GDPR erasure; VSS obfuscates name and email fields in all matching voucher records |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- **Voucher Search** spans `merchantCenter` → `continuumVssService` → `continuumVssMySql`
- **Inventory Unit Ingestion** spans `mbus` → `continuumVssService` → `continuumVssMySql`
- **User Data Sync** spans `mbus` → `continuumVssService` → `continuumVssMySql`
- **Voucher Backfill** spans `continuumVssService` → `continuumVoucherInventoryService` / `visInventory` → `continuumUsersService` → `continuumVssMySql`
- **GDPR User Obfuscation** spans authorized caller → `continuumVssService` → `continuumVssMySql`

Cross-service relationships are defined in `C:\git\Groupon\architecture\structurizr\import\vss\architecture\models\relations.dsl`.
