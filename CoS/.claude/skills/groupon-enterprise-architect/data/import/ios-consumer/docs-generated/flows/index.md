---
service: "ios-consumer"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for the iOS Consumer App.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [App Launch and Mode Selection](app-launch-mode-selection.md) | synchronous | User opens Groupon app on iPhone/iPad | Determines whether to display legacy native app or MBNXT experience based on bucketing and opt-out flags |
| [Push Notification Registration](push-notification-registration.md) | synchronous | App installs or user grants notification permission | Registers APNS device token with Groupon backend |
| [Deal Browse and Discovery](deal-browse-discovery.md) | synchronous | User opens app or taps category/search | Fetches deal listings from `api-lazlo-sox` and displays to user |
| [Consumer Checkout](consumer-checkout.md) | synchronous | User taps "Buy Now" on deal | Completes purchase flow through `api-lazlo-sox` to Continuum checkout services |
| [App Store Release](app-store-release.md) | batch | Release engineer triggers via mobilebot | Builds, signs, and publishes the iOS app to App Store via Jenkins and Fastlane |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- The [App Launch and Mode Selection](app-launch-mode-selection.md) flow spans `continuumIosConsumerApp` and `next-pwa-app` (mobile-expo) when the MBNXT shell reads legacy state via `LegacyDataStore`.
- The [Push Notification Registration](push-notification-registration.md) flow involves `continuumIosConsumerApp`, `api-lazlo-sox`, and the APNS external system.
- The [App Store Release](app-store-release.md) flow spans `ios-consumer` (Jenkins CI), `mobilebot`, Apple App Store Connect, Jira (GPROD), and TestRail.
