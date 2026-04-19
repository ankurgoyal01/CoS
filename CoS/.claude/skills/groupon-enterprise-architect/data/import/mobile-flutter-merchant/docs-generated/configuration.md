---
service: "mobile-flutter-merchant"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [firebase-remote-config, build-flavors, config-files]
---

# Configuration

## Overview

The Mobile Flutter Merchant app is configured through three mechanisms: build flavors (compile-time environment targeting), embedded platform config files (Firebase credentials), and Firebase Remote Config (runtime feature flags). There are no server-side environment variables — the app is a mobile client deployed to device stores. Build flavors (`redemption-debug`, `redemption-release`, `advance-debug`, `advance-release`) control which environment targets (debug vs. release, and feature variant) the app is built against.

## Environment Variables

> Not applicable — this is a mobile client application. There are no runtime environment variables. Environment-specific values are embedded at build time via build flavors.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| Remote Config keys (via `firebase_remote_config`) | Control feature availability, UI behaviour, and rollout gates for merchant features | Defined as defaults in `firebase_remote_config` initialisation | global |

> Specific Remote Config key names are defined in the app source and managed through the Firebase project console. Default values are embedded in the app at build time and activate when Firebase Remote Config is unreachable.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `google-services.json` | JSON | Firebase project credentials for Android builds |
| `GoogleService-Info.plist` | plist (XML) | Firebase project credentials for iOS builds |
| `pubspec.yaml` | YAML | Flutter/Dart dependency manifest and SDK constraints |
| `android/build.gradle` | Groovy/Kotlin DSL | Android build configuration, flavors, signing config |
| `ios/Fastfile` | Ruby (Fastlane DSL) | iOS build, signing, and TestFlight/App Store deployment automation |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Firebase API key | Firebase project authentication for Analytics, Crashlytics, Messaging, Remote Config | Embedded in `google-services.json` / `GoogleService-Info.plist`; managed via CI secrets |
| Google Maps API key | Authorises Google Maps SDK tile and geocoding requests | Embedded in Android/iOS build configuration; managed via CI secrets |
| Salesforce credentials | Authenticates Salesforce messaging and support SDK | Embedded in build configuration; managed via CI secrets |
| App signing keystores | Android APK/AAB signing | Managed in Jenkins CI; not committed to source |
| iOS code signing certificates | Apple App Store and TestFlight distribution | Managed via Fastlane match or CI secrets |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

The app uses four build flavors to target different environments and feature sets:

| Flavor | Purpose |
|--------|---------|
| `redemption-debug` | Debug build for the redemption feature variant; points to non-production Continuum APIs |
| `redemption-release` | Production build for the redemption feature variant; targets production Continuum APIs and App Stores |
| `advance-debug` | Debug build for the advance (deal management) feature variant; non-production APIs |
| `advance-release` | Production build for the advance feature variant; targets production APIs and App Stores |

Firebase Remote Config flags may also differ by environment through separate Firebase projects or flag targeting rules configured in the Firebase console.
