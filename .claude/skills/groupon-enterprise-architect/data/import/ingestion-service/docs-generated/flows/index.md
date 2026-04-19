---
service: "ingestion-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for the Operations Data Ingestion Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Ticket Escalation (Salesforce Case Creation)](ticket-escalation.md) | synchronous | API call from Zingtree or external tool | Receives case creation request, enriches with deal/customer context, creates Salesforce case via Composite API, queues on failure |
| [Failed Ticket Retry Job](failed-ticket-retry.md) | scheduled | Quartz scheduler (internal) | Reads one pending failed SF ticket request from MySQL queue and retries Salesforce case creation |
| [Merchant-Approved Refund Processing](merchant-approved-refund.md) | scheduled | Quartz scheduler (internal) | Fetches merchant-approved refund records from Salesforce and processes each order refund via CAAP API |
| [Customer Refund Request](customer-refund.md) | synchronous | API call from GSO agent tooling | Validates and executes an order refund via CAAP API to Groupon Bucks or original payment method |
| [JWT Token Generation](jwt-token-generation.md) | synchronous | API call from external consumer | Validates caller identity, generates a signed JWT token for a customer UUID using a stored JWK key |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

The **Ticket Escalation** flow spans multiple services and is modelled as a dynamic view in Structurizr:

- Architecture dynamic view: `dynamic-ticketEscalationFlow`
- Participants: `continuumIngestionService` → `lazloApi` → `salesForce`
- Related flows: [Ticket Escalation](ticket-escalation.md), [Failed Ticket Retry Job](failed-ticket-retry.md)

The **Merchant-Approved Refund Processing** flow spans Salesforce (data source), ingestion-service (orchestrator), and CAAP API (refund executor).
