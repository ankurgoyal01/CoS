---
service: "android-consumer"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumAndroidConsumerApp, continuumAndroidLocalStorage]
---

# Architecture Context

## System Context

The Android Consumer App sits at the outermost edge of the Groupon Continuum platform, acting as the primary mobile touchpoint for end consumers. It communicates outbound to the Groupon backend via `apiProxy`, delegates authentication to `oktaIdentity`, and feeds telemetry to Firebase, Bloomreach, and AppsFlyer. On-device state is persisted in `continuumAndroidLocalStorage`. The app does not expose any network-facing API surface of its own — all calls are outbound.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Android Consumer App | `continuumAndroidConsumerApp` | MobileApp | Kotlin/Java Android | SDK 35 | Main Groupon Android consumer application assembled from feature and platform modules |
| Android Local Storage | `continuumAndroidLocalStorage` | Database | SQLite/Room/SharedPreferences | Room 2.3.0 | On-device storage for cached API payloads, preferences, and session-related state |

## Components by Container

### Android Consumer App (`continuumAndroidConsumerApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| App Entry Points (`androidConsumer_appEntryPoints`) | Activities, fragments, and navigation entry points from the Groupon app module | Android UI |
| Feature Modules (`androidConsumer_featureModules`) | Business flows — deals, checkout, search, account, notifications | Kotlin/Java modules |
| Network Integration Layer (`androidConsumer_networkIntegration`) | Retrofit/OkHttp API clients and adapters that call Groupon backend services | Retrofit/OkHttp |
| Local Persistence Layer (`androidConsumer_localPersistence`) | Room, SQLite, and SharedPreferences adapters for cached and offline state | Room/SQLite/SharedPreferences |
| Telemetry and Crash Reporting (`androidConsumer_telemetryAndCrash`) | Analytics, attribution, and crash reporting integrations | Firebase/AppsFlyer/Bloomreach |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumAndroidConsumerApp` | `continuumAndroidLocalStorage` | Stores cached content, preferences, and local session state | Direct (Room/SQLite) |
| `continuumAndroidConsumerApp` | `apiProxy` | Calls Groupon consumer APIs for deals, cart, checkout, identity, and account flows | HTTPS/REST |
| `continuumAndroidConsumerApp` | `googleMaps` | Uses map rendering and geocoding APIs | Android SDK |
| `continuumAndroidConsumerApp` | `rokt` | Loads marketing placements and related event signals | Android SDK |
| `continuumAndroidConsumerApp` | `firebase` | Sends analytics, push token registration, and crash events (stub) | Android SDK |
| `continuumAndroidConsumerApp` | `bloomreach` | Sends engagement and campaign events (stub) | Android SDK |
| `continuumAndroidConsumerApp` | `appsFlyer` | Sends attribution and install conversion events (stub) | Android SDK |
| `continuumAndroidConsumerApp` | `oktaIdentity` | Executes identity and authentication flows (stub) | HTTPS/OIDC |
| `androidConsumer_appEntryPoints` | `androidConsumer_featureModules` | Starts and coordinates feature flows | Direct |
| `androidConsumer_featureModules` | `androidConsumer_networkIntegration` | Requests remote data and writes mutations | Direct |
| `androidConsumer_featureModules` | `androidConsumer_localPersistence` | Reads and writes cached/session state | Direct |
| `androidConsumer_featureModules` | `androidConsumer_telemetryAndCrash` | Emits behavioral and operational events | Direct |
| `androidConsumer_networkIntegration` | `androidConsumer_telemetryAndCrash` | Publishes request timing and error telemetry | Direct |

## Architecture Diagram References

- Component: `components-continuum-android-consumer-app`
