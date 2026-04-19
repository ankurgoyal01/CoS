---
service: "ios-consumer"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Consumer Web & Mobile"
platform: "Continuum"
team: "Mobile Consumer"
status: active
tech_stack:
  language: "Swift"
  language_version: ""
  framework: "UIKit / Native iOS"
  framework_version: ""
  runtime: "iOS"
  runtime_version: ""
  build_tool: "Xcode + Fastlane"
  package_manager: "CocoaPods"
---

# iOS Consumer App Overview

## Purpose

The iOS Consumer App (`ios-consumer`) is the native Groupon iPhone and iPad application used by consumers to browse deals, complete purchases, manage orders, and redeem vouchers. It is the primary iOS client for the Continuum commerce platform, communicating with backend services via the API Lazlo gateway. The app is distributed through the Apple App Store under the bundle identifier `com.groupon.grouponapp`.

## Scope

### In scope

- Native iOS deal browsing, search, and category navigation
- Consumer checkout and order placement via Continuum backend APIs
- Voucher and order management (My Groupons)
- User authentication, account management, and onboarding flows
- Push notification registration and receipt (via APNS)
- Location-aware deal discovery and division/area selection
- Card-Linked Offer (CLO) local store preferences
- Wishlist management
- Proximity notification support
- Legacy user preferences and state bridging to the MBNXT mobile shell (`next-pwa-app/apps/mobile-expo`)

### Out of scope

- Android consumer experience — handled by `android-consumer`
- Next-generation MBNXT mobile experience — handled by `next-pwa-app` (mobile-expo)
- Merchant-facing mobile functionality — handled by `mobile-flutter-merchant`
- Server-side API aggregation — handled by `api-lazlo-sox`
- Push notification delivery infrastructure — handled by `gaurun` / `push-infrastructure`

## Domain Context

- **Business domain**: Consumer Web & Mobile
- **Platform**: Continuum
- **Upstream consumers**: End consumers via Apple App Store; MBNXT (`next-pwa-app`) embeds this app as a git submodule (`groupon-legacy`) for legacy-mode execution
- **Downstream dependencies**: `api-lazlo-sox` (mobile API gateway), `gaurun` (push notification service via APNS), Groupon backend services via Lazlo aggregation layer

## Stakeholders

| Role | Description |
|------|-------------|
| Mobile Consumer Team | Develops and releases the iOS app; team email `iphone@groupon.com` |
| Catalin Calina | iOS release signatory (GPROD Jira ticket approver) |
| Bogdan Herput | iOS release signatory |
| Nisha Malesh | iOS release signatory |
| Ivan Garcia Maya | iOS release signatory |
| Darren Redmond | iOS release signatory |
| Consumer End Users | iPhone and iPad users browsing and purchasing Groupon deals |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Swift | Not specified in DSL | `continuum-ios-consumer-app-components.dsl` |
| Legacy modules | Objective-C | N/A | `legacy-data.ts` references to `.m` source files |
| Build tool | Xcode | Not specified | `apps/mobile-expo/README.md` (Xcode setup) |
| CI automation | Fastlane | Not specified | `apps/mobile-expo/fastlane/Matchfile` |
| Package manager | CocoaPods | Not specified | `apps/mobile-expo/README.md` (CocoaPods setup) |
| Code signing | Fastlane Match | Not specified | `fastlane/Matchfile` — git storage at `ios-consumer-development-certificates` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| CocoaPods | Not specified | package-manager | iOS dependency management |
| Fastlane | Not specified | deployment | Automated build, code signing, and App Store uploads |
| Fastlane Match | Not specified | auth | Shared code signing certificate management via git |
| APNS (Apple Push Notification service) | N/A (OS-level) | messaging | Push notification token registration and delivery |
| iOS Keychain / `rn-keychain` bridge | Not specified | auth | Secure storage of auth tokens, bcookie, user credentials shared with MBNXT |
| NSUserDefaults / Settings (GPUserPrefsMapping) | N/A (OS-level) | state-management | Persists user preferences, division, location, experiment overrides, and feature flags |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
