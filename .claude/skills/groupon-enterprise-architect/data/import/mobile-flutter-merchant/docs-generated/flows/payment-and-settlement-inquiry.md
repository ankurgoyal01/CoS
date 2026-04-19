---
service: "mobile-flutter-merchant"
title: "Payment and Settlement Inquiry"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "payment-and-settlement-inquiry"
flow_type: synchronous
trigger: "Merchant navigates to the payments screen"
participants:
  - "continuumMobileFlutterMerchantApp"
  - "mmaPresentationLayer"
  - "mmaApiOrchestrator"
  - "continuumPaymentsService"
architecture_ref: "dynamic-payment-and-settlement-inquiry"
---

# Payment and Settlement Inquiry

## Summary

The Payment and Settlement Inquiry flow retrieves and displays a merchant's payment schedules and settlement details from the Continuum Payments Service. When a merchant opens the payments screen, the `mmaApiOrchestrator` fetches payment schedule data from `continuumPaymentsService`, caches results in the local Drift SQLite store, and the `mmaPresentationLayer` renders the payment history and upcoming settlement dates. This flow is read-only; payments are calculated and settled by the Continuum backend.

## Trigger

- **Type**: user-action
- **Source**: Merchant navigates to the payments section of the app
- **Frequency**: On-demand (whenever merchant checks payment status)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Presentation Layer | Renders payment schedule and settlement detail screens | `mmaPresentationLayer` |
| API Orchestrator | Fetches payment data from Payments Service and manages local cache | `mmaApiOrchestrator` |
| Payments Service | Provides payment schedules and settlement details for the merchant | `continuumPaymentsService` |
| Local SQLite / Drift | Caches payment data for offline access | `continuumMobileFlutterMerchantApp` (on-device) |

## Steps

1. **Navigate to Payments Screen**: Merchant taps the payments navigation item; `mmaPresentationLayer` dispatches a load action.
   - From: Merchant (user action)
   - To: `mmaPresentationLayer`
   - Protocol: Direct

2. **Check Local Cache**: `mmaApiOrchestrator` checks the Drift SQLite store for recently cached payment data to display immediately while the remote fetch is in-flight.
   - From: `mmaApiOrchestrator`
   - To: Local SQLite (Drift ORM)
   - Protocol: Direct

3. **Fetch Payment Schedules**: `mmaApiOrchestrator` calls `continuumPaymentsService` to retrieve the merchant's payment schedule.
   - From: `mmaApiOrchestrator`
   - To: `continuumPaymentsService`
   - Protocol: REST/HTTP

4. **Receive Payment Data**: `continuumPaymentsService` returns payment schedule entries including amounts, scheduled dates, and settlement statuses.
   - From: `continuumPaymentsService`
   - To: `mmaApiOrchestrator`
   - Protocol: REST/HTTP

5. **Update Local Cache**: `mmaApiOrchestrator` writes the fresh payment data to the Drift SQLite store for offline access.
   - From: `mmaApiOrchestrator`
   - To: Local SQLite (Drift ORM)
   - Protocol: Direct

6. **Fetch Settlement Details**: Merchant taps a specific payment entry to view settlement details; `mmaApiOrchestrator` fetches detail data from `continuumPaymentsService`.
   - From: `mmaApiOrchestrator`
   - To: `continuumPaymentsService`
   - Protocol: REST/HTTP

7. **Render Payment and Settlement View**: `mmaPresentationLayer` displays the payment schedule list and detail view with amounts, dates, and status indicators.
   - From: `mmaPresentationLayer`
   - To: Merchant (UI)
   - Protocol: Direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Payments Service unavailable | `mmaApiOrchestrator` receives HTTP error | Cached Drift data displayed with staleness indicator; error banner shown |
| No payment data available | `continuumPaymentsService` returns empty response | Empty state screen shown ("No payments found") |
| Network timeout | HTTP timeout in `mmaApiOrchestrator` | Cached data served; connectivity error displayed |
| Auth token expired during fetch | 401 response triggers `mmaAuthenticationModule` token refresh | Token refreshed silently; request retried |

## Sequence Diagram

```
Merchant -> mmaPresentationLayer: Navigates to Payments
mmaPresentationLayer -> mmaApiOrchestrator: loadPayments()
mmaApiOrchestrator -> LocalSQLite: Read cached payment data
LocalSQLite --> mmaApiOrchestrator: Cached records (if available)
mmaApiOrchestrator --> mmaPresentationLayer: Show cached data immediately
mmaApiOrchestrator -> continuumPaymentsService: GET /merchant/payments/schedule
continuumPaymentsService --> mmaApiOrchestrator: Payment schedule entries
mmaApiOrchestrator -> LocalSQLite: Write updated payment data
mmaApiOrchestrator --> mmaPresentationLayer: Updated payment list
Merchant -> mmaPresentationLayer: Taps payment entry
mmaPresentationLayer -> mmaApiOrchestrator: loadPaymentDetail(paymentId)
mmaApiOrchestrator -> continuumPaymentsService: GET /merchant/payments/{id}
continuumPaymentsService --> mmaApiOrchestrator: Settlement details
mmaApiOrchestrator --> mmaPresentationLayer: Payment detail
mmaPresentationLayer -> Merchant: Render settlement detail view
```

## Related

- Architecture dynamic view: `dynamic-payment-and-settlement-inquiry`
- Related flows: [Offline and Sync Workflow](offline-and-sync-workflow.md), [Merchant Login Flow](merchant-login-flow.md)
