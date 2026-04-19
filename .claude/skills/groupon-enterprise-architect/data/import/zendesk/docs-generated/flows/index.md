---
service: "zendesk"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 2
---

# Flows

Process and flow documentation for Zendesk.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Zendesk Ticket Flow](zendesk-ticket-flow.md) | synchronous | API call from Groupon internal service | Internal flow where the Zendesk API Integration component routes requests to the Ticketing and Case Management component to process support ticket operations |
| [Salesforce CRM Sync](salesforce-crm-sync.md) | synchronous | Ticket update or resolution event within Zendesk | Zendesk synchronizes support case data with Salesforce CRM to maintain a unified view of customer interactions |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The `dynamic-zendesk-ticket-flow` dynamic view in the architecture DSL documents the internal ticket processing flow within the `continuumZendesk` container. This view shows `zendeskApi` routing ticket and case operations to `zendeskTicketing`. Cross-service flows involving OgWall, Cyclops, and Global Support Systems are tracked in the central Continuum Platform architecture model.
