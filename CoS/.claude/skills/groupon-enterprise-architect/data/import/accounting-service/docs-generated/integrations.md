---
service: "accounting-service"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 6
internal_count: 4
---

# Integrations

## Overview

Accounting Service integrates with one external SaaS system (Salesforce) and five internal Continuum platform services. Four integrations are active in the federated architecture model; two (NetSuite, File Transfer/Sharing) are present as stubs representing intended but not-yet-federated dependencies. Internal dependencies are accessed via REST APIs and the Groupon Message Bus.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | REST | Contract and merchant account data import | yes | `salesForce` |
| NetSuite | REST (stub) | Invoice, vendor, and merchant payment export to general ledger | yes | stub — `netSuite` |
| File Transfer Service | SFTP/REST (stub) | Receives upstream booking and integration files | no | stub — `fileTransferService` |
| File Sharing Service | REST (stub) | Retrieves and stores generated integration and reporting files | no | stub — `fileSharingService` |

### Salesforce Detail

- **Protocol**: REST
- **Base URL / SDK**: Configured via environment variable; accessed during contract import pipeline execution
- **Auth**: API credentials stored as secrets (not documented by value)
- **Purpose**: Primary source of merchant contract data. The contract import pipeline (`acctSvc_contractImport`) pulls contract and merchant/account metadata from Salesforce and persists it to `continuumAccountingMysql`
- **Failure mode**: Contract import jobs fail and are retried; gaps in contract data may cause downstream invoicing to use stale contract terms
- **Circuit breaker**: No evidence found

### NetSuite Detail

- **Protocol**: REST (stub — not currently active in federated model)
- **Base URL / SDK**: Not discoverable from current inventory
- **Auth**: Not discoverable from current inventory
- **Purpose**: Export of invoices, vendors, and merchant payment updates to the NetSuite general ledger system
- **Failure mode**: Export jobs would fail; general ledger would not reflect latest accounting state
- **Circuit breaker**: No evidence found

### File Transfer Service Detail

- **Protocol**: SFTP/REST (stub — not currently active in federated model)
- **Base URL / SDK**: Not discoverable from current inventory
- **Auth**: Not discoverable from current inventory
- **Purpose**: Receives upstream booking and integration files for ingestion
- **Failure mode**: Ingestion of upstream file-based data would halt
- **Circuit breaker**: No evidence found

### File Sharing Service Detail

- **Protocol**: REST (stub — not currently active in federated model)
- **Base URL / SDK**: Not discoverable from current inventory
- **Auth**: Not discoverable from current inventory
- **Purpose**: Retrieves and stores generated integration and reporting output files
- **Failure mode**: Reporting exports would not be retrievable or publishable
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Catalog Service | Message Bus | Consumes `DealCatalogDistribution` events to normalize deal/option metadata into accounting models | `continuumDealCatalogService` |
| Orders Service (TPS) | REST | Retrieves order and refund data for transaction and ASL flow processing | `continuumOrdersService` |
| Voucher Inventory Service | REST + Message Bus | Fetches voucher and inventory product state; consumes `inventory-product-voucher-updates` events | `continuumVoucherInventoryService` |
| Message Bus | Message Bus protocol | Central pub/sub broker for all async event publishing and consumption | `messageBus` |
| Voucher Transaction Service | REST (stub) | Fetches voucher transactions for dynamic pricing flows | stub — `voucherTransactionService` |
| Accounting Service Ledger | Direct (stub) | Reads and writes ledger event context for payment calculations | stub — `accountingServiceLedger` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known consumers include internal finance tooling, merchant payment operations, and services that query vendor contracts, transactions, and invoices via the v3/v2/v1 REST APIs.

## Dependency Health

- `continuumAccountingMysql` and `continuumAccountingRedis` health is surfaced via the `/api/v3/health` endpoint
- No evidence found of explicit circuit breaker patterns for external REST integrations (Salesforce, Orders Service, Voucher Inventory Service)
- Failed Resque jobs for Message Bus consumers accumulate in the Redis failed queue; see [Runbook](runbook.md) for handling procedures
- Stub integrations (NetSuite, File Transfer, File Sharing, Voucher Transaction Service, Accounting Service Ledger) are not represented in the active architecture model and their health is not monitored at this time
