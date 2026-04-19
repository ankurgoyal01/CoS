---
service: "ios-consumer"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [nsuserdefaults, ios-keychain, fastlane-env, plist]
---

# Configuration

## Overview

The iOS Consumer App is configured through a combination of on-device NSUserDefaults (runtime preferences), the iOS Keychain (credentials), Fastlane environment secrets (CI/CD pipeline), and iOS Info.plist values (static app configuration). There are no server-side environment variables. CI/CD secrets are stored in a `.env.secrets` file in the `fastlane/` directory and are never committed to source control.

## Environment Variables

> Not applicable for runtime — the iOS app does not use server-side environment variables. CI/CD pipeline variables are used by Fastlane during builds.

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `MATCH_USERNAME` | Apple ID for Fastlane Match certificate management | yes | None | `.env.secrets` (fastlane) |
| `MATCH_PASSWORD` | Fastlane Match passphrase | yes | None | `.env.secrets` (fastlane) |
| `FIREBASE_TOKEN` | Firebase CLI token for distribution | yes | None | `.env.secrets` (fastlane) |
| `FASTLANE_USER` | Apple developer account username | yes | None | `.env.secrets` (fastlane) |
| `FASTLANE_PASSWORD` | Apple developer account password | yes | None | `.env.secrets` (fastlane) |
| `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` | App-specific password for Apple ID (CI) | yes | None | `.env.secrets` (fastlane) |
| `GITHUB_API_TOKEN` | GitHub Enterprise API token for mobilebot release branch queries | yes | None | mobilebot environment |
| `ATLASSIAN_API_TOKEN` | Jira API token for GPROD ticket creation | yes | None | mobilebot environment |
| `ATLASSIAN_API_EMAIL` | Jira account email for GPROD ticket creation | yes | None | mobilebot environment |
| `TESTRAIL_TOKEN` | TestRail API token for QA verification reports | yes | None | mobilebot environment |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `useLegacyApp` (NSUserDefaults) | Controls whether app launches in legacy native mode vs MBNXT mode | Not specified | per-user (device) |
| `optOutMbnxt` (NSUserDefaults) | User-initiated opt-out of MBNXT experience | false | per-user (device) |
| `isLocallyBucketedToMbnxt` (NSUserDefaults) | Client-side bucketing assignment to MBNXT | null (unset) | per-user (device) |
| `experimentsOverride` (NSUserDefaults) | Debug override string for experiment assignments | None | per-device (debug only) |
| `SelectedRapiExperimentsKey` (NSUserDefaults) | RAPI experiment selections | None | per-user |
| `sslCertificateCheck` (NSUserDefaults) | Enables/disables SSL certificate pinning | Not specified | per-device |
| `clearImageAndUrlCacheOnStartup` (NSUserDefaults) | Forces image and URL cache clear at launch | false | per-device |
| `simulateNewUserEachStart` (NSUserDefaults) | Debug flag to simulate a new user on each app start | false | per-device (debug only) |
| `proxNotifDebugMode` (NSUserDefaults) | Debug mode for proximity notifications | false | per-device (debug only) |
| `disableNotificationAPICalls` (NSUserDefaults) | Prevents notification API calls (debug) | false | per-device (debug only) |
| `reportScrollingPerformance` (NSUserDefaults) | Reports scrolling performance metrics | false | per-device (debug only) |
| `reportPerformanceMetrics` (NSUserDefaults) | Reports general performance metrics | false | per-device (debug only) |
| `highlightAutoLayoutErrors` (NSUserDefaults) | Highlights Auto Layout constraint errors | false | per-device (debug only) |
| `autoLayoutChimeCatfood` (NSUserDefaults) | Catfood-specific Auto Layout feature | false | per-device (catfood only) |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `fastlane/Matchfile` | Ruby DSL | Code signing certificate storage configuration — references `ios-consumer-development-certificates` git repo; app identifiers: `com.groupon.grouponapp`, `com.groupon.grouponapp.iMessage`, `com.groupon.grouponapp.notificationServiceExtension` |
| `fastlane/.env.secrets` | env | CI/CD secrets for Apple developer account, Firebase, and Match (not committed to source control) |
| iOS `Info.plist` | plist | Static app configuration: bundle ID, version, capabilities |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `MATCH_PASSWORD` | Fastlane Match certificate encryption passphrase | `.env.secrets` (git-ignored) |
| `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` | Apple ID app-specific password for CI automation | `.env.secrets` (git-ignored) |
| `ATLASSIAN_API_TOKEN` | Jira REST API token for change management | mobilebot deployment secrets |
| `TESTRAIL_TOKEN` | TestRail Basic auth token for QA reports | mobilebot deployment secrets |
| `GITHUB_API_TOKEN` | GitHub Enterprise PAT for release branch queries | mobilebot deployment secrets |
| iOS Keychain auth tokens | User authentication credentials (`LEGACY_AUTH_TOKEN_KEY`, `LEGACY_USER_ID_KEY`, `LEGACY_USER_DETAILS_KEY`) | iOS Keychain (on-device) |
| bcookie | Groupon session cookie (`GROUPON_COOKIES_SAVED_BCOOKIE_KEY_V2`) | iOS Keychain (on-device) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

The app ships in three build configurations:

| Environment | Description | Trigger |
|-------------|-------------|---------|
| MBNXT DEV | Development build using `.env` defaults | `nx prebuild mobile-expo` |
| MBNXT Catfood | Internal QA/staging distribution via TestFlight/AppTester | `nx run mobile-expo:release:catfood` |
| MBNXT Production | Public App Store release (v2x legacy, v4x MBNXT) | `nx run mobile-expo:release:prod` |

The `appVersionOverride` NSUserDefaults key allows per-device version override for testing. The `bCookieOverride` and `experimentsOverride` keys provide additional debug overrides.
