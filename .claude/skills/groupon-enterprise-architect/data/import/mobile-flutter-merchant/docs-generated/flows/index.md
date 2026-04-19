---
service: "mobile-flutter-merchant"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 7
---

# Flows

Process and flow documentation for the Mobile Flutter Merchant app.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Merchant Login Flow](merchant-login-flow.md) | synchronous | User opens app / taps sign-in | Authenticates merchant via Google OAuth / Okta and establishes session |
| [Deal Creation and Publishing](deal-creation-and-publishing.md) | synchronous | Merchant initiates new deal from deals screen | Merchant drafts, edits, and submits a deal for publishing via Deal Management API |
| [Redemption Processing](redemption-processing.md) | synchronous | Merchant scans or enters voucher code at point of sale | Validates and redeems a customer voucher via Universal Merchant API |
| [Payment and Settlement Inquiry](payment-and-settlement-inquiry.md) | synchronous | Merchant navigates to payments screen | Fetches and displays payment schedules and settlement details from Payments Service |
| [Inbox and Notifications Management](inbox-and-notifications-management.md) | event-driven | FCM push notification received or merchant opens inbox | Delivers and displays push notifications; merchant views and acts on inbox messages |
| [Location and Place Management](location-and-place-management.md) | synchronous | Merchant navigates to places screen | Reads and updates merchant place/location data via M3 Places Service with map rendering |
| [Offline and Sync Workflow](offline-and-sync-workflow.md) | asynchronous | App detects network connectivity change | Reads from local SQLite cache when offline; syncs with Continuum APIs on reconnection |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 0 |
| Event-driven | 1 |

## Cross-Service Flows

- **Merchant Login Flow** spans `continuumMobileFlutterMerchantApp` and `googleOAuth` — see [Merchant Login Flow](merchant-login-flow.md)
- **Deal Creation and Publishing** spans `continuumMobileFlutterMerchantApp` and `continuumDealManagementApi` — see [Deal Creation and Publishing](deal-creation-and-publishing.md)
- **Redemption Processing** spans `continuumMobileFlutterMerchantApp` and `continuumUniversalMerchantApi` — see [Redemption Processing](redemption-processing.md)
- **Payment and Settlement Inquiry** spans `continuumMobileFlutterMerchantApp` and `continuumPaymentsService` — see [Payment and Settlement Inquiry](payment-and-settlement-inquiry.md)
- **Inbox and Notifications Management** spans `continuumMobileFlutterMerchantApp`, `notsService`, and the Firebase FCM channel — see [Inbox and Notifications Management](inbox-and-notifications-management.md)
- **Location and Place Management** spans `continuumMobileFlutterMerchantApp`, `continuumM3PlacesService`, and `googleMaps` — see [Location and Place Management](location-and-place-management.md)
- **Offline and Sync Workflow** is internal to `continuumMobileFlutterMerchantApp` with sync to all Continuum APIs on reconnection — see [Offline and Sync Workflow](offline-and-sync-workflow.md)
