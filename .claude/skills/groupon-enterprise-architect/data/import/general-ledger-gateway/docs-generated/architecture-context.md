---
service: "general-ledger-gateway"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers:
    - continuumGeneralLedgerGatewayApi
    - continuumGeneralLedgerGatewayPostgres
    - continuumGeneralLedgerGatewayRedis
---

# Architecture Context

## System Context

General Ledger Gateway sits within the Continuum platform as a SOX-inscoped finance service. It mediates all interactions between Accounting Service (internal FED platform service) and NetSuite ERP instances (external Oracle SaaS). Accounting Service calls GLG to create and query invoices; GLG translates those calls into OAuth-signed NetSuite RESTlet requests. GLG also runs batch jobs to pull applied invoice records from NetSuite and push them back into Accounting Service.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| General Ledger Gateway API | `continuumGeneralLedgerGatewayApi` | Service | Java, Dropwizard | REST service exposing invoice, ledger entry, and job endpoints; calls NetSuite and Accounting Service |
| General Ledger Gateway DB | `continuumGeneralLedgerGatewayPostgres` | Database | PostgreSQL | Stores invoices, ledger entry mappings, and Quartz job store state |
| General Ledger Gateway Redis Cache | `continuumGeneralLedgerGatewayRedis` | Cache | Redis | Caches NetSuite lookup results (e.g., currency records) |

## Components by Container

### General Ledger Gateway API (`continuumGeneralLedgerGatewayApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Invoice Resource | REST endpoints for invoice lookup (`GET /v1/invoices/{uuid}`) and send (`PUT /v1/invoices/{ledger}/send`) | JAX-RS |
| Ledger Entry Map Resource | REST endpoints for ledger entry mapping lookups by UUID or ledger ID | JAX-RS |
| Job Resource | REST endpoint to trigger import jobs on demand (`POST /v1/{ledger}/jobs/import-applied-invoices`) | JAX-RS |
| Invoice Service | Sends invoices to the appropriate NetSuite ledger instance | Java |
| Applied Invoice Service | Processes applied invoices downloaded from NetSuite and applies them in Accounting Service | Java |
| Job Service | Triggers Quartz jobs on demand via the scheduler | Java |
| Import Applied Invoices Job | Quartz job that pages through NetSuite saved search results for applied invoices and processes each one | Quartz Job |
| Quartz Scheduler | Manages CronScheduler and AdHocScheduler instances; persists job state to PostgreSQL | Quartz |
| NetSuite Client Manager | Selects and initialises the correct NetSuite client for a given ledger instance | HTTP Client |
| Accounting Service Client | Issues invoice create, show, and apply HTTP calls to Accounting Service | HTTP Client |
| NetSuite Client Cache | Wraps NetSuite lookup results in Redis via Lettuce | Lettuce/Redis |
| Data Access | JDBI 3 DAOs for reading/writing invoices and ledger entry map records | JDBI |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumGeneralLedgerGatewayApi` | `continuumGeneralLedgerGatewayPostgres` | Read/write invoices, ledger mappings, Quartz job store | JDBC |
| `continuumGeneralLedgerGatewayApi` | `continuumGeneralLedgerGatewayRedis` | Cache NetSuite lookups | Redis |
| `continuumGeneralLedgerGatewayApi` | Accounting Service | Invoice create, show, apply | HTTPS |
| `continuumGeneralLedgerGatewayApi` | NetSuite ERP | Ledger invoice updates and applied invoice downloads | HTTPS (OAuth 1.0) |

> External targets (Accounting Service and NetSuite ERP) are referenced as stubs in the local architecture model because they are not yet part of the federated model.

## Architecture Diagram References

- Component: `components-GeneralLedgerGatewayApiComponents`
- Dynamic: `ImportAppliedInvoices` (import-applied-invoices job flow)
