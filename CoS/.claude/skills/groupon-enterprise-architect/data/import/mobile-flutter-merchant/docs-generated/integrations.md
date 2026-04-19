---
service: "mobile-flutter-merchant"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 4
internal_count: 5
---

# Integrations

## Overview

The Mobile Flutter Merchant app integrates with five internal Continuum services and four external third-party platforms. All integrations are outbound — the app calls dependencies; no system calls back into the app directly (push notifications from FCM are the exception, delivered via the Firebase SDK). REST/HTTP is the primary protocol for Continuum services; SDKs are used for Google and Salesforce integrations.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google OAuth | OAuth2 / WebView | Merchant authentication and token issuance | yes | `googleOAuth` |
| Google Maps | SDK | Renders merchant location maps and geospatial place views | no | `googleMaps` |
| Salesforce | SDK/REST | Merchant support messaging and case management | no | `salesForce` |
| Firebase (Analytics, Crashlytics, Messaging, Remote Config) | SDK | Analytics, crash reporting, push notifications, remote feature flags | yes | — |

### Google OAuth Detail

- **Protocol**: OAuth2 via embedded WebView / system browser
- **Base URL / SDK**: Google Identity SDK, Okta webview login
- **Auth**: OAuth2 authorization code flow
- **Purpose**: Issues authentication tokens for merchant sign-in; tokens are stored in platform-secure storage and attached to all API calls
- **Failure mode**: Login blocked; merchants cannot access the app; session errors surface in the login screen
- **Circuit breaker**: No

### Google Maps Detail

- **Protocol**: Native SDK (`google_maps_flutter` 2.7.0)
- **Base URL / SDK**: `google_maps_flutter` Flutter plugin
- **Auth**: Google Maps API key embedded in build configuration
- **Purpose**: Renders interactive maps for merchant place/location management screens
- **Failure mode**: Map tiles fail to load; location features degrade gracefully with a blank map view
- **Circuit breaker**: No

### Salesforce Detail

- **Protocol**: SDK/REST
- **Base URL / SDK**: Salesforce Messaging SDK integrated into `mmaMerchantEngagementModule`
- **Auth**: Salesforce service credentials (managed via build configuration)
- **Purpose**: Provides in-app messaging and support case submission for merchants
- **Failure mode**: Support chat unavailable; inbox messaging features degrade; users see an error state
- **Circuit breaker**: No

### Firebase Detail

- **Protocol**: Firebase SDKs
- **Base URL / SDK**: `firebase_analytics` 11.3.4, `firebase_crashlytics` 4.1.4, `firebase_messaging` 15.1.4, `firebase_remote_config` 5.1.4
- **Auth**: Firebase project credentials embedded in `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
- **Purpose**: Analytics event tracking, crash diagnostics, push notification delivery (FCM), and remote feature flag configuration
- **Failure mode**: Analytics and crash reporting degrade silently; push notifications are not delivered; feature flags fall back to default values in `firebase_remote_config`
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Universal Merchant API | REST/HTTP | Dashboard data, deals, vouchers, account management | `continuumUniversalMerchantApi` |
| Deal Management API | REST/HTTP | Deal draft creation, edit, change request workflows | `continuumDealManagementApi` |
| M3 Places Service | REST/HTTP | Merchant place and location data read/write | `continuumM3PlacesService` |
| Payments Service | REST/HTTP | Payment schedule and settlement detail retrieval | `continuumPaymentsService` |
| Merchant Advisor Service | REST/HTTP | Merchant advisor insights and performance recommendations | `merchantAdvisorService` |
| NOTS Service | REST/HTTP | Onboarding todo items and dismiss actions | `notsService` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. This app is a mobile client and does not expose endpoints; it is not consumed by any downstream system.

## Dependency Health

- The `mmaApiOrchestrator` component manages all outbound HTTP calls to Continuum services using the `http` 1.0.0 package
- No explicit circuit breaker library is evidenced in the inventory; failure handling is implemented per-feature within the orchestrator
- Firebase Remote Config provides default flag values that activate when the Firebase service is unreachable, ensuring the app remains functional
- Local SQLite (Drift) data serves as a fallback when Continuum backend services are unavailable, enabling offline read access
