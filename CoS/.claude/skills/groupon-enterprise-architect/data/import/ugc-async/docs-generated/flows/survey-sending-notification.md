---
service: "ugc-async"
title: "Survey Sending — Notification Dispatch"
generated: "2026-03-03"
type: flow
flow_name: "survey-sending-notification"
flow_type: scheduled
trigger: "Quartz scheduler fires SurveySendingJob / LocalSurveySendingJob / GoodsSurveySendingJob / PostPurchaseSurveySendingJob"
participants:
  - "continuumUgcAsyncService"
  - "continuumUgcPostgresDb"
  - "continuumUsersService"
  - "continuumDealCatalogService"
  - "globalSubscriptionService_0b7f"
  - "rocketmanTransactionalService_1c55"
  - "rocketmanCommercialService_2d66"
  - "crmMessageService_7a44"
architecture_ref: "dynamic-ugc-async-survey-sending"
---

# Survey Sending — Notification Dispatch

## Summary

On a Quartz-scheduled interval, ugc-async fetches surveys in a sendable state from PostgreSQL and dispatches survey notification requests to users via email, push, and inbox channels. A multi-layer eligibility check ensures notifications are only sent to eligible users, for active deals, and only when sufficient time has passed since the survey was created. Each survey is processed in a 10-thread executor pool; dispatch outcomes are persisted as dispatch records in PostgreSQL.

## Trigger

- **Type**: schedule (Quartz job)
- **Source**: Quartz Job Scheduler component within `continuumUgcAsyncService` — fires `LocalSurveySendingJob`, `GoodsSurveySendingJob`, and `PostPurchaseSurveySendingJob` on configured cron intervals
- **Frequency**: Periodic (interval configured in application YAML Quartz configuration)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| UGC Async Service — Quartz Scheduler | Fires the sending job on schedule | `continuumUgcAsyncService` |
| UGC Async Service — Survey Sending Processor | Orchestrates fetching, eligibility, and dispatch | `continuumUgcAsyncService` |
| UGC Async Service — Eligibility Framework (Sending) | Applies sending-specific eligibility rules | `continuumUgcAsyncService` |
| UGC Postgres | Source of pending surveys; target for dispatch records | `continuumUgcPostgresDb` |
| Users Service | Provides user email, push token, and locale | `continuumUsersService` |
| Deal Catalog Service | Validates deal title and image URL exist for notification content | `continuumDealCatalogService` |
| Global Subscription Service | Checks whether the user has opted out of survey communications | `globalSubscriptionService_0b7f` |
| Rocketman Transactional | Delivers email survey notification | `rocketmanTransactionalService_1c55` |
| Rocketman Commercial | Delivers push notification survey message | `rocketmanCommercialService_2d66` |
| CRM Message Service | Delivers inbox (in-app) survey message | `crmMessageService_7a44` |

## Steps

1. **Quartz fires sending job**: `LocalSurveySendingJob`, `GoodsSurveySendingJob`, or `PostPurchaseSurveySendingJob` is triggered by Quartz scheduler (`@DisallowConcurrentExecution` prevents overlapping runs)
   - From: Quartz Scheduler
   - To: Survey Sending Processor
   - Protocol: direct (in-process)

2. **Fetches batch of sendable surveys**: `SurveySendingJobHelper` queries `continuumUgcPostgresDb` for surveys in the eligible state with outstanding notifications for the configured medium (email, push, inbox)
   - From: `continuumUgcAsyncService`
   - To: `continuumUgcPostgresDb`
   - Protocol: JDBI / SQL

3. **Submits surveys to thread pool**: `SurveySendingJob.performIteration` submits each survey to a 10-thread executor pool for parallel processing
   - From: Survey Sending Processor
   - To: Survey Sending Processor (parallel threads)
   - Protocol: direct (in-process, concurrent)

4. **Evaluates sending eligibility**: `SurveySendingEligibilityCheckChain` runs checkers: `SurveySendingEnabledChecker`, `SurveyStatusChecker`, `SurveyWaitTimeCompletedChecker`, `NotificationAlreadySentChecker`, `MerchantBlackListedChecker`, `UserOptedOutChecker`, `DealTitleExistsChecker`, `DealImageUrlExistsChecker`, `AnswerAlreadyExistsChecker`; for email: `EmailAlreadyPresentForSurveyChecker`, `NotificationWaitTimeChecker`; for push: `PushTokenExistsChecker`, `PushOrInboxFlowEnabledChecker`
   - From: Survey Sending Processor
   - To: Eligibility Framework (Sending)
   - Protocol: direct (in-process)

5. **Checks user subscription status**: Calls Global Subscription Service to verify user has not opted out of survey emails for their locale
   - From: `continuumUgcAsyncService`
   - To: `globalSubscriptionService_0b7f`
   - Protocol: REST (Retrofit)

6. **Enriches survey with user and deal data**: Calls Users Service for email address / push token and Deal Catalog Service to confirm deal title and image URL are available for the notification payload
   - From: `continuumUgcAsyncService`
   - To: `continuumUsersService`, `continuumDealCatalogService`
   - Protocol: REST (Retrofit)

7. **Dispatches email notification**: Calls Rocketman Transactional service with survey link, deal title, merchant name, and user locale
   - From: `continuumUgcAsyncService`
   - To: `rocketmanTransactionalService_1c55`
   - Protocol: REST (Retrofit)

8. **Dispatches push notification**: Calls Rocketman Commercial service with push token and notification payload (conditional on `PushOrInboxFlowEnabledChecker`)
   - From: `continuumUgcAsyncService`
   - To: `rocketmanCommercialService_2d66`
   - Protocol: REST (Retrofit)

9. **Dispatches inbox notification**: Calls CRM Message Service for in-app inbox delivery (conditional on `PushOrInboxFlowEnabledChecker`)
   - From: `continuumUgcAsyncService`
   - To: `crmMessageService_7a44`
   - Protocol: REST (Retrofit)

10. **Persists dispatch record**: Writes a dispatch record to `continuumUgcPostgresDb` recording the medium, outcome, and timestamp for each notification attempt
    - From: `continuumUgcAsyncService`
    - To: `continuumUgcPostgresDb`
    - Protocol: JDBI / SQL

11. **Iterates until no more surveys**: Job loops (`performIteration`) until a batch returns zero surveys, then terminates

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Eligibility check fails | Dispatch record written with eligibility failure outcome | Survey not sent; outcome logged |
| Rocketman / CRM service 5xx | HTTP error caught; error outcome written to dispatch record | Notification not delivered; not automatically retried |
| Rocketman / CRM service 4xx | Client error logged; dispatch record written with error | Notification not delivered |
| User subscription check fails | Exception caught; user treated as opted-out to prevent accidental over-communication | Survey sending skipped |
| Postgres write failure (dispatch record) | Exception logged; survey may be re-processed on next job run | Possible duplicate dispatch if dispatch record was not saved |
| Thread pool exhaustion | Executor blocks until a thread is available | Job slows; does not drop surveys |

## Sequence Diagram

```
Quartz Scheduler -> Survey Sending Processor: Fire sending job (scheduled)
Survey Sending Processor -> UGC Postgres: Fetch batch of pending surveys (JDBI)
UGC Postgres --> Survey Sending Processor: Survey list
Survey Sending Processor -> Eligibility Framework: Evaluate sending eligibility per survey
Eligibility Framework -> Global Subscription Service: Check user opt-out (REST)
Global Subscription Service --> Eligibility Framework: Opt-out status
Eligibility Framework --> Survey Sending Processor: Eligibility result
Survey Sending Processor -> Users Service: Fetch user email / push token (REST)
Users Service --> Survey Sending Processor: User contact data
Survey Sending Processor -> Deal Catalog Service: Validate deal title / image (REST)
Deal Catalog Service --> Survey Sending Processor: Deal content data
Survey Sending Processor -> Rocketman Transactional: Dispatch email (REST)
Rocketman Transactional --> Survey Sending Processor: Delivery status
Survey Sending Processor -> UGC Postgres: Write dispatch record (JDBI)
```

## Related

- Architecture dynamic view: `dynamic-ugc-async-survey-sending`
- Related flows: [Survey Creation from MBus Event](survey-creation-mbus.md), [Email Reminder Dispatch](survey-sending-notification.md)
- Email reminder variant: `EmailReminderJob` (Quartz) uses `EmailReminderHelper` to fetch surveys eligible for a follow-up reminder email and applies a reduced eligibility chain before re-dispatching via Rocketman Transactional
