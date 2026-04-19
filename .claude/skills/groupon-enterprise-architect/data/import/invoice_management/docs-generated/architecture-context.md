---
service: "invoice_management"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [goodsInvoiceAggregator, continuumInvoiceManagementPostgres]
---

# Architecture Context

## System Context

invoice_management sits within the **Continuum** platform as a backend service in the Goods Commerce domain. It is an event-driven aggregator: it consumes purchase order, receiver, shipment, and sales order events from the Goods Message Bus and materialises them into invoices and payment records in its PostgreSQL database. Downstream, it transmits invoices and payment data to NetSuite for accounting, stores remittance reports in AWS S3, and sends notification emails via Rocketman. The service exposes a REST API for operational queries (invoice listing, payment pulls, report exports) consumed by internal Goods tooling and finance operators.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Goods Invoice Aggregator | `goodsInvoiceAggregator` | Backend service | Java 8 / Play Framework 2.x | Skeletor 0.99.8 | Core invoicing service; consumes Goods events; manages invoices, payments, receivers, POs; transmits to NetSuite |
| Invoice Management PostgreSQL | `continuumInvoiceManagementPostgres` | Database | PostgreSQL | 42.3.1 (JDBC driver) | Stores invoices, payments, receivers, purchase orders, and scheduled job tracking data |

## Components by Container

### Goods Invoice Aggregator (`goodsInvoiceAggregator`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| PO Event Consumer | Consumes PO events from Message Bus; creates invoice records | mbus-client 1.2.7 |
| GMO Event Consumer | Consumes marketplace item shipped events; creates marketplace invoices | mbus-client 1.2.7 |
| SRS Event Consumer | Consumes sales order update events; updates invoice state | mbus-client 1.2.7 |
| STS Event Consumer | Consumes shipment tracking events; updates shipment status | mbus-client 1.2.7 |
| Receiver Event Consumer | Consumes Receiver events; creates receiver records | mbus-client 1.2.7 |
| Invoice Controller | Exposes REST endpoints for invoice listing, creation, and management | Play Framework |
| Payment Controller | Exposes REST endpoints for payment fetch, reconciliation, and export | Play Framework |
| NetSuite Transmitter | Transmits invoices to NetSuite via OAuth 1.0a REST API | scribe 1.3.7 |
| NetSuite Callback Handler | Handles `/ns_callback` webhook from NetSuite for payment status updates | Play Framework |
| Remittance Report Generator | Generates Excel remittance reports using Apache POI; uploads to AWS S3 | poi 3.12 + aws-java-sdk |
| 3PL Invoice Generator | Generates invoices for third-party logistics partners | Play Framework |
| Quartz Job Scheduler | Schedules recurring jobs (payment fetch, invoice transmission, report generation) | quartz-scheduler 2.1.1 |
| Invoice Repository | ORM-backed data access for all invoice and payment entities | ebean ORM + PostgreSQL |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `goodsInvoiceAggregator` | `continuumInvoiceManagementPostgres` | Reads and writes invoices, payments, receivers, POs | JDBC / SQL |
| `goodsInvoiceAggregator` | Message Bus | Consumes PO, Receiver, SRS, GMO, STS events | Message Bus (mbus-client) |
| `goodsInvoiceAggregator` | NetSuite | Transmits invoices and receives payment callbacks | REST / HTTPS (OAuth 1.0a) |
| `goodsInvoiceAggregator` | AWS S3 | Uploads remittance reports | AWS SDK (HTTPS) |
| `goodsInvoiceAggregator` | Rocketman | Sends invoice and remittance notification emails | REST / HTTP |
| `goodsInvoiceAggregator` | Shipment Tracker | Queries shipment status | REST / HTTP |
| `goodsInvoiceAggregator` | Goods Stores API | Queries vendor/store data for invoice enrichment | REST / HTTP |
| `goodsInvoiceAggregator` | Accounting Service | Sends accounting entries for invoice events | REST / HTTP |
| `goodsInvoiceAggregator` | Commerce Interface | Queries order data | REST / HTTP |
| `goodsInvoiceAggregator` | GPAPI | Queries goods platform data | REST / HTTP |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-goodsInvoiceAggregator`
