---
service: "cs-api"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 8
---

# Flows

Process and flow documentation for CS API (CaaP).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Agent Session Creation](agent-session-creation.md) | synchronous | Agent login action in Cyclops UI | Authenticates an agent, issues a CS token, and establishes a Redis-backed session |
| [Customer Info Aggregation](customer-info-aggregation.md) | synchronous | Agent opens customer record in Cyclops | Fans out to multiple services to assemble a unified customer profile for the agent |
| [Deal and Order Inquiry](deal-order-inquiry.md) | synchronous | Agent looks up orders or deals for a customer | Queries Orders Service and Deal Catalog; returns combined deal/order detail to agent |
| [Case Memo Management](case-memo-management.md) | synchronous | Agent creates, edits, or deletes a case memo | Reads and writes memo records to MySQL via the Repositories component |
| [Agent Ability Check](agent-ability-check.md) | synchronous | Cyclops UI requests agent capability context | Resolves the authenticated agent's abilities and roles from MySQL and returns them |
| [Convert to Cash Refund](convert-to-cash-refund.md) | synchronous | Agent initiates a convert-to-cash refund action | Validates eligibility and calls Incentives Service to convert a refund to Groupon Bucks |
| [Zendesk Ticket Sync](zendesk-ticket-sync.md) | synchronous | Agent creates or retrieves a support ticket | Proxies ticket creation and lookup requests to Zendesk via HTTP |
| [Customer Notification History](customer-notification-history.md) | synchronous | Agent views customer notification history | Queries notification history and returns paginated results to the agent UI |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 8 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All CS API flows are synchronous and cross service boundaries by fanning out HTTP calls to downstream Continuum services:

- **Customer Info Aggregation** spans `continuumUsersService`, `continuumConsumerDataService`, `continuumAudienceManagementService` — see [Customer Info Aggregation](customer-info-aggregation.md)
- **Deal and Order Inquiry** spans `continuumOrdersService`, `continuumDealCatalogService`, `continuumGoodsInventoryService`, `lazloApi` — see [Deal and Order Inquiry](deal-order-inquiry.md)
- **Convert to Cash Refund** spans `continuumIncentivesService` and `continuumOrdersService` — see [Convert to Cash Refund](convert-to-cash-refund.md)
- **Zendesk Ticket Sync** crosses the Continuum boundary to the external `zendesk` platform — see [Zendesk Ticket Sync](zendesk-ticket-sync.md)

> No architecture dynamic views are defined in the DSL model (`views/dynamics.dsl` contains no views). Sequence diagrams in each flow file are derived from the component and relationship model.
