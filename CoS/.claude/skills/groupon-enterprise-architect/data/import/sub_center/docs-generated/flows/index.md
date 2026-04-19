---
service: "sub_center"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Subscription Center.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Email Unsubscribe](email-unsubscribe.md) | synchronous | User clicks email unsubscribe link | Processes a user's request to unsubscribe from one or all email channels |
| [SMS Unsubscribe](sms-unsubscribe.md) | synchronous | User submits SMS unsubscribe form | Processes a user's request to stop receiving SMS messages and sends Twilio confirmation |
| [Subscription Preferences](subscription-preferences.md) | synchronous | User navigates to and submits subscription center | Loads and updates a user's full subscription channel preferences |
| [Channel Management](channel-management.md) | synchronous | User toggles individual channel subscriptions | Enables or disables individual email or SMS subscription channels for a user |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All four flows interact with downstream Continuum services:

- [Email Unsubscribe](email-unsubscribe.md) calls `grouponV2Api_ext_7c1d` and `gssService_ext_5b3e` to read and write subscription state
- [SMS Unsubscribe](sms-unsubscribe.md) calls `subscriptionsService_ext_9a41` and dispatches via `twilioSms_ext_3a95`
- [Subscription Preferences](subscription-preferences.md) orchestrates calls to `subscriptionsService_ext_9a41`, `geoDetailsService_ext_4d22`, `remoteLayoutService_ext_1f8c`, `featureFlagsService_ext_8e0b`, and `optimizeService_ext_6c7f`
- [Channel Management](channel-management.md) writes to `grouponV2Api_ext_7c1d` or `subscriptionsService_ext_9a41`

> Cross-service dynamic views are not yet defined in the federated architecture model (`views/dynamics.dsl` is empty).
