---
service: "goods-promotion-manager"
title: "Promotion Lifecycle"
generated: "2026-03-03"
type: flow
flow_name: "promotion-lifecycle"
flow_type: synchronous
trigger: "Internal user action via REST API"
participants:
  - "continuumGoodsPromotionManagerService"
  - "continuumGoodsPromotionManagerDb"
architecture_ref: "dynamic-goods-promotion-manager"
---

# Promotion Lifecycle

## Summary

A promotion moves through four distinct states: `CREATED`, `LOCKED`, `SUBMITTED`, and `DONE`. Internal merchandise and pricing team members interact with the REST API to create a promotion, associate metrics and countries, adjust it, lock it for review, submit it for execution, and ultimately mark it done. The service enforces strict state transition rules at every write operation.

## Trigger

- **Type**: user-action (API call)
- **Source**: Internal Groupon merchandise or pricing team member calling the REST API (e.g., via a front-end tool or Postman)
- **Frequency**: On-demand; a promotion is created once and progresses through states over its operational lifespan

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Internal User | Initiates promotion lifecycle actions | — |
| Goods Promotion Manager Service | Validates input, enforces state machine, persists changes | `continuumGoodsPromotionManagerService` |
| Promotion Handler | Orchestrates validation and DAO calls | `continuumGoodsPromotionManagerService` |
| Promotion DAO Manager | Executes multi-table database operations | `continuumGoodsPromotionManagerService` |
| Goods Promotion Manager DB | Persists promotion state | `continuumGoodsPromotionManagerDb` |

## Steps

1. **Create Promotion**: Internal user sends `POST /v1/promotions` with a `PromotionDetail` body including name, start/end/due times, associated metrics, and target countries.
   - From: Internal User
   - To: `continuumGoodsPromotionManagerService` (`Promotion Resource`)
   - Protocol: HTTPS/REST

2. **Validate and Persist**: Promotion Handler validates required fields, string lengths, timestamp ordering (end > start > now), metric IDs, and country IDs. Asserts promotion name uniqueness. Assigns a new UUID and calls `PromotionDaoManager.insertPromotionWithMetricCountryInfo()`.
   - From: `promotionResource` / `promotionHandler`
   - To: `continuumGoodsPromotionManagerDb`
   - Protocol: JDBC

3. **Return Created Promotion**: Service returns the persisted `PromotionDetail` (including the assigned UUID) with HTTP 200.
   - From: `continuumGoodsPromotionManagerService`
   - To: Internal User
   - Protocol: HTTPS/REST

4. **Lock Promotion**: User sends `PUT /v1/promotions/{promotionUuid}` with `status: LOCKED`. Valid only when current status is `CREATED`.
   - From: Internal User
   - To: `continuumGoodsPromotionManagerService`
   - Protocol: HTTPS/REST

5. **Validate Lock Transition**: Promotion Handler fetches the existing promotion, asserts the current status is `CREATED` or `LOCKED`, then updates the record.
   - From: `promotionHandler`
   - To: `continuumGoodsPromotionManagerDb`
   - Protocol: JDBC

6. **Submit Promotion**: User sends `PUT /v1/promotions/{promotionUuid}` with `status: SUBMITTED`. Valid only when current status is `LOCKED`.
   - From: Internal User
   - To: `continuumGoodsPromotionManagerService`
   - Protocol: HTTPS/REST

7. **Enforce Submission Rules**: Promotion Handler asserts the current status is `LOCKED` before allowing transition to `SUBMITTED`. Once `SUBMITTED`, no further updates are permitted.
   - From: `promotionHandler`
   - To: `continuumGoodsPromotionManagerDb`
   - Protocol: JDBC

8. **Retrieve Promotions**: At any point, users may call `GET /v1/promotions` (with optional `promotionStatus` and `isActive` filters) or `GET /v1/promotions/{promotionUuid}` to inspect state.
   - From: Internal User
   - To: `continuumGoodsPromotionManagerService`
   - Protocol: HTTPS/REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Required field missing or blank | `ValidationException` thrown in `PromotionDetail.validatePromotionCreationComponents()` | HTTP 400 with error message |
| Promotion name already exists (different UUID) | `assertPromotionNameUnique()` throws `ValidationException` | HTTP 400 with duplicate name error |
| Metric ID does not exist in DB | `assertMetricIdExist()` throws `ValidationException` | HTTP 400 with invalid metric ID error |
| Country ID does not exist in DB | `assertCountryIdExist()` throws `ValidationException` | HTTP 400 with invalid country ID error |
| Invalid status transition (e.g., submitting a `CREATED` promotion) | `assertPromotionStatus()` throws `ValidationException` | HTTP 400 with transition error message |
| Attempting to update a `SUBMITTED` promotion | `assertPromotionStatus()` throws `ValidationException` | HTTP 400: "Updates are not allowed on submitted promotions" |
| Promotion UUID not found | Handler returns null / throws `ValidationException` | HTTP 404 |

## Sequence Diagram

```
InternalUser -> PromotionResource: POST /v1/promotions (PromotionDetail)
PromotionResource -> PromotionHandler: insertPromotionDetail(promotionDetail, userId)
PromotionHandler -> PromotionHandler: validateFields(), assertNameUnique(), assertMetricIds(), assertCountryIds()
PromotionHandler -> PromotionDaoManager: insertPromotionWithMetricCountryInfo(promotionDetail)
PromotionDaoManager -> GoodsPromotionManagerDB: INSERT INTO promotion, promotion_metric, promotion_country
GoodsPromotionManagerDB --> PromotionDaoManager: persisted PromotionDetail
PromotionDaoManager --> PromotionHandler: PromotionDetail (with UUID)
PromotionHandler --> PromotionResource: PromotionDetail
PromotionResource --> InternalUser: HTTP 200 PromotionDetail

InternalUser -> PromotionResource: PUT /v1/promotions/{uuid} (status=LOCKED)
PromotionResource -> PromotionHandler: updatePromotionDetail(promotionDetail, userId)
PromotionHandler -> GoodsPromotionManagerDB: SELECT existing promotion
PromotionHandler -> PromotionHandler: assertPromotionStatus(LOCKED, existingStatus)
PromotionHandler -> PromotionDaoManager: updatePromotionWithMetricCountryInfo(promotionDetail)
PromotionDaoManager -> GoodsPromotionManagerDB: UPDATE promotion SET status='LOCKED'
GoodsPromotionManagerDB --> PromotionDaoManager: updated PromotionDetail
PromotionDaoManager --> PromotionHandler: PromotionDetail
PromotionHandler --> PromotionResource: PromotionDetail
PromotionResource --> InternalUser: HTTP 200 PromotionDetail
```

## Related

- Architecture dynamic view: `dynamic-goods-promotion-manager`
- Related flows: [Promotion Deal Management](promotion-deal-management.md), [Promotion CSV Export](promotion-csv-export.md)
