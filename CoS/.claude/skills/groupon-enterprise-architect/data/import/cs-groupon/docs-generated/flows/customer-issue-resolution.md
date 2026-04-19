---
service: "cs-groupon"
title: "Customer Issue Resolution"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "customer-issue-resolution"
flow_type: synchronous
trigger: "CS agent initiates a customer lookup or issue action in the Web App"
participants:
  - "continuumCsWebApp"
  - "continuumCsAppDb"
  - "continuumCsRedisCache"
  - "continuumOrdersService"
  - "continuumUsersService"
  - "continuumDealCatalogService"
  - "continuumInventoryService"
  - "continuumPricingService"
  - "continuumVoucherInventoryService"
  - "continuumEmailService"
  - "continuumRegulatoryConsentLogApi"
architecture_ref: "dynamic-cs-groupon"
---

# Customer Issue Resolution

## Summary

A CS agent uses the cyclops Web App to look up a customer's order or account, diagnose the reported issue, and apply a resolution such as a refund, voucher reissue, or email notification. The flow aggregates data from multiple downstream Continuum platform services to give the agent a unified view, then routes the chosen resolution action to the appropriate service.

## Trigger

- **Type**: user-action
- **Source**: CS agent navigates to an order or user record in `continuumCsWebApp`
- **Frequency**: On demand (per agent action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CS Web App | Entry point; renders UI, orchestrates downstream calls | `continuumCsWebApp` |
| CS App Database | Stores CS issue records and agent notes | `continuumCsAppDb` |
| CS Redis Cache | Session validation on each request | `continuumCsRedisCache` |
| Orders Service | Supplies order history and refund eligibility | `continuumOrdersService` |
| Users Service | Supplies user profile and account status | `continuumUsersService` |
| Deal Catalog Service | Supplies deal metadata for the order | `continuumDealCatalogService` |
| Inventory Service | Confirms inventory status for the affected item | `continuumInventoryService` |
| Pricing Service | Calculates refund amount or price adjustment | `continuumPricingService` |
| Voucher Inventory Service | Issues, cancels, or resends vouchers | `continuumVoucherInventoryService` |
| Email Service | Sends resolution notification to customer | `continuumEmailService` |
| Regulatory Consent Log API | Logs CS agent consent action for compliance | `continuumRegulatoryConsentLogApi` |

## Steps

1. **Agent authenticates**: CS agent submits login credentials.
   - From: `agent browser`
   - To: `continuumCsWebApp`
   - Protocol: HTTP / session (Warden)

2. **Session validation**: Web App validates session token on each request.
   - From: `continuumCsWebApp`
   - To: `continuumCsRedisCache`
   - Protocol: Redis

3. **Agent searches for customer or order**: Agent submits a search query or navigates directly to an order/user record.
   - From: `continuumCsWebApp`
   - To: `continuumCsAppDb` (local CS records) and Elasticsearch (fuzzy search)
   - Protocol: ActiveRecord / Elasticsearch HTTP

4. **Fetch order details**: Web App requests full order data from Orders Service.
   - From: `continuumCsWebApp`
   - To: `continuumOrdersService` (via `apiProxy`)
   - Protocol: REST

5. **Fetch user profile**: Web App requests user account data from Users Service.
   - From: `continuumCsWebApp`
   - To: `continuumUsersService` (via `apiProxy`)
   - Protocol: REST

6. **Load deal metadata**: Web App loads deal information associated with the order.
   - From: `continuumCsWebApp`
   - To: `continuumDealCatalogService` (via `apiProxy`)
   - Protocol: REST

7. **Check inventory status**: Web App verifies inventory availability for the affected item.
   - From: `continuumCsWebApp`
   - To: `continuumInventoryService` (via `apiProxy`)
   - Protocol: REST

8. **Agent selects resolution action**: Agent chooses refund, voucher operation, or email notification.
   - From: `agent browser`
   - To: `continuumCsWebApp`
   - Protocol: HTTP POST

9. **Calculate pricing** (refund path): Web App requests refund amount calculation.
   - From: `continuumCsWebApp`
   - To: `continuumPricingService` (via `apiProxy`)
   - Protocol: REST

10. **Execute resolution** (voucher path): Web App issues, cancels, or resends voucher.
    - From: `continuumCsWebApp`
    - To: `continuumVoucherInventoryService` (via `apiProxy`)
    - Protocol: REST

11. **Send email notification**: Web App dispatches customer resolution notification.
    - From: `continuumCsWebApp`
    - To: `continuumEmailService` (via `apiProxy`)
    - Protocol: REST

12. **Log consent action**: Web App records the CS agent's resolution action for compliance.
    - From: `continuumCsWebApp`
    - To: `continuumRegulatoryConsentLogApi` (via `apiProxy`)
    - Protocol: REST

13. **Write CS issue record**: Web App saves the resolution outcome and agent notes.
    - From: `continuumCsWebApp`
    - To: `continuumCsAppDb`
    - Protocol: ActiveRecord / MySQL

14. **Render confirmation**: Web App returns updated UI to agent confirming resolution.
    - From: `continuumCsWebApp`
    - To: `agent browser`
    - Protocol: HTTP / HTML (server-rendered)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Orders Service unavailable | HTTP error surfaced by Typhoeus | Agent sees error message; order data not displayed |
| Pricing Service returns error | Resolution blocked; error shown to agent | Agent must retry or escalate |
| Voucher operation fails | Error returned from `continuumVoucherInventoryService` | Agent sees failure; voucher state unchanged |
| Email Service unavailable | Error logged; agent informed | Customer not notified; manual follow-up needed |
| Redis session expired | Warden redirects agent to login | Agent must re-authenticate |

## Sequence Diagram

```
Agent -> continuumCsWebApp: Submit search or navigate to record
continuumCsWebApp -> continuumCsRedisCache: Validate session
continuumCsWebApp -> continuumOrdersService: GET order details
continuumCsWebApp -> continuumUsersService: GET user profile
continuumCsWebApp -> continuumDealCatalogService: GET deal metadata
continuumCsWebApp -> continuumInventoryService: GET inventory status
Agent -> continuumCsWebApp: Select resolution action
continuumCsWebApp -> continuumPricingService: Calculate refund amount (refund path)
continuumCsWebApp -> continuumVoucherInventoryService: Voucher operation (voucher path)
continuumCsWebApp -> continuumEmailService: Send customer notification
continuumCsWebApp -> continuumRegulatoryConsentLogApi: Log consent action
continuumCsWebApp -> continuumCsAppDb: Write CS issue record
continuumCsWebApp --> Agent: Render resolution confirmation
```

## Related

- Architecture dynamic view: `dynamic-cs-groupon`
- Related flows: [Web UI Session Management](web-ui-session-management.md), [Search and Filter Workflow](search-and-filter-workflow.md)
