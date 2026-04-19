---
service: "android-consumer"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [gradle-properties, build-flavors, build-types]
---

# Configuration

## Overview

The Android Consumer App is configured primarily through `gradle.properties` (433 lines), which defines all dependency versions, API keys, SDK tokens, and build parameters. Build flavors (`groupon`, `livingsocial`) provide brand-level differentiation, and build types (`debug`, `release`, `perfTests`) control signing and optimization. There are no runtime environment variables in the traditional server sense — all configuration is baked into the APK/AAB at build time.

## Environment Variables

> Not applicable for an Android app. All configuration is supplied at build time via `gradle.properties` or build variant resource files. See Config Files section below.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| A/B test flags via `base-abtests` module | Experiment and feature flag evaluation using `GROUPON_ABTESTPROCESSOR_VERSION=1.3.0` | Determined by server-side assignment | per-user |

> Feature flag values are fetched from the backend and cached in `continuumAndroidLocalStorage`. The `base-abtests` module (version 1.3.0) owns the evaluation logic.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `gradle.properties` | properties | Primary build config: 433 lines covering all dependency versions, API keys, SDK tokens, build parameters, and minSdk/targetSdk/compileSdk values |
| `Jenkinsfile` | Groovy DSL | CI/CD pipeline configuration (503 lines); defines build stages, Docker image reference, and Fastlane invocation |
| `google-services.json` | JSON | Firebase project configuration (not committed; provided at CI build time) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `APPROOV_SECRET` | Approov SDK attestation secret for API protection and certificate pinning | `gradle.properties` (build-time injection) |
| `BLOOMREACH_PROJECT_TOKEN_UK` | Bloomreach project token for UK tenant | `gradle.properties` |
| `BLOOMREACH_PROJECT_TOKEN_US` | Bloomreach project token for US tenant | `gradle.properties` |
| `APPSFLYER_DEV_KEY` | AppsFlyer developer key for attribution tracking | `gradle.properties` |
| `RECAPTCHA_KEY` | reCAPTCHA site key for bot protection | `gradle.properties` |
| `MS_CLARITY_PROJECT_ID` | Microsoft Clarity project ID for session recording | `gradle.properties` |
| `GOOGLE_MAPS_API_KEY` | Google Maps Android API key | `gradle.properties` |
| Firebase `google-services.json` credentials | Firebase project and API credentials | Supplied at CI build time via secrets |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Build Flavor | Purpose | Notable Differences |
|---|---|---|
| `groupon` | Main Groupon brand build | Primary package ID `com.groupon`, Groupon API endpoints, Groupon Bloomreach tokens |
| `livingsocial` | LivingSocial brand build | Alternative package ID, LivingSocial-specific API endpoints and branding |

| Build Type | Purpose | Notable Differences |
|---|---|---|
| `debug` | Local development and QA testing | Debug signing, logging enabled, no ProGuard/R8 shrinking |
| `release` | Production Google Play Store distribution | Release signing, R8/ProGuard minification and obfuscation, Approov enabled |
| `perfTests` | Performance testing builds | Configured for performance benchmarks; may disable some obfuscation |

All API keys and SDK tokens are baked into the build artifact at compile time. Rotation requires a new build and release cycle through Google Play Store.
