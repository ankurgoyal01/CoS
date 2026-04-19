---
service: "breakage-reduction-service"
title: "Reminder Scheduling"
generated: "2026-03-03"
type: flow
flow_name: "reminder-scheduling"
flow_type: synchronous
trigger: "POST /remind_me_later/v1/users/{user_id}/send_reminder or POST /remind_me_later/v1/users/{user_id}/vouchers/{voucher_id}/reminders"
participants:
  - "continuumBreakageReductionService"
  - "continuumUsersService"
  - "continuumVoucherInventoryApi"
  - "riseApi"
architecture_ref: "dynamic-brs-reminder-scheduling-flow"
---

# Reminder Scheduling

## Summary

The reminder scheduling flow allows consumers to schedule a future reminder for a specific voucher. When a user requests a "Remind Me Later" from the post-purchase UI, BRS validates the request, loads the user account from Users Service and the voucher metadata from VIS, then submits an ad-hoc scheduled job to the RISE scheduler with the target delivery time and notification context. This flow is modeled as a Structurizr dynamic view (`dynamic-brs-reminder-scheduling-flow`).

## Trigger

- **Type**: api-call (user-action via consumer UI)
- **Source**: Consumer-facing web or mobile application making an authenticated request via Hybrid Boundary
- **Frequency**: On demand, per user action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| BRS API Routes | Receives and routes remind-me-later requests | `brsApiRoutes` |
| Remind-Me-Later Handler | Validates input, coordinates data loading, and invokes RISE | `reminderHandler` |
| Storage Facade | Loads user and voucher data before scheduling | `storageFacade` |
| Service Client Adapters (RISE) | Submits the scheduled reminder job to RISE | `serviceClientAdapters` |
| Users Service | Provides user account details (email, locale) | `continuumUsersService` |
| Voucher Inventory Service | Provides voucher metadata for reminder context | `continuumVoucherInventoryApi` |
| RISE Scheduler | Receives and queues the reminder job for future delivery | `riseApi` |

## Steps

1. **Receive remind-me-later request**: Client sends `POST /remind_me_later/v1/users/{user_id}/send_reminder` or `POST /remind_me_later/v1/users/{user_id}/vouchers/{voucher_id}/reminders` with `remind_at` (target delivery time) and `voucher_id` parameters.
   - From: consumer client
   - To: `brsApiRoutes`
   - Protocol: HTTPS

2. **Route to Remind-Me-Later Handler**: API Routes dispatches the request to the Remind-Me-Later Handler.
   - From: `brsApiRoutes`
   - To: `reminderHandler`
   - Protocol: direct

3. **Load user account**: Remind-Me-Later Handler (via Storage Facade) calls Users Service to retrieve user account details — specifically email address and locale for notification personalization.
   - From: `storageFacade`
   - To: `continuumUsersService`
   - Protocol: HTTPS/JSON

4. **Load voucher metadata**: Storage Facade calls Voucher Inventory Service to retrieve the voucher unit record, confirming the voucher exists and extracting context such as inventory product ID, expiration date, and consumer ID.
   - From: `storageFacade`
   - To: `continuumVoucherInventoryApi`
   - Protocol: HTTPS/JSON (`GET /inventory/v1/units`)

5. **Validate reminder eligibility**: The Remind-Me-Later Handler verifies the `remind_at` time is valid (in the future, within the voucher validity window) and that the user is eligible for reminders in their country (using `reminder_countries_email` / `reminder_countries_push` feature flags).

6. **Submit job to RISE**: The handler uses the RISE Service Client Adapter to POST an ad-hoc scheduled job to RISE with the voucher ID, user context, notification type (`custom_reminder`), and target delivery time (`remind_at`).
   - From: `serviceClientAdapters` (RISE client)
   - To: `riseApi`
   - Protocol: HTTPS/JSON (`POST /rise/v1/adhoc?clientId=breakage-reduction-service`)

7. **Return confirmation**: BRS returns a success response (200 OK) to the caller confirming the reminder has been scheduled.
   - From: `reminderHandler`
   - To: consumer client
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| User not found | Error propagated from Users Service client | Caller receives error response |
| Voucher not found | `notFoundError` thrown in Storage Facade | Caller receives 404 |
| `remind_at` invalid or in the past | Validation error in Remind-Me-Later Handler | Caller receives 4xx validation error |
| User country not eligible for reminders | Request rejected | Caller receives 4xx |
| RISE scheduling failure | Error propagated from RISE client | Caller receives 5xx; no retry |

## Sequence Diagram

```
Client -> brsApiRoutes: POST /remind_me_later/v1/users/{user_id}/send_reminder
brsApiRoutes -> reminderHandler: dispatch
reminderHandler -> storageFacade: loadUser + loadVoucher
storageFacade -> continuumUsersService: loadUserDetails(userId)
continuumUsersService --> storageFacade: user account
storageFacade -> continuumVoucherInventoryApi: unitsShow(voucherId)
continuumVoucherInventoryApi --> storageFacade: voucher unit
storageFacade --> reminderHandler: user + voucher context
reminderHandler -> serviceClientAdapters: schedule(risePayload)
serviceClientAdapters -> riseApi: POST /rise/v1/adhoc?clientId=breakage-reduction-service
riseApi --> serviceClientAdapters: 200 OK (job queued)
reminderHandler --> Client: 200 OK (reminder scheduled)
```

## Related

- Architecture dynamic view: `dynamic-brs-reminder-scheduling-flow`
- Related flows: [Voucher Next-Actions Computation](voucher-next-actions.md), [Voucher Context Preload](voucher-context-preload.md)
