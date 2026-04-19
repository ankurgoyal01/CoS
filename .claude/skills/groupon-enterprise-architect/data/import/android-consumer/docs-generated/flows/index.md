---
service: "android-consumer"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for the Groupon Android Consumer App.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Deal Discovery and Browse](deal-discovery-browse.md) | synchronous | User opens app or navigates to browse/search | User browses deal listings: cache check, API fetch, Room store, render, analytics |
| [Shopping Cart and Checkout](shopping-cart-checkout.md) | synchronous | User taps "Add to Cart" or proceeds to checkout | Add to cart through Adyen 3DS payment processing to order confirmation |
| [User Authentication](user-authentication.md) | synchronous | User initiates sign-in or app detects expired session | Okta OAuth 2.0 PKCE flow, token storage, profile fetch, and session management |
| [Push Notification and Deep-link](push-notification-deeplink.md) | event-driven | FCM push received or Android deep-link intent fired | FCM push delivery, notification display, deep-link parsing, and navigation |
| [Analytics and Telemetry Collection](analytics-telemetry-collection.md) | asynchronous | User interaction or system event | Collect user and system events; batch and dispatch to Firebase, Bloomreach, AppsFlyer, Clarity |
| [Offline Support and Cache Invalidation](offline-support-cache-invalidation.md) | event-driven | Network state change or TTL expiry | Connectivity check, TTL-based cache serving, sync queue flush via WorkManager |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 1 |
| Event-driven | 2 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- **Deal Discovery and Browse** spans `continuumAndroidConsumerApp` → `apiProxy` (deals endpoint). See [Deal Discovery and Browse](deal-discovery-browse.md).
- **Shopping Cart and Checkout** spans `continuumAndroidConsumerApp` → `apiProxy` (cart/checkout endpoints) → `Adyen` (3DS). See [Shopping Cart and Checkout](shopping-cart-checkout.md).
- **User Authentication** spans `continuumAndroidConsumerApp` → `oktaIdentity` → `apiProxy`. See [User Authentication](user-authentication.md).
- **Push Notification and Deep-link** spans Firebase Cloud Messaging → `continuumAndroidConsumerApp`. See [Push Notification and Deep-link](push-notification-deeplink.md).
- **Analytics and Telemetry Collection** spans `continuumAndroidConsumerApp` → Firebase Analytics / Bloomreach / AppsFlyer / Clarity. See [Analytics and Telemetry Collection](analytics-telemetry-collection.md).

For central architecture dynamic views, reference `dynamic-android-consumer-*` (no dynamic views are modeled in the DSL at this time).
