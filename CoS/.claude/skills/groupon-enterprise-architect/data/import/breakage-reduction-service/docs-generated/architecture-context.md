---
service: "breakage-reduction-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumBreakageReductionService", "continuumBreakageReductionRedis"]
---

# Architecture Context

## System Context

The Breakage Reduction Service sits within Groupon's **Continuum** platform, inside the Redemption domain. It acts as the orchestration hub for post-purchase breakage reduction: consumer-facing clients (web/mobile) invoke its HTTP endpoints to retrieve what next-actions apply to a given voucher. BRS aggregates context from ten or more downstream Continuum services, evaluates workflow eligibility rules, and schedules reminder and notification jobs through the RISE scheduler. It owns a Redis cache for workflow helper state and has no directly owned relational database.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Breakage Reduction Service | `continuumBreakageReductionService` | Service | Node.js (I-Tier) | ^16 | HTTP service exposing voucher next-actions, reminder scheduling, message-content, and backfill endpoints |
| Breakage Reduction Redis | `continuumBreakageReductionRedis` | Cache | Redis | 2.x (client) | Key-value cache used by workflow helper logic |

## Components by Container

### Breakage Reduction Service (`continuumBreakageReductionService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| BRS API Routes (`brsApiRoutes`) | OpenAPI route definitions and request routing for voucher, reminder, message, backfill, and deprecated extension endpoints | Node.js Modules |
| Voucher Next Actions Handler (`voucherNextActionsHandler`) | Computes next actions for vouchers using workflow rules and response assembly | Node.js Module |
| Remind-Me-Later Handler (`reminderHandler`) | Validates reminder requests and schedules reminder actions in RISE | Node.js Module |
| Backfill Handler (`backfillHandler`) | Backfills and schedules notification workflows in bulk or per voucher | Node.js Module |
| Message Content Handler (`messageContentHandler`) | Assembles campaign message content for push/in-app responses | Node.js Module |
| Storage Facade (`storageFacade`) | Shared storage/orchestration layer that coordinates downstream data fetches and workflow inputs | Node.js Class |
| Service Client Adapters (`serviceClientAdapters`) | Gofer-based HTTP clients for VIS, TPIS, Orders, Deal Catalog, Users, Merchant, Place, UGC, EPODS, AMS, and RISE | Node.js Modules |
| Notification Workflow Engine (`workflowEngine`) | Workflow helper/notification execution logic used to compute and filter eligible next-actions | Node.js Modules |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumBreakageReductionService` | `continuumVoucherInventoryApi` | Reads/updates inventory units/products and availability | HTTPS/JSON |
| `continuumBreakageReductionService` | `continuumThirdPartyInventoryService` | Reads third-party inventory units/products | HTTPS/JSON |
| `continuumBreakageReductionService` | `continuumDealCatalogService` | Resolves deal metadata and products | HTTPS/JSON |
| `continuumBreakageReductionService` | `continuumOrdersService` | Fetches order details, summaries, and refund amounts | HTTPS/JSON |
| `continuumBreakageReductionService` | `continuumEpodsService` | Fetches booking segment resources/details | HTTPS/JSON |
| `continuumBreakageReductionService` | `continuumM3MerchantService` | Fetches merchant profile data | HTTPS/JSON |
| `continuumBreakageReductionService` | `continuumPlaceReadService` | Fetches redemption location/place data | HTTPS/JSON |
| `continuumBreakageReductionService` | `continuumUgcService` | Fetches user review ratings | HTTPS/JSON |
| `continuumBreakageReductionService` | `continuumUsersService` | Fetches user account details | HTTPS/JSON |
| `continuumBreakageReductionService` | `continuumAudienceManagementService` | Fetches customer authority attributes | HTTPS/JSON |
| `continuumBreakageReductionService` | `continuumBreakageReductionRedis` | Reads/writes helper state for workflow features | TCP/Redis |
| `brsApiRoutes` | `voucherNextActionsHandler` | Routes `/voucher/v1/next_actions` requests | internal |
| `brsApiRoutes` | `reminderHandler` | Routes `remind_me_later` requests | internal |
| `brsApiRoutes` | `backfillHandler` | Routes `/backfill` and `/backfill/batch` requests | internal |
| `brsApiRoutes` | `messageContentHandler` | Routes `/message/v1/content` requests | internal |
| `voucherNextActionsHandler` | `workflowEngine` | Evaluates workflows and action schedules | internal |
| `voucherNextActionsHandler` | `storageFacade` | Loads voucher/order/user/deal context | internal |
| `reminderHandler` | `storageFacade` | Loads user and voucher data before scheduling | internal |
| `reminderHandler` | `serviceClientAdapters` | Schedules reminder via RISE client | internal |
| `backfillHandler` | `serviceClientAdapters` | Schedules backfill jobs via RISE client | internal |
| `workflowEngine` | `storageFacade` | Reads contextual entities and feature state | internal |
| `storageFacade` | `serviceClientAdapters` | Executes downstream service requests | internal |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumBreakageReductionService`
- Component: `components-continuum-breakage-reduction-service-components`
- Dynamic view: `dynamic-brs-reminder-scheduling-flow`
