---
service: "mvrt"
title: "Online Voucher Redemption"
generated: "2026-03-03"
type: flow
flow_name: "online-voucher-redemption"
flow_type: synchronous
trigger: "HTTP POST from browser SPA to /redeemVouchers"
participants:
  - "mvrt_webRouting"
  - "voucherRedemption"
  - "voucherSearch"
  - "apiProxy"
  - "continuumVoucherInventoryService"
architecture_ref: "dynamic-search_and_redeem_flow"
---

# Online Voucher Redemption

## Summary

After performing a search, the user selects one or more redeemable vouchers and triggers a batch redemption. The Web Routing component receives the POST request, validates the Okta session, and passes the selected vouchers to the Voucher Redemption Engine. The engine filters to redeemable units, determines whether each voucher requires normal or forced (managerial) redemption based on the user's permissions, and posts individual redemption requests to the Voucher Inventory Service in parallel. Results — including success/failure status, redemption date, and redeemed-by identity — are returned to the browser as JSON.

## Trigger

- **Type**: user-action
- **Source**: MVRT browser SPA — user selects vouchers from search results and clicks Redeem
- **Frequency**: On demand, per redemption batch action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser SPA | Initiates redemption; displays results | — |
| Web Routing and Auth (`mvrt_webRouting`) | Receives HTTP POST, enforces auth, builds attribute context | `mvrt_webRouting` |
| Voucher Redemption Engine (`voucherRedemption`) | Filters redeemable units, determines redemption type, fans out redemption calls | `voucherRedemption` |
| API Proxy | Routes outbound VIS calls | `apiProxy` |
| Voucher Inventory Service | Accepts redemption POST and marks vouchers as redeemed | `continuumVoucherInventoryService` |

## Steps

1. **Receive redemption request**: Browser POSTs to `/redeemVouchers` with `vouchers[]` (each containing uuid, redeemable flags), `note`, and Okta user context.
   - From: Browser SPA
   - To: `mvrt_webRouting`
   - Protocol: REST/HTTP POST

2. **Authenticate and extract context**: Web Routing validates Okta session; extracts `oktaUser`, `MvrtConfig`, `redemptionSize` (chunk: 15), `redemptionSourceType` (`normal`/`finance`), `post_expiration_days`, and country redemption enable flags.
   - From: `mvrt_webRouting`
   - To: `voucherRedemption`
   - Protocol: Direct (in-process)

3. **Filter redeemable vouchers**: Redemption Engine filters the input list to only those with `redeemable === true`.
   - From: `voucherRedemption` (internal)
   - Protocol: Direct (in-process)

4. **Determine redemption type per voucher**: For each voucher, checks `managerialRedeemable` and `normalRedeemable` flags:
   - If `managerialRedeemable === true` and `normalRedeemable === false`: use forced mode, `sourceType = 'finance'`, note prefix `"MVRT - Forced. Note: <user_note>"`
   - Otherwise: use normal mode, `sourceType = 'portal'`, note prefix `"MVRT - Normal. Note: <user_note>"`
   - From: `voucherRedemption` (internal)
   - Protocol: Direct (in-process)

5. **Post redemption to VIS**: For each voucher, calls `units.postRedemption` with `unitUUID`, `notes`, `redeemedBy` (Okta email), and `sourceType`. All calls are made in parallel via `Promise.all`.
   - From: `voucherRedemption`
   - To: `apiProxy` → `continuumVoucherInventoryService`
   - Protocol: REST via `@grpn/voucher-inventory-client`

6. **Return redemption results**: Each voucher result includes `redemptionStatus`, `redemptionDate`, `redeemedBy`, `reason` (Success or Failed with error description), and updated `redeemable` flag.
   - From: `voucherRedemption` → `mvrt_webRouting`
   - To: Browser SPA
   - Protocol: REST/HTTP 200 JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| VIS returns non-201 | `reason = 'Failed <errorMessage>'`; `redeemable = true` restored | Voucher marked Failed in UI; user can retry |
| VIS error object with `message` field | Appended to failure reason string | Displayed to user in results table |
| VIS error object with `description` field | Appended to failure reason string | Displayed to user in results table |
| All redemptions fail (Promise.all catch) | Error logged as `[UNITS-REDEEM-ERROR]`; empty array returned | UI shows no successful redemptions |
| Voucher already redeemed | VIS returns non-201; failure reason returned | Voucher shows current redemption status |

## Sequence Diagram

```
Browser -> mvrt_webRouting: POST /redeemVouchers {vouchers[], note}
mvrt_webRouting -> voucherRedemption: invoke with oktaUser, redemptionConfig
voucherRedemption -> voucherRedemption: filter to redeemable=true
voucherRedemption -> voucherRedemption: determine normal vs forced per voucher
voucherRedemption -> apiProxy: units.postRedemption(uuid, redeemedBy, notes, sourceType) [parallel]
apiProxy -> continuumVoucherInventoryService: POST redemption
continuumVoucherInventoryService --> apiProxy: 201 Created or error
apiProxy --> voucherRedemption: {httpCode, uuid, redeemedBy, notes, redemptionDate}
voucherRedemption --> mvrt_webRouting: [{uuid, redemptionStatus, reason, redemptionDate, ...}]
mvrt_webRouting --> Browser: 200 JSON {results[]}
```

## Related

- Architecture dynamic view: `dynamic-search_and_redeem_flow`
- Related flows: [Online Voucher Search](online-voucher-search.md)
