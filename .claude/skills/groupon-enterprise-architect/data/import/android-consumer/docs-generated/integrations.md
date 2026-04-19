---
service: "android-consumer"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 11
internal_count: 1
---

# Integrations

## Overview

The Android Consumer App integrates with one internal Groupon service (`apiProxy`) and eleven external services. Most integrations use vendor Android SDKs bundled at build time. Network API calls use Retrofit/OkHttp with OAuth 2.0 bearer token authentication. The app has no inbound network integrations — all dependencies are outbound.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Firebase Analytics | sdk | User event telemetry | yes | `firebase` |
| Firebase Crashlytics | sdk | Crash reporting | yes | `firebase` |
| Firebase Cloud Messaging | sdk | Push notification delivery | yes | `firebase` |
| Google Maps SDK | sdk | Map rendering and geocoding | no | `googleMaps` |
| Okta | https/oidc | OAuth 2.0 / OIDC authentication | yes | `oktaIdentity` |
| Adyen | sdk | 3D Secure payment processing | yes | — |
| AppsFlyer | sdk | Install and campaign attribution | no | `appsFlyer` |
| Bloomreach (Exponea) | sdk | Customer engagement event delivery | no | `bloomreach` |
| Rokt | sdk | Marketing placement rendering | no | `rokt` |
| Approov | sdk | API protection and certificate pinning | yes | — |
| Microsoft Clarity | sdk | Session recording | no | — |
| Sift Science | sdk | Fraud detection signals | no | — |
| reCAPTCHA | sdk | Bot protection | no | — |

### Firebase Detail

- **Protocol**: Android SDK (Firebase BOM)
- **Base URL / SDK**: `com.google.firebase:firebase-bom` — Analytics 23.0.0, Crashlytics 20.0.3, FCM 21.1.0
- **Auth**: Google Service Account (configured via `google-services.json`)
- **Purpose**: Crash reporting, user behavior analytics, and push notification delivery
- **Failure mode**: Analytics and crash events are queued locally and sent when connectivity resumes; FCM push delivery failure results in missed notification
- **Circuit breaker**: No — SDK handles retries internally

### Okta Detail

- **Protocol**: HTTPS / OAuth 2.0 / OpenID Connect
- **Base URL / SDK**: Okta Android SDK (`oktaIdentity`)
- **Auth**: OAuth 2.0 client credentials + PKCE
- **Purpose**: User sign-in, token issuance, token refresh, and session management
- **Failure mode**: Authentication flows fail; user is shown login error; cached session may allow continued access until token expiry
- **Circuit breaker**: No

### Adyen Detail

- **Protocol**: Android SDK (`com.adyen.checkout:*` 5.16.0)
- **Base URL / SDK**: Adyen Checkout Android SDK
- **Auth**: Adyen public key / merchant token (supplied at checkout session initiation)
- **Purpose**: 3D Secure payment processing during checkout
- **Failure mode**: Checkout flow fails; user is shown payment error; no charge is made
- **Circuit breaker**: No

### Approov Detail

- **Protocol**: Android SDK (Approov 3.5.3) embedded in OkHttp interceptor chain
- **Base URL / SDK**: `io.approov:approov-android-sdk:3.5.3`
- **Auth**: Approov secret (stored in `gradle.properties` as `APPROOV_SECRET`)
- **Purpose**: API integrity protection and certificate pinning for all backend calls
- **Failure mode**: Network requests are blocked if Approov attestation fails; app shows connectivity error
- **Circuit breaker**: No — failure is hard block

### Google Maps SDK Detail

- **Protocol**: Android SDK (`com.google.android.gms:play-services-maps` 19.2.0)
- **Base URL / SDK**: Google Maps Android SDK
- **Auth**: Google Maps API key (configured in `gradle.properties`)
- **Purpose**: Render deal location maps and resolve geocoding for location-based search
- **Failure mode**: Map component shows empty or error state; search still functions without map
- **Circuit breaker**: No

### Bloomreach (Exponea) Detail

- **Protocol**: Android SDK (Bloomreach 4.8.0)
- **Base URL / SDK**: `com.exponea.sdk:sdk:4.8.0`
- **Auth**: Bloomreach project tokens (UK/US separate, stored in `gradle.properties`)
- **Purpose**: Customer engagement event delivery for segmentation and campaigns
- **Failure mode**: Events are queued and retried by SDK; no user-facing impact
- **Circuit breaker**: No — SDK handles internally

### AppsFlyer Detail

- **Protocol**: Android SDK (AppsFlyer 6.17.5)
- **Base URL / SDK**: `com.appsflyer:af-android-sdk:6.17.5`
- **Auth**: AppsFlyer Dev Key (stored in `gradle.properties`)
- **Purpose**: Mobile attribution — tracks install source, campaign conversion, and in-app events
- **Failure mode**: Attribution data is lost; no user-facing impact
- **Circuit breaker**: No

### Rokt Detail

- **Protocol**: Android SDK (Rokt 3.15.11-beta.2)
- **Base URL / SDK**: `com.rokt:rokt-sdk:3.15.11-beta.2`
- **Auth**: Rokt account tag (configured at integration point)
- **Purpose**: Render marketing and promotional placements at designated screen locations
- **Failure mode**: Placement renders empty; no user-facing error
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Groupon Backend APIs | HTTPS/REST | Deals, cart, checkout, identity, account, search, collections | `apiProxy` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. This app is a user-facing client; it is consumed directly by Groupon Android users via Google Play Store.

## Dependency Health

- Retrofit/OkHttp is configured with connection and read timeouts (exact values in `gradle.properties` / OkHttp client configuration).
- Approov enforces certificate pinning — if the backend certificate changes without updating the Approov configuration, all API calls will fail.
- Firebase, Bloomreach, and AppsFlyer SDKs queue events locally and retry; these are not on the critical path for app functionality.
- Adyen is on the critical path for checkout; failures are surfaced to the user as payment errors.
- Okta is on the critical path for authentication; token refresh failures result in forced re-login.
