---
service: "mobile-flutter-merchant"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: false
orchestration: "app-store"
environments: [debug, release]
---

# Deployment

## Overview

The Mobile Flutter Merchant app is a mobile application distributed through the Google Play Store (Android) and Apple App Store / TestFlight (iOS). It is not containerised or orchestrated via Kubernetes or ECS. CI/CD is managed by Jenkins. Build automation for iOS uses Fastlane. The app has two feature variants (redemption, advance) each with debug and release flavors, producing four distinct build targets.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | Mobile app distributed as APK/AAB (Android) and IPA (iOS) |
| Orchestration | Google Play Store / Apple App Store | Platform store distribution and update delivery |
| CI/CD | Jenkins | Builds, signs, and publishes app artifacts to stores and TestFlight |
| iOS automation | Fastlane | Handles code signing, build, and TestFlight upload |
| Android build | Gradle | Compiles, flavors, and signs Android artifacts |
| Flutter build | Flutter CLI | Cross-platform build orchestration |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| redemption-debug | Local and CI debug builds for redemption feature variant | — | — |
| redemption-release | Production builds for redemption variant; distributed via Play Store and App Store | Global | Google Play Store / Apple App Store |
| advance-debug | Local and CI debug builds for advance (deal management) feature variant | — | — |
| advance-release | Production builds for advance variant; distributed via Play Store and App Store | Global | Google Play Store / Apple App Store |
| TestFlight | iOS pre-release distribution to internal and beta testers | Global | Apple TestFlight |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: Jenkinsfile (Android Gradle), `ios/Fastfile` (iOS Fastlane)
- **Trigger**: On push to release branches; manual dispatch for production releases

### Pipeline Stages

1. **Checkout**: Clones the repository and configures the Flutter environment
2. **Dependency install**: Runs `flutter pub get` to fetch Dart/Flutter dependencies
3. **Static analysis**: Runs `flutter analyze` for lint and type checks
4. **Test**: Runs `flutter test` for unit and widget tests
5. **Build (Android)**: Runs `flutter build apk` / `flutter build appbundle` per flavor using Gradle
6. **Build (iOS)**: Runs Fastlane lanes to build and sign the iOS IPA per flavor
7. **Sign**: Applies Android keystore signing and iOS code signing certificates
8. **Publish (Android)**: Uploads AAB to Google Play Store internal/production track
9. **Publish (iOS)**: Uploads IPA to TestFlight or App Store via Fastlane

## Scaling

> Not applicable — mobile applications do not scale horizontally. The app is deployed to individual devices; usage scales through store distribution and user adoption.

## Resource Requirements

> Not applicable — resource requirements are constrained by the target mobile device specifications, not by infrastructure configuration. The app targets iOS and Android devices meeting Flutter 3.27.2 minimum platform requirements.
