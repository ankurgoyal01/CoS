---
service: "getaways-payment-reconciliation"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumGetawaysPaymentReconciliationService", "continuumGetawaysPaymentReconciliationDb"]
---

# Architecture Context

## System Context

Getaways Payment Reconciliation sits within the **Continuum Platform** (`continuumSystem`) as a finance operations service for the Getaways (Travel) domain. It bridges external EAN invoice data with Groupon's internal inventory and accounting systems. The service receives invoice files from Gmail (external), consumes inventory update events from the internal MBus, calls the Maris inventory service and Accounting Service for data enrichment and payment creation, and notifies the finance team by email. No end-customer traffic flows through this service; it is operated by internal finance and engineering staff.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Getaways Payment Reconciliation Service | `continuumGetawaysPaymentReconciliationService` | Application | Java, Dropwizard | JTier 5.14.1 | Main application: reconciliation API, web UI, workers, email import, MBus consumer |
| Getaways Payment Reconciliation DB | `continuumGetawaysPaymentReconciliationDb` | Database | MySQL | — | Stores invoices, reservations, reconciliation status, and reconciliation outputs |

## Components by Container

### Getaways Payment Reconciliation Service (`continuumGetawaysPaymentReconciliationService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Web Resources | Serves reconciliation REST API and web UI; routes requests to Invoice Payments Service and Accounting Service Client | JAX-RS |
| Invoice Payments Service | Business logic to validate invoice totals against reservation data and reconcile payments | Java |
| Accounting Service Client | HTTP client that creates vendor invoices in the external Accounting Service | HTTP |
| Reconciliation Worker | Scheduled worker that drives periodic reconciliation; reads/writes DB, calls Invoice Payments Service, sends notifications | Java |
| Email Reader Script Executor | Schedules and executes the Python invoice import script on a timer | Java |
| Invoice Importer Script | Python script that authenticates to Gmail via OAuth2, downloads invoice attachments via IMAP, parses CSV/Excel, bulk-loads rows into MySQL, updates import status | Python |
| Message Bus Consumer | Consumes inventory-units-updated messages from the MBus topic | JMS |
| Message Bus Processor | Processes consumed inventory update messages; fetches unit details from Maris; persists reservation records to DB | Java |
| Maris Client | HTTP client for fetching inventory unit details from the Maris service | HTTP |
| Notification Service | Sends reconciliation status notifications via SMTP | SMTP |
| JDBI DAOs | Database access layer for all reconciliation entities (invoices, reservations, import status) | JDBI |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumGetawaysPaymentReconciliationService` | `continuumGetawaysPaymentReconciliationDb` | Reads/writes reconciliation data | JDBC/MySQL |
| `webResources` | `invoicePaymentsService` | Validates and reconciles invoice totals | direct |
| `webResources` | `getawaysPaymentReconciliation_accountingServiceClient` | Creates vendor invoices | direct |
| `webResources` | `jdbiDaos` | Reads/writes reconciliation data | direct |
| `invoicePaymentsService` | `jdbiDaos` | Reads reconciliation data | direct |
| `reconciliationWorker` | `jdbiDaos` | Reads/writes reconciliation data | direct |
| `reconciliationWorker` | `getawaysPaymentReconciliation_notificationService` | Sends reconciliation notifications | direct |
| `reconciliationWorker` | `invoicePaymentsService` | Validates totals | direct |
| `getawaysPaymentReconciliation_messageBusConsumer` | `messageBusProcessor` | Delivers inventory update messages | direct |
| `messageBusProcessor` | `marisClient` | Fetches inventory unit details | direct |
| `messageBusProcessor` | `jdbiDaos` | Stores reservations | direct |
| `emailReaderScriptExecutor` | `invoiceImporterScript` | Executes invoice import | process exec |
| `invoiceImporterScript` | `jdbiDaos` | Loads invoice data | direct (MySQL bulk load) |
| `continuumGetawaysPaymentReconciliationService` | Accounting Service API (external) | Creates vendor invoices | HTTP |
| `continuumGetawaysPaymentReconciliationService` | Maris Inventory API (external) | Fetches inventory units | HTTP |
| `continuumGetawaysPaymentReconciliationService` | MBus inventory-units-updated topic | Consumes inventory update messages | JMS |
| `continuumGetawaysPaymentReconciliationService` | Gmail (IMAP) | Downloads invoice attachments | IMAP/OAuth2 |
| `continuumGetawaysPaymentReconciliationService` | Gmail (SMTP) | Sends invoice import status email | SMTP/OAuth2 |
| `continuumGetawaysPaymentReconciliationService` | Groupon SMTP Server | Sends reconciliation notifications | SMTP |

## Architecture Diagram References

- Component: `components-getaways-payment-reconciliation-components`
