---
service: "ugc-moderation"
title: "Merchant UGC Transfer"
generated: "2026-03-03"
type: flow
flow_name: "merchant-ugc-transfer"
flow_type: synchronous
trigger: "Moderator initiates a merchant UGC transfer from the merchant transfer page"
participants:
  - "Moderator (browser)"
  - "continuumUgcModerationWeb"
  - "continuumUgcService"
  - "m3_merchant_service"
architecture_ref: "dynamic-ugcModeration"
---

# Merchant UGC Transfer

## Summary

This flow covers how moderators transfer all UGC associations (tips, recommendations) from one merchant to another. This is used when a merchant changes hands, merges, or when UGC has been attributed to the wrong merchant. The flow has two phases: a preview phase that fetches and compares UGC data for both merchants in parallel, and an execution phase that calls the UGC API's transfer endpoint. Both merchants are validated as UUID format before any API calls are made.

## Trigger

- **Type**: user-action
- **Source**: Moderator navigates to `GET /merchant_transfer` and submits a transfer request
- **Frequency**: on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Moderator (browser) | Enters old/new merchant UUIDs, reviews preview, confirms transfer | Human operator (admins allowlist) |
| `continuumUgcModerationWeb` | Orchestrates preview (parallel API calls) and transfer execution | `continuumUgcModerationWeb` |
| `continuumUgcService` | Provides UGC counts, reviews, answers; executes the transfer | `continuumUgcService` |
| `m3_merchant_service` | Provides merchant profiles (name, core data) for both merchants | `merchantDataApi` |

## Steps

### Phase 1: Preview

1. **Moderator opens merchant transfer page**: Browser sends `GET /merchant_transfer`.
   - From: Browser
   - To: `continuumUgcModerationWeb` (Merchant Transfer Controller — `main` action)
   - Protocol: HTTP

2. **Controller renders the transfer form**: Returns HTML page with old/new merchant UUID input fields.
   - From: `continuumUgcModerationWeb`
   - To: Browser
   - Protocol: HTTP (HTML)

3. **Moderator enters merchant UUIDs and requests preview**: Browser sends `GET /merchant_transfer/search?old=<uuid>&new=<uuid>`.
   - From: Browser
   - To: `continuumUgcModerationWeb` (Merchant Transfer Controller — `search` action)
   - Protocol: HTTP

4. **Controller validates UUIDs**: Uses `validator.isUUID()` to validate both `old` and `new` parameters. Returns `{ response: 'no-valid-merchant-id' }` if invalid.
   - From: Merchant Transfer Controller
   - To: Merchant Transfer Controller (internal)
   - Protocol: internal

5. **Controller fetches merchant data in parallel**: Launches 6 parallel async tasks via `async.parallel()`:
   - `merchantDataClient.merchants.getMerchant({ merchantId: old, view_type: core })`
   - `merchantDataClient.merchants.getMerchant({ merchantId: new, view_type: core })`
   - `ugcServiceClient.admin.searchAnswers({ merchantId: old, tag: mc_feedback })`
   - `ugcServiceClient.admin.searchAnswers({ merchantId: new, tag: mc_feedback })`
   - `ugcServiceClient.merchants.reviews({ id: old, merchantId: old, Cache-Control: no-cache })`
   - `ugcServiceClient.merchants.reviews({ id: new, merchantId: new, Cache-Control: no-cache })`
   - From: `continuumUgcModerationWeb`
   - To: `m3_merchant_service` + `continuumUgcService` (concurrent)
   - Protocol: HTTPS

6. **All parallel tasks complete**: Controller aggregates results: merchant profiles, tip counts, recommendation percentages for both old and new merchants.
   - From: `m3_merchant_service` + `continuumUgcService`
   - To: `continuumUgcModerationWeb`
   - Protocol: HTTPS

7. **Controller formats and returns preview**: Returns JSON `{ result: "ok", data: { merchant, newMerchant, ugc: { recommendationsAll, tipsAllCount, ... } } }`.
   - From: `continuumUgcModerationWeb`
   - To: Browser
   - Protocol: HTTP (JSON)

### Phase 2: Execution

8. **Moderator confirms and submits transfer**: Browser sends `POST /merchant_transfer` with `{ newMerchantId, oldMerchantId, caseId, issueType, reasonSummary }`.
   - From: Browser
   - To: `continuumUgcModerationWeb` (Merchant Transfer Controller — `transfer` action)
   - Protocol: HTTP

9. **Controller extracts agent identity**: Reads `x-grpn-username` from request headers; defaults to `'admin'` if not present.
   - From: Merchant Transfer Controller
   - To: Merchant Transfer Controller (internal)
   - Protocol: internal

10. **Controller validates required fields**: Checks `newMerchantId` and `oldMerchantId` are present; returns `jsonMissingParams` error if missing.
    - From: Merchant Transfer Controller
    - To: Merchant Transfer Controller (internal)
    - Protocol: internal

11. **Controller calls UGC transfer API**: Calls `ugcServiceClient.transfer.merchant()` with `{ newMerchantId, oldMerchantId, caseId, reasonSummary, issueType, agent: username }`.
    - From: `continuumUgcModerationWeb`
    - To: `continuumUgcService`
    - Protocol: HTTPS

12. **UGC API executes transfer**: Transfers all UGC associations from old merchant to new merchant.
    - From: `continuumUgcService`
    - To: `continuumUgcService` (internal operation)
    - Protocol: internal

13. **Transfer result returned**: UGC API returns success response; moderation tool returns `{ result: "ok", data: { message: "Merchant transfer successful", ... } }`.
    - From: `continuumUgcModerationWeb`
    - To: Browser
    - Protocol: HTTP (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid UUID format | Returns `{ response: 'no-valid-merchant-id' }` immediately | Moderator sees invalid ID message |
| Missing `newMerchantId` | `responders.jsonMissingParams('newMerchantId')` | Browser receives missing params error |
| Missing `oldMerchantId` | `responders.jsonMissingParams('oldMerchantId')` | Browser receives missing params error |
| Parallel preview task failure | `async.parallel` callback receives error; `jsonErrorResponse(err.statusCode, 'unable-to-load')` | Browser receives error response |
| UGC transfer returns 404 | `responders.html('Merchant not found, please check the IDs.')` | Error message displayed |
| UGC transfer API error | `responders.html('Error during merchant transfer, please try again later.')` | Error message displayed |
| Unable to transfer | `responders.html('Unable to transfer merchant, please reach out to CoreApps')` | Escalation message shown |

## Sequence Diagram

```
Moderator -> continuumUgcModerationWeb: GET /merchant_transfer/search?old=<uuid>&new=<uuid>
continuumUgcModerationWeb -> m3_merchant_service: getMerchant(old, view_type=core) [parallel]
continuumUgcModerationWeb -> m3_merchant_service: getMerchant(new, view_type=core) [parallel]
continuumUgcModerationWeb -> continuumUgcService: searchAnswers(old, tag=mc_feedback) [parallel]
continuumUgcModerationWeb -> continuumUgcService: searchAnswers(new, tag=mc_feedback) [parallel]
continuumUgcModerationWeb -> continuumUgcService: merchants.reviews(old) [parallel]
continuumUgcModerationWeb -> continuumUgcService: merchants.reviews(new) [parallel]
m3_merchant_service --> continuumUgcModerationWeb: merchant profiles
continuumUgcService --> continuumUgcModerationWeb: tips + reviews data
continuumUgcModerationWeb --> Moderator: { result: "ok", data: { merchant, newMerchant, ugc } }

Moderator -> continuumUgcModerationWeb: POST /merchant_transfer { oldMerchantId, newMerchantId, caseId, issueType, reasonSummary }
continuumUgcModerationWeb -> continuumUgcService: transfer.merchant(oldMerchantId, newMerchantId, agent=username)
continuumUgcService --> continuumUgcModerationWeb: success
continuumUgcModerationWeb --> Moderator: { result: "ok", data: { message: "Merchant transfer successful" } }
```

## Related

- Architecture dynamic view: `dynamic-ugcModeration`
- Related flows: [Tip Search and Delete](tip-search-and-delete.md)
- [Integrations](../integrations.md) for `m3_merchant_service` and `continuumUgcService` details
- [API Surface](../api-surface.md) for endpoint details
