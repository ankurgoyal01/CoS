---
service: "goods-promotion-manager"
title: "Deal Eligibility Check"
generated: "2026-03-03"
type: flow
flow_name: "deal-eligibility-check"
flow_type: synchronous
trigger: "API call — internal user evaluates deal eligibility before adding deals to a promotion"
participants:
  - "continuumGoodsPromotionManagerService"
  - "continuumGoodsPromotionManagerDb"
architecture_ref: "dynamic-goods-promotion-manager"
---

# Deal Eligibility Check

## Summary

Before deals are added to a promotion, merchandise team members call the eligibility endpoint to determine whether each deal (identified by permalink) meets the criteria for inclusion. The service evaluates two categories of flags: an **eligibility** check (the deal has been live long enough and meets 28-day registration requirements) and a **pre-qualification** check (the deal meets quality signals including star rating, competitive pricing, inventory levels, GP margin, and metal tier). When enabled, additional ILS business rules (the 50% Rule and the Resting Rule) are applied by querying the ILS deal selection log history and existing promotion schedules.

## Trigger

- **Type**: user-action (API call)
- **Source**: Internal user submits deal permalinks and promotion UUIDs to `POST /v1/deal_promotion_eligibilities`
- **Frequency**: On-demand, before adding deals to a promotion

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Internal User | Initiates eligibility check with deal permalinks and promotion UUIDs | — |
| Deal Promotion Eligibility Resource | Receives request and delegates to handler | `continuumGoodsPromotionManagerService` |
| Deal Promotion Eligibility Handler | Orchestrates eligibility evaluation logic | `continuumGoodsPromotionManagerService` |
| Deal DAO | Looks up deals by permalink | `continuumGoodsPromotionManagerService` |
| Deal Promotion Eligibility DAO | Retrieves stored eligibility flags for each deal | `continuumGoodsPromotionManagerService` |
| ILS Deal Selection Log Raw DAO | Queries historical ILS promotion data for 50% Rule and Resting Rule | `continuumGoodsPromotionManagerService` |
| Promotion DAO Manager | Retrieves promotion details and inventory product promotion history | `continuumGoodsPromotionManagerService` |
| Goods Promotion Manager DB | Source of all eligibility and deal data | `continuumGoodsPromotionManagerDb` |

## Steps

1. **Receive Eligibility Request**: User sends `POST /v1/deal_promotion_eligibilities` with a body containing a set of `promotionUuids` and a set of `permalinks`.
   - From: Internal User
   - To: `continuumGoodsPromotionManagerService` (`Deal Promotion Eligibility Resource`)
   - Protocol: HTTPS/REST

2. **Retrieve Deals by Permalink**: Handler calls `DealDao.getDealByPermalinkSet()` to resolve permalinks to Deal objects. Any permalinks not found are collected in `failedPermalinks`.
   - From: `dealPromotionEligibilityHandler`
   - To: `continuumGoodsPromotionManagerDb`
   - Protocol: JDBC

3. **Retrieve Promotion by UUID**: For each `promotionUuid`, handler calls `PromotionDaoManager.getPromotionByUuid()`. Throws `ValidationException` if any promotion UUID does not exist.
   - From: `dealPromotionEligibilityHandler`
   - To: `continuumGoodsPromotionManagerDb`
   - Protocol: JDBC

4. **Fetch Deal Promotion Eligibility Record**: For each deal, handler calls `DealPromotionEligibilityDao.getDealPromotionEligibilityByDealUuid()` to retrieve the stored eligibility flags.
   - From: `dealPromotionEligibilityHandler`
   - To: `continuumGoodsPromotionManagerDb`
   - Protocol: JDBC

5. **Evaluate Eligibility Flags**: Handler calls `checkEligible()` which evaluates:
   - `less_28_reg_days_flag` must be true
   - `new_deal_days` must be > 14, or the promotion start must be > 14 days in the future relative to the deal's age (exemption applies during Black Friday period)
   - From: `dealPromotionEligibilityHandler` (in-memory)
   - To: — (pure computation)
   - Protocol: direct

6. **Evaluate Pre-Qualification Flags**: Handler calls `checkPreQual()` which evaluates nine quality signals: `star_rating`, `last_ils_day`, `competitive_pricing`, `prior_ils_performance`, `negative_gp_flag`, `inventory_flag`, `constraints_flag`, `metal_tier_rating`, `no_ils_hist_deal_perf`. Each flag with value `-1` maps to false.
   - From: `dealPromotionEligibilityHandler` (in-memory)
   - To: — (pure computation)
   - Protocol: direct

7. **Apply ILS 50% Rule (if enabled)**: If `ils50PercentRuleFlagEnabled=true` and the promotion is not in the Black Friday exemption period, handler computes 90-day past and future windows around the promotion dates, queries `ils_deal_selection_log_raw` and promotion inventory product history, and checks that no inventory product has been on promotion for more than the `MAX_ILS_DAYS_THRESHOLD` within the window.
   - From: `dealPromotionEligibilityHandler`
   - To: `continuumGoodsPromotionManagerDb` (`ILSDealSelectionLogRawDao`, `PromotionDao`)
   - Protocol: JDBC

8. **Apply ILS Resting Rule (if enabled)**: If `ilsRestingRuleFlagEnabled=true` and not in Black Friday exemption period, handler computes 2-day windows and checks that no inventory product was on promotion within the resting window.
   - From: `dealPromotionEligibilityHandler`
   - To: `continuumGoodsPromotionManagerDb`
   - Protocol: JDBC

9. **Return Eligibility Results**: Handler returns a `DealPromotionEligibilityResponseWrapper` containing a list of `DealPromotionEligibilityPresenter` (one per deal×promotion combination, with `isEligible`, `isPreQual`, and `reason` list) plus `failedPermalinks`.
   - From: `continuumGoodsPromotionManagerService`
   - To: Internal User
   - Protocol: HTTPS/REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `promotionUuids` is null | `ValidationException` thrown immediately | HTTP 400 |
| `permalinks` is null | `ValidationException` thrown immediately | HTTP 400 |
| Promotion UUID not found in DB | `ValidationException` thrown | HTTP 400 with "promotion does not exist" message |
| Deal permalink not found in DB | Permalink added to `failedPermalinks` set; processing continues for remaining deals | HTTP 200; caller receives partial results with `failedPermalinks` |
| `DealPromotionEligibility` record not found for a deal | `IllegalArgumentException` caught; deal's permalink added to `failedPermalinks` | HTTP 200; partial results |
| ILS Rule evaluation encounters an exception | Logged; eligibility result may be partial | HTTP 200 with available flags |

## Sequence Diagram

```
InternalUser -> DealPromotionEligibilityResource: POST /v1/deal_promotion_eligibilities {promotionUuids, permalinks}
DealPromotionEligibilityResource -> DealPromotionEligibilityHandler: getDealPromotionEligibilities(promotionUuids, permalinks)
DealPromotionEligibilityHandler -> DealDao: getDealByPermalinkSet(permalinks)
DealDao -> GoodsPromotionManagerDB: SELECT * FROM deal WHERE deal_permalink IN (...)
GoodsPromotionManagerDB --> DealDao: List<Deal>
DealDao --> DealPromotionEligibilityHandler: List<Deal>, failedPermalinks
DealPromotionEligibilityHandler -> PromotionDaoManager: getPromotionByUuid(promotionUuid)
PromotionDaoManager -> GoodsPromotionManagerDB: SELECT * FROM promotion WHERE uuid = ?
GoodsPromotionManagerDB --> PromotionDaoManager: Promotion
DealPromotionEligibilityHandler -> DealPromotionEligibilityDao: getDealPromotionEligibilityByDealUuid(dealUuid)
DealPromotionEligibilityDao -> GoodsPromotionManagerDB: SELECT * FROM deal_promotion_eligibility WHERE deal_uuid = ?
GoodsPromotionManagerDB --> DealPromotionEligibilityHandler: DealPromotionEligibility
DealPromotionEligibilityHandler -> DealPromotionEligibilityHandler: checkEligible(), checkPreQual()
DealPromotionEligibilityHandler -> ILSDealSelectionLogRawDao: getInventoryProductUUIDDaysOnPromotion(...) [if flags enabled]
ILSDealSelectionLogRawDao -> GoodsPromotionManagerDB: SELECT ... FROM ils_deal_selection_log_raw
GoodsPromotionManagerDB --> DealPromotionEligibilityHandler: List<IPIDSum>
DealPromotionEligibilityHandler -> DealPromotionEligibilityHandler: check50pRule(), checkRestingRule()
DealPromotionEligibilityHandler --> DealPromotionEligibilityResource: DealPromotionEligibilityResponseWrapper
DealPromotionEligibilityResource --> InternalUser: HTTP 200 {dealPromotionEligibilities, failedPermalinks}
```

## Related

- Architecture dynamic view: `dynamic-goods-promotion-manager`
- Related flows: [Promotion Lifecycle](promotion-lifecycle.md), [Promotion Deal Management](promotion-deal-management.md)
