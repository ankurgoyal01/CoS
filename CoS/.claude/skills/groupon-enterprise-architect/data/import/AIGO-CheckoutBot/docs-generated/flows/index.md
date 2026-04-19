---
service: "AIGO-CheckoutBot"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for AIGO-CheckoutBot.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [User Message to Response](user-message-to-response.md) | synchronous | User submits a message via the Chat Widget | End-to-end processing of a user chat message through the backend, LLM, and response delivery |
| [Design Tree Update](design-tree-update.md) | synchronous | Admin operator saves a tree node change in the Admin Frontend | Admin-initiated update of a conversation decision tree node persisted to PostgreSQL |
| [Deal Simulation Replay](deal-simulation-replay.md) | batch | Operator triggers a simulation run from the Admin Frontend | Replays a predefined conversation scenario through the decision tree to validate flow behavior |
| [Analytics Aggregation and Reporting](analytics-aggregation-and-reporting.md) | scheduled | Periodic schedule or manual trigger from the Admin Frontend | Aggregates conversation event data from PostgreSQL and produces analytics reports |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

The **User Message to Response** flow crosses into external systems: it calls OpenAI GPT or Google Gemini for LLM completions, optionally creates Salesforce cases on escalation, and publishes events to the Salted engagement platform. These cross-service interactions are modelled in the central architecture dynamic view `chatConversationFlow`. See [Architecture Context](../architecture-context.md) for container relationship details.
