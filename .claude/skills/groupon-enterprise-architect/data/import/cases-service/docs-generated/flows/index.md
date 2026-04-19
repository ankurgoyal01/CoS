---
service: "cases-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for the Merchant Cases Service (MCS).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Case Creation](case-creation.md) | synchronous | Merchant submits support case via Merchant Center | Validates merchant context, creates Salesforce Case object, triggers email and notification |
| [Case Retrieval](case-retrieval.md) | synchronous | Merchant opens support inbox or views a specific case | Fetches case list or single case from Salesforce with Redis-backed unread count |
| [Case Reply](case-reply.md) | synchronous | Merchant posts a reply to an open case | Creates EmailMessage in Salesforce and dispatches transactional email via Rocketman |
| [Message Bus Case Event Processing](message-bus-case-event-processing.md) | asynchronous | Salesforce publishes case lifecycle event to JMS topic | Consumes event, refreshes Redis unread count, dispatches merchant notification |
| [Deal Approval Case Flow](deal-approval-case-flow.md) | synchronous | Merchant submits a deal edit requiring approval | Creates deal-edit case in Salesforce linked to deal UUID, tracks approval status |
| [Knowledge Management Search](knowledge-management-search.md) | synchronous | Merchant searches for self-service help content | Queries Inbenta per-locale API, returns articles, topics, and suggestions |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 0 |
| Hybrid (sync + async side-effects) | 1 |

## Cross-Service Flows

- **Case Creation** and **Case Reply** span `continuumMerchantCaseService` → Salesforce → `mxNotificationService` → `rocketmanEmailApi`. The dynamic view `dynamic-cases-case-flow` in the architecture model captures the internal component flow.
- **Message Bus Case Event Processing** originates in Salesforce, flows through the Groupon message bus (`messageBus`), is consumed by `continuumMerchantCaseService`, and terminates in `mxNotificationService` or Redis updates.
- See the architecture dynamic view: `dynamic-cases-case-flow`
