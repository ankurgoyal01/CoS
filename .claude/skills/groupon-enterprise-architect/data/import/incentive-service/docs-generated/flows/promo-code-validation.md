---
service: "incentive-service"
title: "Promo Code Validation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "promo-code-validation"
flow_type: synchronous
trigger: "API call — GET /incentives/validate"
participants:
  - "continuumIncentiveService"
  - "incentiveApi"
  - "incentiveDataAccess"
  - "incentiveExternalClients"
  - "continuumIncentivePostgres"
  - "continuumIncentiveCassandra"
  - "continuumIncentiveRedis"
  - "continuumPricingService"
  - "continuumDealCatalogService"
architecture_ref: "dynamic-incentive-request-flow"
---

# Promo Code Validation

## Summary

The promo code validation flow allows checkout systems to verify whether a promo code is applicable for a given user and deal context before completing a purchase. The `incentiveApi` component resolves the incentive definition, checks prior redemption history, and evaluates eligibility rules against live pricing context, returning a structured valid/invalid response with discount details. This flow is only active when `SERVICE_MODE=checkout`.

## Trigger

- **Type**: api-call
- **Source**: Checkout system or consumer-facing application
- **Frequency**: Per checkout request where a promo code is present

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Checkout System | Initiates validation request with promo code, user ID, and deal context | — |
| Incentive Service (API) | Orchestrates validation logic across data and external dependencies | `incentiveApi` |
| Incentive Data Access | Reads incentive definitions from PostgreSQL and Redis; checks Cassandra for prior redemptions | `incentiveDataAccess` |
| Incentive External Clients | Calls Pricing Service for eligibility context and Deal Catalog for deal details | `incentiveExternalClients` |
| Incentive PostgreSQL | Holds authoritative incentive definition and quota counter | `continuumIncentivePostgres` |
| Incentive Cassandra / Keyspaces | Holds prior redemption records keyed by user and incentive | `continuumIncentiveCassandra` |
| Incentive Redis | Caches incentive definitions to reduce PostgreSQL read load | `continuumIncentiveRedis` |
| Pricing Service | Provides pricing context for eligibility evaluation | `continuumPricingService` |
| Deal Catalog Service | Provides deal/product details for scope resolution | `continuumDealCatalogService` |

## Steps

1. **Receive validation request**: Checkout system calls `GET /incentives/validate` with promo code, user ID, and deal context parameters.
   - From: Checkout System
   - To: `incentiveApi`
   - Protocol: REST/HTTP

2. **Resolve incentive definition**: `incentiveDataAccess` checks Redis cache for the incentive definition; on cache miss, queries PostgreSQL.
   - From: `incentiveApi`
   - To: `continuumIncentiveRedis` then `continuumIncentivePostgres` (on miss)
   - Protocol: Redis, then JDBC/PostgreSQL

3. **Check prior redemption records**: `incentiveDataAccess` queries Cassandra (or Keyspaces in cloud) for any prior redemption by the same user for this incentive.
   - From: `incentiveApi`
   - To: `continuumIncentiveCassandra`
   - Protocol: Cassandra CQL

4. **Fetch deal details**: `incentiveExternalClients` retrieves deal/product details for scope validation.
   - From: `incentiveApi`
   - To: `continuumDealCatalogService`
   - Protocol: REST/HTTP

5. **Request pricing context**: `incentiveExternalClients` calls Pricing Service to retrieve current pricing data for the deal, used in eligibility calculations.
   - From: `incentiveApi`
   - To: `continuumPricingService`
   - Protocol: REST/HTTP

6. **Run qualification logic**: `incentiveApi` evaluates whether the user and deal combination satisfies the incentive's eligibility rules, using the resolved definition, prior redemption status, deal details, and pricing context.
   - From: `incentiveApi`
   - To: internal (no external call)
   - Protocol: in-process

7. **Return validation result**: `incentiveApi` returns a structured JSON response containing `valid: true/false`, the applicable discount amount and type, and any rejection reason if invalid.
   - From: `incentiveApi`
   - To: Checkout System
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Incentive not found in PostgreSQL | Return `valid: false` with rejection reason `INCENTIVE_NOT_FOUND` | Checkout flow proceeds without discount |
| Prior redemption found in Cassandra | Return `valid: false` with rejection reason `ALREADY_REDEEMED` | Checkout flow proceeds without discount |
| Pricing Service unavailable | Return error response; validation cannot complete without pricing context | Checkout system handles degradation |
| Deal Catalog Service unavailable | Return error response; validation cannot resolve deal scope | Checkout system handles degradation |
| Redis cache failure | Fall through to PostgreSQL directly; no impact on correctness | Increased PostgreSQL load |
| Cassandra read timeout | Retry up to configured attempts; return error if exhausted | Checkout system handles degradation |

## Sequence Diagram

```
CheckoutSystem -> incentiveApi: GET /incentives/validate?code=X&userId=Y&dealId=Z
incentiveApi -> continuumIncentiveRedis: GET incentive:X
continuumIncentiveRedis --> incentiveApi: (cache miss)
incentiveApi -> continuumIncentivePostgres: SELECT * FROM incentives WHERE code = X
continuumIncentivePostgres --> incentiveApi: incentive definition
incentiveApi -> continuumIncentiveCassandra: SELECT * FROM redemptions WHERE user_id = Y AND incentive_id = X
continuumIncentiveCassandra --> incentiveApi: (no prior redemption)
incentiveApi -> continuumDealCatalogService: GET /deals/Z
continuumDealCatalogService --> incentiveApi: deal details
incentiveApi -> continuumPricingService: GET /pricing?dealId=Z&userId=Y
continuumPricingService --> incentiveApi: pricing context
incentiveApi -> incentiveApi: run qualification logic
incentiveApi --> CheckoutSystem: { valid: true, discount: { type: "percent", value: 20 } }
```

## Related

- Architecture dynamic view: `dynamic-incentive-request-flow`
- Related flows: [Incentive Redemption](incentive-redemption.md)
