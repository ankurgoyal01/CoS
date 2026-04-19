---
service: "android-consumer"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Mobile Consumer Commerce"
platform: "Android"
team: "Mobile / Android Consumer"
status: active
tech_stack:
  language: "Kotlin"
  language_version: "2.2.0"
  framework: "Android Framework / AndroidX"
  framework_version: "Android SDK 35"
  runtime: "Android"
  runtime_version: "minSdk 26 / targetSdk 35"
  build_tool: "Gradle + Android Gradle Plugin 8.8.2"
  package_manager: "Gradle"
---

# Groupon Android Consumer App Overview

## Purpose

The Groupon Android Consumer App (`android-consumer`) is the primary native Android application that enables Groupon customers to browse deals, add items to cart, complete checkout, manage their accounts, and track orders. It is a multi-module Kotlin/Java monorepo with 40+ Gradle modules organised by feature, distributed via the Google Play Store under package ID `com.groupon`. The app integrates with Groupon backend APIs, third-party payment processors, analytics platforms, and marketing attribution services.

## Scope

### In scope

- Deal browsing, search, and collection management
- Shopping cart management and checkout flow with Adyen 3DS payment processing
- User authentication via Okta OAuth 2.0 / OIDC
- Account profile management and settings
- Push notification receipt and deep-link navigation
- Local caching of API responses via Room/SQLite for offline support
- User event telemetry via Firebase Analytics, Bloomreach, and AppsFlyer
- Crash and error reporting via Firebase Crashlytics
- Marketing placement rendering via Rokt
- Map rendering and geocoding via Google Maps SDK

### Out of scope

- Backend deal data management (owned by `apiProxy` / Continuum backend services)
- Identity provider management (owned by `oktaIdentity`)
- iOS consumer app (separate repository)
- Web consumer experience (MBNXT / Next.js)

## Domain Context

- **Business domain**: Mobile Consumer Commerce
- **Platform**: Android (Google Play Store, package `com.groupon`)
- **Upstream consumers**: End users via Google Play Store; push notifications delivered via Firebase Cloud Messaging
- **Downstream dependencies**: Groupon backend APIs (`apiProxy`), Okta (`oktaIdentity`), Google Maps (`googleMaps`), Firebase (analytics, crash, FCM), Bloomreach, AppsFlyer, Adyen, Rokt

## Stakeholders

| Role | Description |
|------|-------------|
| Mobile / Android Consumer Team | Primary owners; responsible for feature development, releases, and incidents |
| Platform / Architecture Team | Maintains architecture model and cross-service contracts |
| Product Management | Defines feature roadmap and A/B test experiments |
| Commerce / Checkout Team | Co-owns checkout and payment flows |
| Marketing / Growth Team | Consumes attribution events from AppsFlyer and Bloomreach |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Kotlin | 2.2.0 | `gradle.properties` |
| Language (secondary) | Java | 8+ | `gradle.properties` |
| Framework | Android Framework / AndroidX | Android SDK 35 | `gradle.properties` |
| Runtime | Android | minSdk 26 / targetSdk 35 / compileSdk 35 | `gradle.properties` |
| Build tool | Gradle + Android Gradle Plugin | 8.8.2 | `gradle.properties` |
| Package manager | Gradle | — | `build.gradle` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Retrofit | 2.9.0 | http-framework | REST API client for Groupon backend calls |
| OkHttp | 4.12.0 | http-framework | HTTP client with interceptors and timeout handling |
| Room | 2.3.0 | orm | SQLite ORM for local caching and offline state |
| Firebase Crashlytics | 20.0.3 | logging | Crash reporting and error tracking |
| RxJava2 | 2.2.21 | async | Reactive programming (legacy async flows) |
| Kotlin Coroutines | 1.10.2 | async | Modern suspend-function async/await |
| Jackson | 2.14.3 | serialization | JSON parsing for API responses |
| Google Maps SDK | 19.2.0 | ui-framework | Map rendering and geocoding |
| Firebase Analytics | 23.0.0 | metrics | User event analytics |
| Firebase Cloud Messaging | 21.1.0 | message-client | Push notification delivery |
| AppsFlyer | 6.17.5 | metrics | Install source and campaign attribution |
| Bloomreach (Exponea) | 4.8.0 | metrics | Customer engagement event delivery |
| Rokt | 3.15.11-beta.2 | ui-framework | Marketing placement rendering |
| Approov | 3.5.3 | auth | API protection and certificate pinning |
| Adyen | 5.16.0 | auth | 3D Secure payment processing |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
