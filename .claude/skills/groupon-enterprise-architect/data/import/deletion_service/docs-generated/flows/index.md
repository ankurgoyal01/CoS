---
service: "deletion_service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for the Deletion Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [GDPR Erase Event Ingestion](erase-event-ingestion.md) | event-driven | MBUS message on `jms.topic.gdpr.account.v1.erased` | Receives an account erase event, validates the payload, and creates per-service erasure task records in the database |
| [Scheduled Erasure Execution](scheduled-erasure-execution.md) | scheduled | Quartz job every 30 minutes | Scans for pending erase requests and executes erasure across each registered downstream service |
| [Orders Data Erasure](orders-data-erasure.md) | batch | Triggered by Scheduled Erasure Execution flow per request | Reads a customer's fulfillment line items from the Orders MySQL database and anonymises PII fields |
| [SMS Consent Erasure (Attentive)](sms-consent-erasure.md) | event-driven | MBUS message on `jms.topic.scs.subscription.erasure` or `ATTENTIVE` option on POST /customer | Sends an Attentive SMS consent deletion notification via Rocketman and records the send ID |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- The **GDPR Erase Event Ingestion** flow spans the upstream account management system (publishes to MBUS) and the Deletion Service (consumes from MBUS). The dynamic view `dynamic-erase-request-flow` in the architecture DSL captures the end-to-end path.
- The **Scheduled Erasure Execution** flow spans the Deletion Service, Orders MySQL (owned by the Orders service), and the Rocketman API (external).
- Both flows terminate with a completion event published to `jms.queue.gdpr.account.v1.erased.complete`, which is consumed by downstream GDPR audit and reporting systems.
