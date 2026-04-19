---
service: "goods-promotion-manager"
title: "Promotion Deal Management"
generated: "2026-03-03"
type: flow
flow_name: "promotion-deal-management"
flow_type: synchronous
trigger: "API call — internal user creates, updates, or removes deal associations on a promotion"
participants:
  - "continuumGoodsPromotionManagerService"
  - "continuumGoodsPromotionManagerDb"
architecture_ref: "dynamic-goods-promotion-manager"
---

# Promotion Deal Management

## Summary

Once a promotion is created, internal users associate specific deals with it by creating `promotion_deal` records. Each promotion deal links a promotion UUID with a deal UUID and carries deal-level metric data (division, category, subcategory, channel, coop type, coop value, pricing). Users can also update existing promotion deal records or delete associations. Promotion ineligibilities — records that capture why a deal was excluded from a promotion — are managed through a separate but related endpoint.

## Trigger

- **Type**: user-action (API call)
- **Source**: Internal Groupon merchandise or pricing team member
- **Frequency**: On-demand during promotion configuration

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Internal User | Submits deal association create/update/delete requests | — |
| Promotion Deal Resource | Receives and routes deal management requests | `continuumGoodsPromotionManagerService` |
| Promotion Deal Handler | Validates and orchestrates deal association operations | `continuumGoodsPromotionManagerService` |
| Promotion Ineligibility Resource | Receives ineligibility create/update requests | `continuumGoodsPromotionManagerService` |
| Promotion Ineligibility Handler | Validates and persists ineligibility records | `continuumGoodsPromotionManagerService` |
| Promotion Deal DAO | Persists promotion deal records | `continuumGoodsPromotionManagerService` |
| Promotion Ineligibility DAO | Persists promotion ineligibility records | `continuumGoodsPromotionManagerService` |
| Goods Promotion Manager DB | Stores promotion deal and ineligibility data | `continuumGoodsPromotionManagerDb` |

## Steps

### Create Promotion Deals

1. **Submit Create Request**: User sends `POST /v1/promotion_deals` with a `PromotionDealRequestWrapper` body containing the promotion UUID and a list of deals with their metric data. The `x-remote-user` header identifies the requesting user.
   - From: Internal User
   - To: `continuumGoodsPromotionManagerService` (`Promotion Deal Resource`)
   - Protocol: HTTPS/REST

2. **Validate and Insert**: Promotion Deal Handler validates that the referenced promotion exists and that the input data is valid. Inserts new `promotion_deal` records via `PromotionDealDao`.
   - From: `promotionDealHandler`
   - To: `continuumGoodsPromotionManagerDb`
   - Protocol: JDBC

3. **Return Operation Results**: Service returns a list of `PromotionDealOperationResponseWrapper` items describing any operations that failed, along with the reason. A successful create returns an empty failure list (HTTP 200).
   - From: `continuumGoodsPromotionManagerService`
   - To: Internal User
   - Protocol: HTTPS/REST

### Update Promotion Deals

1. **Submit Update Request**: User sends `PUT /v1/promotion_deals` with the same `PromotionDealRequestWrapper` body structure.
   - From: Internal User
   - To: `continuumGoodsPromotionManagerService`
   - Protocol: HTTPS/REST

2. **Validate and Update**: Handler validates the request and updates existing `promotion_deal` records.
   - From: `promotionDealHandler`
   - To: `continuumGoodsPromotionManagerDb`
   - Protocol: JDBC

3. **Return Results**: Service returns failed operations list (HTTP 200).
   - From: `continuumGoodsPromotionManagerService`
   - To: Internal User
   - Protocol: HTTPS/REST

### Delete Promotion Deals

1. **Submit Delete Request**: User sends `POST /v1/promotion_deals/delete` with a `PromotionDealRequestWrapper` identifying which deals to remove from the promotion.
   - From: Internal User
   - To: `continuumGoodsPromotionManagerService`
   - Protocol: HTTPS/REST

2. **Validate and Delete**: Handler validates and removes the specified `promotion_deal` records.
   - From: `promotionDealHandler`
   - To: `continuumGoodsPromotionManagerDb`
   - Protocol: JDBC

3. **Return Results**: Service returns failed operations list (HTTP 200).
   - From: `continuumGoodsPromotionManagerService`
   - To: Internal User
   - Protocol: HTTPS/REST

### Record Promotion Ineligibilities

1. **Submit Ineligibility Update**: User sends `PUT /v1/promotion_ineligibilities` with a `PromotionIneligibilityRequestWrapper` containing deals and their ineligibility reasons.
   - From: Internal User
   - To: `continuumGoodsPromotionManagerService` (`Promotion Ineligibility Resource`)
   - Protocol: HTTPS/REST

2. **Upsert Ineligibility Records**: Handler validates and upserts `promotion_ineligibility` records. Failed operations are returned in the response.
   - From: `promotionIneligibilityHandler`
   - To: `continuumGoodsPromotionManagerDb`
   - Protocol: JDBC

3. **Return Results**: Service returns failed operations list (HTTP 200).
   - From: `continuumGoodsPromotionManagerService`
   - To: Internal User
   - Protocol: HTTPS/REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Referenced promotion does not exist | Handler validation throws `ValidationException` | HTTP 400 |
| Promotion is in `SUBMITTED` status | Handler rejects write; updates not allowed on submitted promotions | HTTP 400 |
| Individual deal operation fails (validation or DB error) | Operation recorded in failure list; other operations continue | HTTP 200 with non-empty failure list |
| Internal DB error | `UnableToExecuteStatementException` caught, re-thrown as `ValidationException` | HTTP 400 or HTTP 500 |

## Sequence Diagram

```
InternalUser -> PromotionDealResource: POST /v1/promotion_deals (PromotionDealRequestWrapper)
PromotionDealResource -> PromotionDealHandler: createPromotionDeals(request, userId)
PromotionDealHandler -> GoodsPromotionManagerDB: SELECT promotion WHERE uuid = promotionUuid
GoodsPromotionManagerDB --> PromotionDealHandler: Promotion (validates existence)
PromotionDealHandler -> PromotionDealDao: insertPromotionDeals(deals)
PromotionDealDao -> GoodsPromotionManagerDB: INSERT INTO promotion_deal (...)
GoodsPromotionManagerDB --> PromotionDealDao: inserted rows
PromotionDealDao --> PromotionDealHandler: results
PromotionDealHandler --> PromotionDealResource: List<PromotionDealOperationResponseWrapper> (failures)
PromotionDealResource --> InternalUser: HTTP 200 failure list (empty = all succeeded)
```

## Related

- Architecture dynamic view: `dynamic-goods-promotion-manager`
- Related flows: [Promotion Lifecycle](promotion-lifecycle.md), [Deal Eligibility Check](deal-eligibility-check.md), [Promotion CSV Export](promotion-csv-export.md)
