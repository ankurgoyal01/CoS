---
service: "ios-consumer"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 2
---

# Integrations

## Overview

The iOS Consumer App integrates with three external systems (Apple App Store, Apple Push Notification service, and Apple TestFlight/App Store Connect) and two internal Groupon services (`api-lazlo-sox` and `gaurun`). The primary internal integration is with `api-lazlo-sox`, which acts as the aggregating mobile API gateway for all consumer data. Push delivery is handled by `gaurun` via APNS.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Apple App Store | app-store-submission | App distribution and updates to consumers | yes | External |
| Apple Push Notification service (APNS) | apns | Device push notification delivery | yes | External |
| Apple TestFlight / App Store Connect | rest (Fastlane API) | QA/beta distribution and App Store release management | no | External |
| Groupon Jenkins CI | rest (Fastlane + Jenkins) | CI build triggering at `https://cloud-jenkins.groupondev.com/job/mobile/job/ios-consumer/buildWithParameters` | no | External |
| Jira (Atlassian) | rest | GPROD change management ticket creation at `https://groupondev.atlassian.net` | no | External |
| TestRail | rest | QA verification report retrieval at `https://groupondev.testrail.io` | no | External |

### Apple Push Notification service (APNS) Detail

- **Protocol**: APNS (OS-level, HTTP/2-based Apple protocol)
- **Base URL / SDK**: OS-level iOS framework
- **Auth**: Apple developer certificate (`com.groupon.grouponapp` + `com.groupon.grouponapp.notificationServiceExtension`), managed via Fastlane Match
- **Purpose**: Registers device push token with Groupon backend; receives push notifications for deals, orders, and promotions
- **Failure mode**: Notifications are not delivered; user sees no push alerts; app continues operating normally
- **Circuit breaker**: Not applicable — OS-managed

### Jenkins CI Detail

- **Protocol**: REST (HTTP POST with query parameters)
- **Base URL / SDK**: `https://cloud-jenkins.groupondev.com/job/mobile/job/ios-consumer/buildWithParameters`
- **Auth**: Jenkins API token
- **Purpose**: Triggers iOS IPA build with parameters: `LABEL`, `MODULE`, `GIT_REF`, `Build_Config`, `UPLOAD_TO_ITUNES`, `BUILD_IPA`, `UPLOAD_TO_NEXUS`
- **Failure mode**: Build not triggered; mobilebot reports failure to Slack channel `#mobile-ios-release`
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `api-lazlo-sox` | https / rest | Mobile API gateway — aggregates deal, user, order, geo, and taxonomy data for the app | `continuumSystem` |
| `gaurun` | kafka + apns | Pushes promotional and transactional notifications to iOS devices via the `ios-consumer` Kafka worker | `continuumSystem` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| `next-pwa-app` (mobile-expo) | Native iOS bridge (git submodule) | MBNXT embeds `ios-consumer` as `groupon-legacy` submodule; reads NSUserDefaults and Keychain state via `LegacyDataStore` bridge at startup to determine bucketing and authentication |
| End consumers (iPhone/iPad users) | iOS App Store | Deal browsing, purchasing, voucher management |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

- The `api-lazlo-sox` gateway is the critical dependency for all app functionality; if the gateway is down, deal browsing, checkout, and account features are unavailable.
- APNS dependency is OS-managed; no application-level circuit breaker is in place.
- The Jenkins CI dependency is non-critical for runtime operation; it only affects the build and release pipeline.
