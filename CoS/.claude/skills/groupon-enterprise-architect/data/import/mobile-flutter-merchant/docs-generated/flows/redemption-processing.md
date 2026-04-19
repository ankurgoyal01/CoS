---
service: "mobile-flutter-merchant"
title: "Redemption Processing"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "redemption-processing"
flow_type: synchronous
trigger: "Merchant scans or manually enters a customer voucher code at point of sale"
participants:
  - "continuumMobileFlutterMerchantApp"
  - "mmaPresentationLayer"
  - "mmaApiOrchestrator"
  - "continuumUniversalMerchantApi"
architecture_ref: "dynamic-redemption-processing"
---

# Redemption Processing

## Summary

The Redemption Processing flow enables a Groupon merchant to validate and redeem a customer's voucher at the point of sale using the mobile app. The merchant scans a QR code or enters a voucher code; the app submits a redemption request to `continuumUniversalMerchantApi`, receives confirmation, records the redemption locally via the Drift ORM, and presents the result to the merchant. This is a core transactional flow and is supported by the `redemption` build flavor.

## Trigger

- **Type**: user-action
- **Source**: Merchant opens the redemptions screen and scans or enters a customer voucher code
- **Frequency**: On-demand (at point of sale for each customer transaction)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Presentation Layer | Renders redemption screen, captures voucher code input, displays result | `mmaPresentationLayer` |
| API Orchestrator | Submits redemption request and retrieves voucher status | `mmaApiOrchestrator` |
| Universal Merchant API | Validates voucher and processes redemption transaction | `continuumUniversalMerchantApi` |
| Local SQLite / Drift | Records redemption result locally for audit and offline history | `continuumMobileFlutterMerchantApp` (on-device) |

## Steps

1. **Open Redemption Screen**: Merchant navigates to the redemptions section; `mmaPresentationLayer` renders the voucher entry interface (camera scanner or manual input).
   - From: `mmaPresentationLayer`
   - To: Merchant (UI)
   - Protocol: Direct

2. **Capture Voucher Code**: Merchant scans customer's QR code or manually types the voucher code; `mmaPresentationLayer` validates the format client-side before submission.
   - From: Merchant (user input)
   - To: `mmaPresentationLayer`
   - Protocol: Direct

3. **Submit Redemption Request**: `mmaPresentationLayer` triggers `mmaApiOrchestrator` to submit the redemption to `continuumUniversalMerchantApi`.
   - From: `mmaApiOrchestrator`
   - To: `continuumUniversalMerchantApi`
   - Protocol: REST/HTTP

4. **Validate and Process Voucher**: `continuumUniversalMerchantApi` validates the voucher (existence, expiry, already-redeemed status, deal association) and records the redemption.
   - From: `continuumUniversalMerchantApi` (internal processing)
   - To: Continuum backend data store
   - Protocol: Internal

5. **Receive Redemption Result**: `continuumUniversalMerchantApi` returns the redemption outcome (success, already redeemed, expired, invalid) to `mmaApiOrchestrator`.
   - From: `continuumUniversalMerchantApi`
   - To: `mmaApiOrchestrator`
   - Protocol: REST/HTTP

6. **Persist Local Redemption Record**: `mmaApiOrchestrator` writes the redemption result to the local Drift SQLite store for history and offline audit.
   - From: `mmaApiOrchestrator`
   - To: Local SQLite (Drift ORM)
   - Protocol: Direct (Drift)

7. **Display Redemption Result**: `mmaPresentationLayer` renders the outcome to the merchant — green success screen, or specific error message (e.g., "Voucher already used", "Voucher expired").
   - From: `mmaPresentationLayer`
   - To: Merchant (UI)
   - Protocol: Direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid voucher code format | Client-side validation in `mmaPresentationLayer` | Error shown before API call; merchant prompted to re-enter |
| Voucher already redeemed | `continuumUniversalMerchantApi` returns already-redeemed status | "Already redeemed" message shown to merchant |
| Voucher expired | `continuumUniversalMerchantApi` returns expired status | "Voucher expired" message shown; no redemption recorded |
| Network failure during submission | HTTP error in `mmaApiOrchestrator` | Connectivity error displayed; merchant prompted to retry; no redemption recorded |
| API timeout | `mmaApiOrchestrator` timeout | Redemption status unknown; merchant advised to retry or contact support |

## Sequence Diagram

```
Merchant -> mmaPresentationLayer: Opens redemption screen
mmaPresentationLayer -> Merchant: Render scanner / input UI
Merchant -> mmaPresentationLayer: Scans QR or enters voucher code
mmaPresentationLayer -> mmaPresentationLayer: Validate code format
mmaPresentationLayer -> mmaApiOrchestrator: redeemVoucher(voucherCode)
mmaApiOrchestrator -> continuumUniversalMerchantApi: POST /vouchers/{code}/redeem
continuumUniversalMerchantApi -> continuumUniversalMerchantApi: Validate + record redemption
continuumUniversalMerchantApi --> mmaApiOrchestrator: {status: success | error, details}
mmaApiOrchestrator -> LocalSQLite: Write redemption record
mmaApiOrchestrator --> mmaPresentationLayer: Redemption result
mmaPresentationLayer -> Merchant: Display success or error screen
```

## Related

- Architecture dynamic view: `dynamic-redemption-processing`
- Related flows: [Deal Creation and Publishing](deal-creation-and-publishing.md), [Offline and Sync Workflow](offline-and-sync-workflow.md)
