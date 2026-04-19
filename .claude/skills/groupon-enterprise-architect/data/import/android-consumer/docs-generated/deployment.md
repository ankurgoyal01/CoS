---
service: "android-consumer"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "google-play-store"
environments: [debug, release, perfTests]
---

# Deployment

## Overview

The Android Consumer App is built inside Docker CI containers and distributed as an Android App Bundle (AAB) to the Google Play Store. There is no server-side orchestration (no Kubernetes or ECS). CI/CD runs on Jenkins (Conveyor CI) using a 503-line Jenkinsfile. Fastlane manages the Play Store upload. Releases use a gradual rollout strategy: beta channel, then staged percentage rollout, then 100% production.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `android_build_consumer` base image used for CI builds |
| Orchestration | Google Play Store | Gradual rollout (beta → staged → 100%) |
| Load balancer | Not applicable | Mobile app; no server load balancer |
| CDN | Not applicable | Distributed via Google Play Store |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| debug | Local development and QA testing | Device / emulator | Sideloaded APK |
| release | Production distribution to all users | Global | Google Play Store (`com.groupon`) |
| perfTests | Performance benchmark builds | CI / device lab | Internal distribution |
| Beta channel | Early access / staged testing | Google Play Beta | Google Play Store (beta) |

## CI/CD Pipeline

- **Tool**: Jenkins (Conveyor CI)
- **Config**: `Jenkinsfile` (503 lines)
- **Trigger**: On pull request, on merge to main branch, and manual dispatch

### Pipeline Stages

1. **Docker Build Environment**: Spin up `android_build_consumer` Docker container with Android SDK and Java 8+ pre-installed
2. **Dependency Resolution**: Gradle resolves and caches all dependencies from `gradle.properties`
3. **Code Compilation**: `./gradlew assembleRelease` / `./gradlew bundleRelease` compiles Kotlin/Java across all 40+ modules
4. **Unit Tests**: Execute unit test suites across feature modules
5. **Code Quality / Lint**: Android Lint and static analysis checks
6. **APK Assembly**: Build debug APK for QA sideloading and verification
7. **AAB Bundle**: Build release AAB for Play Store submission
8. **Signing**: Sign AAB with release keystore (credentials in CI secrets)
9. **Play Store Upload**: Fastlane `supply` uploads AAB to Google Play Console
10. **Gradual Rollout**: Release promoted from internal → beta → staged percentage → 100% production

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Not applicable — mobile app | — |
| Memory | Android OS managed per app process | Android OS default limits |
| CPU | Android OS managed per app process | Android OS default limits |

> Mobile apps do not have server-side scaling. The Google Play Store handles distribution infrastructure.

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CI Build RAM | > No evidence found in codebase | — |
| CI Build CPU | > No evidence found in codebase | — |
| APK size | Minimised via R8/ProGuard in release builds | Google Play 150 MB APK limit (AAB bypasses via Play Asset Delivery) |
