---
service: "clo-service"
title: "User Account Lifecycle"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "user-account-lifecycle"
flow_type: event-driven
trigger: "users.account or gdpr.erasure event from Message Bus"
participants:
  - "continuumCloServiceWorker"
  - "cloWorkerMessageConsumers"
  - "cloWorkerAsyncJobs"
  - "continuumCloServicePostgres"
  - "messageBus"
  - "continuumUsersService"
architecture_ref: "components-clo-service-worker"
---

# User Account Lifecycle

## Summary

This flow describes how CLO Service responds to user account lifecycle events. When a user account is created, updated, or suspended, CLO Service adjusts the user's CLO profile and enrollment eligibility accordingly. When a GDPR erasure request arrives, CLO Service removes or anonymizes all personal data and CLO enrollments associated with that user. The GDPR erasure path is compliance-critical and SOX in-scope.

## Trigger

- **Type**: event (Message Bus)
- **Source**: `users.account` events (account creation, update, suspension) and `gdpr.erasure` events from Message Bus
- **Frequency**: Continuous (event-driven); GDPR events are time-sensitive with regulatory SLAs

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CLO Service Worker | Consumes and processes account lifecycle events | `continuumCloServiceWorker` |
| Message Consumers | Receives users.account and gdpr.erasure events | `cloWorkerMessageConsumers` |
| Async Job Processors | Executes account update and erasure jobs | `cloWorkerAsyncJobs` |
| CLO Service PostgreSQL | Stores user CLO profiles, enrollments, and claim records | `continuumCloServicePostgres` |
| Message Bus | Delivers account lifecycle events | `messageBus` |
| Users Service | Authoritative source of user account state | `continuumUsersService` |

## Steps

### Account Created / Updated

1. **Receives account event**: `cloWorkerMessageConsumers` receives a `users.account` event from Message Bus with user id and account state.
   - From: `messageBus`
   - To: `cloWorkerMessageConsumers`
   - Protocol: Message Bus

2. **Dispatches to async job**: `cloWorkerMessageConsumers` dispatches the event to `cloWorkerAsyncJobs`.
   - From: `cloWorkerMessageConsumers`
   - To: `cloWorkerAsyncJobs`
   - Protocol: Direct (Sidekiq)

3. **Fetches authoritative user state**: `cloWorkerAsyncJobs` calls `continuumUsersService` (or uses event payload) to confirm current account state.
   - From: `cloWorkerAsyncJobs`
   - To: `continuumUsersService`
   - Protocol: REST

4. **Creates or updates CLO user profile**: `cloWorkerAsyncJobs` upserts the user's CLO profile in `continuumCloServicePostgres`, setting eligibility status based on account state.
   - From: `cloWorkerAsyncJobs`
   - To: `continuumCloServicePostgres`
   - Protocol: ActiveRecord / SQL

5. **Adjusts enrollments if account suspended**: If the account event indicates suspension, `cloWorkerAsyncJobs` deactivates all active enrollments for the user, calling card network APIs via `cloWorkerPartnerProcessors` as needed.
   - From: `cloWorkerAsyncJobs`
   - To: `continuumCloServicePostgres`, card network APIs
   - Protocol: ActiveRecord / SQL, REST

### GDPR Erasure

1. **Receives erasure event**: `cloWorkerMessageConsumers` receives a `gdpr.erasure` event from Message Bus containing the user id to be erased.
   - From: `messageBus`
   - To: `cloWorkerMessageConsumers`
   - Protocol: Message Bus

2. **Dispatches erasure job**: `cloWorkerMessageConsumers` dispatches the erasure job to `cloWorkerAsyncJobs` with high priority.
   - From: `cloWorkerMessageConsumers`
   - To: `cloWorkerAsyncJobs`
   - Protocol: Direct (Sidekiq)

3. **Removes or anonymizes enrollments**: `cloWorkerAsyncJobs` deletes or anonymizes all enrollment records for the user in `continuumCloServicePostgres`, including card tokens and personal identifiers.
   - From: `cloWorkerAsyncJobs`
   - To: `continuumCloServicePostgres`
   - Protocol: ActiveRecord / SQL

4. **Removes or anonymizes claims**: `cloWorkerAsyncJobs` deletes or anonymizes all claim records associated with the user.
   - From: `cloWorkerAsyncJobs`
   - To: `continuumCloServicePostgres`
   - Protocol: ActiveRecord / SQL

5. **Removes or anonymizes card interactions**: `cloWorkerAsyncJobs` deletes or anonymizes card interaction records for the user.
   - From: `cloWorkerAsyncJobs`
   - To: `continuumCloServicePostgres`
   - Protocol: ActiveRecord / SQL

6. **Deregisters card tokens with card networks**: `cloWorkerPartnerProcessors` calls card network APIs to remove the user's card tokens from enrolled offers.
   - From: `cloWorkerPartnerProcessors`
   - To: Card network APIs (Visa, Mastercard, Amex)
   - Protocol: REST / SOAP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Account event for unknown user | Create new CLO user profile | Profile initialized with received account state |
| Duplicate account event | Idempotent upsert | No duplicate profiles; last event state applied |
| GDPR erasure job failure | Sidekiq retry; dead job queue on exhaustion | Immediate alert; compliance SLA breach risk |
| Card network deregistration failure | Retry via Sidekiq | Deregistration delayed; card tokens may remain active on network temporarily |
| Partial erasure (some records deleted, some not) | Transaction rollback; full retry | Consistent erasure on next attempt |

## Sequence Diagram

```
messageBus -> cloWorkerMessageConsumers: users.account event (suspended)
cloWorkerMessageConsumers -> cloWorkerAsyncJobs: dispatch account update job
cloWorkerAsyncJobs -> continuumUsersService: GET user state
continuumUsersService --> cloWorkerAsyncJobs: account suspended
cloWorkerAsyncJobs -> continuumCloServicePostgres: update user profile (ineligible)
cloWorkerAsyncJobs -> continuumCloServicePostgres: deactivate enrollments
cloWorkerPartnerProcessors -> CardNetworkAPI: deregister card tokens

messageBus -> cloWorkerMessageConsumers: gdpr.erasure event
cloWorkerMessageConsumers -> cloWorkerAsyncJobs: dispatch erasure job (high priority)
cloWorkerAsyncJobs -> continuumCloServicePostgres: anonymize enrollments
cloWorkerAsyncJobs -> continuumCloServicePostgres: anonymize claims
cloWorkerAsyncJobs -> continuumCloServicePostgres: anonymize card interactions
cloWorkerPartnerProcessors -> CardNetworkAPI: deregister card tokens
```

## Related

- Architecture dynamic view: `components-clo-service-worker`
- Related flows: [Card Enrollment and CLO Activation](card-enrollment-clo-activation.md), [Claim Processing and Statement Credit](claim-processing-statement-credit.md)
