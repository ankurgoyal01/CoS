---
service: "accounting-service"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumAccountingService, continuumAccountingMysql, continuumAccountingRedis]
---

# Architecture Context

## System Context

Accounting Service is a backend container within the Continuum platform. It sits at the intersection of merchant commerce and finance, receiving contract data from Salesforce, consuming inventory and order events from internal Continuum services via the Message Bus, and persisting all accounting domain data to its own MySQL database. External finance systems (NetSuite) and file transfer services are downstream stubs. Internal consumers query accounting data through its REST API.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Accounting Service | `continuumAccountingService` | Backend | Ruby on Rails | 4.1.16 | Rails service that imports contracts, processes accounting events, and manages merchant payments and invoices |
| Accounting MySQL | `continuumAccountingMysql` | Database | MySQL | — | Primary relational datastore for accounting entities and workflows (contracts, invoices, transactions, payments, vendors) |
| Accounting Redis | `continuumAccountingRedis` | Cache / Queue | Redis | — | Queueing and cache store used by Resque workers and asynchronous workflows |

## Components by Container

### Accounting Service (`continuumAccountingService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `acctSvc_apiEndpoints` | Rails controllers and serializers for internal APIs and operational endpoints | Rails Controllers |
| `acctSvc_contractImport` | Import workflows that ingest contract and deal metadata and persist accounting models | Ruby Services |
| `acctSvc_ingestion` | Workers handling ASL, IPV, VIS, VTS, and TPS ingest and normalization into accounting models | Resque Workers |
| `acctSvc_paymentAndInvoicing` | Business workflows that generate transactions, statements, invoices, and merchant payments | Ruby Domain Services |
| `acctSvc_reportingExports` | Scheduled reporting, reconciliation, and outbound file and export generation | Ruby Jobs |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumAccountingService` | `continuumAccountingMysql` | Reads and writes accounting domain data | ActiveRecord / SQL |
| `continuumAccountingService` | `continuumAccountingRedis` | Uses queues, locks, and cache for async workloads | Redis protocol |
| `continuumAccountingService` | `salesForce` | Imports contracts and syncs merchant/account metadata | REST / API |
| `continuumAccountingService` | `continuumDealCatalogService` | Fetches deal and option metadata during contract processing | REST |
| `continuumAccountingService` | `continuumOrdersService` | Retrieves order and refund data for TPS/ASL flows | REST |
| `continuumAccountingService` | `continuumVoucherInventoryService` | Fetches voucher and inventory product state | REST |
| `continuumAccountingService` | `messageBus` | Consumes and publishes accounting domain events | Message Bus |
| `acctSvc_apiEndpoints` | `acctSvc_contractImport` | Triggers contract import and update commands | Direct |
| `acctSvc_apiEndpoints` | `acctSvc_paymentAndInvoicing` | Triggers invoice and payment workflows | Direct |
| `acctSvc_contractImport` | `acctSvc_ingestion` | Resolves inventory lineage and data-source mappings | Direct |
| `acctSvc_ingestion` | `acctSvc_paymentAndInvoicing` | Publishes normalized accounting events for transaction creation | Direct |
| `acctSvc_paymentAndInvoicing` | `acctSvc_reportingExports` | Provides statement, invoice, and payment data for exports | Direct |

## Architecture Diagram References

- Component: `components-continuum-accounting-service`

> Dynamic views are not yet defined for this service. See [Flows](flows/index.md) for process-level sequence documentation.
