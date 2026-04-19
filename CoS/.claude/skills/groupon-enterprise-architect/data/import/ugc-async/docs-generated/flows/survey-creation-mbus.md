---
service: "ugc-async"
title: "Survey Creation from MBus Event"
generated: "2026-03-03"
type: flow
flow_name: "survey-creation-mbus"
flow_type: event-driven
trigger: "MBus order, voucher redemption, or post-purchase event"
participants:
  - "mbusPlatform_9b1a"
  - "continuumUgcAsyncService"
  - "continuumDealCatalogService"
  - "continuumVoucherInventoryService"
  - "continuumGoodsInventoryService"
  - "continuumUsersService"
  - "continuumUgcPostgresDb"
  - "continuumUgcRedisCache"
architecture_ref: "dynamic-ugc-async-survey-creation"
---

# Survey Creation from MBus Event

## Summary

When a customer purchases or redeems a deal, an event is published to the internal MBus platform. ugc-async consumes these events via its enabled MBus consumer listeners (`localSurveyCreator`, `localSurveyCreatorV2`, `thirdPartySurveyCreator`, `goodsSurveyCreator`, `postPurchaseVISListener`) and creates survey records in the UGC PostgreSQL database for later dispatch. The flow applies an eligibility chain to prevent duplicate surveys, filter opted-out users, and validate that the deal and voucher data are in the expected state before persisting a survey.

## Trigger

- **Type**: event (MBus message)
- **Source**: Order processing, voucher inventory, or deal catalog services publish redemption/purchase events to the MBus platform
- **Frequency**: Per purchase/redemption event; event-driven, continuous

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MBus Platform | Event source — delivers purchase/redemption event to ugc-async consumer | `mbusPlatform_9b1a` |
| UGC Async Service — Message Bus Consumers | Receives and deserialises the MBus event payload | `continuumUgcAsyncService` |
| UGC Async Service — Survey Creation Processor | Orchestrates eligibility checks and survey creation | `continuumUgcAsyncService` |
| UGC Async Service — Eligibility Framework | Evaluates eligibility rules (survey exists, user opted out, deal exists, time-based checks) | `continuumUgcAsyncService` |
| Deal Catalog Service | Provides deal metadata (title, image URL, category) | `continuumDealCatalogService` |
| Voucher Inventory Service | Validates voucher state (redeemed status) | `continuumVoucherInventoryService` |
| Goods Inventory Service | Provides goods inventory data for Goods survey type | `continuumGoodsInventoryService` |
| Users Service | Provides user profile for survey personalisation | `continuumUsersService` |
| UGC Postgres | Persists new survey record | `continuumUgcPostgresDb` |
| Redis Cache | Checked for deduplication keys | `continuumUgcRedisCache` |

## Steps

1. **Receives purchase/redemption event**: MBus platform delivers a message to the enabled consumer listener (e.g., `localSurveyCreator`)
   - From: `mbusPlatform_9b1a`
   - To: `continuumUgcAsyncService` (Message Bus Consumers component)
   - Protocol: MBus

2. **Deserialises and validates event payload**: `SurveyCreationMessageProcessor` parses the message payload; `MessageValidator` checks required fields
   - From: Message Bus Consumers
   - To: Survey Creation Processor
   - Protocol: direct (in-process)

3. **Runs eligibility check chain**: `SurveyCreationEligibilityChecker` / `EligibilityCheckChain` evaluates checkers in sequence: `SurveyExistsChecker` (no duplicate), `UserOptedOutChecker`, `DealExistsChecker`, `RedeemedChecker`, `StatusEligibilityChecker`, `TimeBasedSurveyChecker`
   - From: Survey Creation Processor
   - To: Eligibility Framework
   - Protocol: direct (in-process)

4. **Fetches deal metadata**: Calls Deal Catalog Service to retrieve deal title, image URL, and category attributes required for the survey record
   - From: `continuumUgcAsyncService`
   - To: `continuumDealCatalogService`
   - Protocol: REST (Retrofit)

5. **Fetches voucher state**: Calls Voucher Inventory Service to confirm the voucher is in the expected redemption state
   - From: `continuumUgcAsyncService`
   - To: `continuumVoucherInventoryService`
   - Protocol: REST (Retrofit)

6. **Fetches user profile**: Calls Users Service to retrieve user locale and profile data for survey personalisation
   - From: `continuumUgcAsyncService`
   - To: `continuumUsersService`
   - Protocol: REST (Retrofit)

7. **Builds survey properties**: `SurveyPropertiesBuilder` assembles the survey model from the event payload and enriched deal/user data
   - From: Survey Creation Processor
   - To: UGC Repository
   - Protocol: direct (in-process)

8. **Persists survey record**: `SurveyCreator` calls `SurveyService` / JDBI DAO to insert the new survey into `continuumUgcPostgresDb`
   - From: `continuumUgcAsyncService`
   - To: `continuumUgcPostgresDb`
   - Protocol: JDBI / SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Eligibility check fails (duplicate, opted-out, invalid state) | Eligibility framework rejects; survey not created | Event acknowledged; no survey persisted |
| Deal Catalog Service unavailable | Exception caught; error logged to Steno | Survey creation skipped; event processed without survey |
| Postgres write failure | Exception propagates; message may be re-delivered by MBus | Potential duplicate if MBus re-delivers; `SurveyExistsChecker` guards against duplicates on re-delivery |
| Invalid event payload | `MessageValidator` / `ValidationException` thrown | Event dropped; error logged |

## Sequence Diagram

```
MBus Platform -> UGC Async (Consumers): Deliver purchase/redemption event
UGC Async (Consumers) -> Survey Creation Processor: Dispatch to handler
Survey Creation Processor -> Eligibility Framework: Run eligibility check chain
Eligibility Framework -> UGC Postgres: Query existing surveys (SurveyExistsChecker)
Eligibility Framework --> Survey Creation Processor: Eligibility result
Survey Creation Processor -> Deal Catalog Service: Fetch deal metadata (REST)
Deal Catalog Service --> Survey Creation Processor: Deal title, image, category
Survey Creation Processor -> Voucher Inventory Service: Validate voucher state (REST)
Voucher Inventory Service --> Survey Creation Processor: Voucher status
Survey Creation Processor -> Users Service: Fetch user profile (REST)
Users Service --> Survey Creation Processor: User locale/profile
Survey Creation Processor -> UGC Postgres: INSERT survey record (JDBI)
UGC Postgres --> Survey Creation Processor: Survey ID
```

## Related

- Architecture dynamic view: `dynamic-ugc-async-survey-creation`
- Related flows: [Survey Sending — Notification Dispatch](survey-sending-notification.md), [Goods Survey Creation from Teradata](goods-survey-creation-teradata.md)
