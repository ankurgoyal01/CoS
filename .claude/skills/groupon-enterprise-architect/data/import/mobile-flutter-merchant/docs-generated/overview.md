---
service: "mobile-flutter-merchant"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Merchant Commerce"
platform: "iOS, Android"
team: "Merchant Mobile (mobile-mx@groupon.com)"
status: active
tech_stack:
  language: "Dart"
  language_version: "3.27.2"
  framework: "Flutter"
  framework_version: "3.27.2"
  runtime: "Flutter"
  runtime_version: "3.27.2"
  build_tool: "Gradle (Android), Xcode/Fastlane (iOS), Flutter CLI"
  package_manager: "pub"
---

# Mobile Flutter Merchant Overview

## Purpose

The Mobile Flutter Merchant app is Groupon's cross-platform mobile client for merchants, available on iOS and Android. It allows merchants to authenticate, manage their deal portfolio, process customer redemptions, review payment schedules, manage locations, and communicate through inbox and support channels. The app serves as the primary self-service tool for Groupon merchant partners interacting with the Continuum commerce platform.

## Scope

### In scope

- Merchant authentication and session management via Google OAuth and Okta/webview login
- Deal browsing, creation, and publishing workflows
- Redemption processing for customer vouchers at point of sale
- Payment schedule and settlement inquiry
- Merchant place and location management via M3 Places Service
- Inbox messaging and push notification management (Firebase Cloud Messaging)
- Merchant advisor insights and onboarding todo tracking
- Offline data access via local SQLite storage (Drift ORM)
- Feature flag-driven configuration via Firebase Remote Config

### Out of scope

- Consumer-facing deal discovery or checkout (handled by consumer-facing apps)
- Backend deal pricing, fulfillment, and billing logic (owned by Continuum services)
- Merchant account provisioning and contracting (handled by Salesforce CRM)
- Server-side notification routing (owned by NOTS Service)

## Domain Context

- **Business domain**: Merchant Commerce
- **Platform**: iOS, Android (Flutter/Dart)
- **Upstream consumers**: Merchants (Groupon merchant partners) interact directly with the app
- **Downstream dependencies**: Universal Merchant API, Deal Management API, M3 Places Service, Payments Service, Merchant Advisor Service, NOTS Service, Salesforce, Google Maps, Google OAuth

## Stakeholders

| Role | Description |
|------|-------------|
| Merchant Mobile Team | Owns development, release, and support; contact mobile-mx@groupon.com |
| Tech Lead | abhishekkumar — primary architecture owner |
| Groupon Merchants | End users; operate the app in-store and on-the-go |
| Merchant Operations | Internal team monitoring deal health and redemptions |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Dart | 3.27.2 | pubspec.yaml / flutter SDK constraint |
| Framework | Flutter | 3.27.2 | pubspec.yaml / flutter SDK constraint |
| Runtime | Flutter | 3.27.2 | pubspec.yaml |
| Build tool (Android) | Gradle | — | android/build.gradle |
| Build tool (iOS) | Xcode / Fastlane | — | ios/ Fastfile |
| Package manager | pub | — | pubspec.yaml |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| redux | 5.0.0 | state-management | Centralised unidirectional state management for UI flows |
| firebase_analytics | 11.3.4 | metrics | User behaviour and event tracking |
| firebase_crashlytics | 4.1.4 | logging | Crash reporting and diagnostics |
| firebase_messaging | 15.1.4 | message-client | Firebase Cloud Messaging for push notifications |
| firebase_remote_config | 5.1.4 | config | Remote feature flag delivery |
| drift | 2.21.0 | orm | Type-safe SQLite ORM for local offline data persistence |
| sembast | 3.4.4 | db-client | NoSQL embedded store for lightweight local data |
| http | 1.0.0 | http-framework | HTTP client for REST API calls to Continuum services |
| google_maps_flutter | 2.7.0 | ui-framework | Embeds Google Maps for merchant/location visualisation |
| flutter_local_notifications | 17.0.0 | message-client | Local notification scheduling and display |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
