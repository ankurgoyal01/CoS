---
service: "ios-consumer"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "nsuserdefaults"
    type: "key-value (NSUserDefaults / iOS Settings)"
    purpose: "User preferences, location state, feature flags, experiment overrides"
  - id: "ios-keychain"
    type: "secure-store (iOS Keychain)"
    purpose: "Auth tokens, bcookie, user credentials"
---

# Data Stores

## Overview

The iOS Consumer App is a mobile client that manages local on-device state. It uses two on-device storage mechanisms: NSUserDefaults (via iOS Settings API) for user preferences and lightweight state, and the iOS Keychain for sensitive credentials. There is no server-side database owned by this application.

## Stores

### NSUserDefaults / iOS Settings (`nsuserdefaults`)

| Property | Value |
|----------|-------|
| Type | key-value (NSUserDefaults / iOS Settings API) |
| Architecture ref | `continuumIosConsumerApp` |
| Purpose | User preferences, location/division selection, feature flags, experiment overrides, onboarding state, push consent |
| Ownership | owned (on-device) |
| Migrations path | Not applicable — managed by iOS OS-level Settings framework |

#### Key Entities

| Entity / Key | Purpose | Key Fields |
|--------------|---------|-----------|
| `country` | User's selected country context | string (mapped from legacy to MBNXT country code) |
| `userDivisionId`, `userDivisionName`, `userDivisionCity` | User's selected deal division/location | string |
| `pushNotificationsEnabled` | User consent for push notifications | string |
| `lastPushContractVersion` | Version of push permission contract shown | string |
| `didSuccessfullyPostDeviceToken` | Device token registration status | boolean |
| `launchCount` | Number of app launches (incremented in legacy app) | integer |
| `isOnboardingFinished`, `didFinishOnboarding` | Onboarding completion state | boolean |
| `useLegacyApp` | Whether to use legacy native app vs MBNXT | boolean |
| `optOutMbnxt` | Whether user has opted out of MBNXT | boolean |
| `isLocallyBucketedToMbnxt` | Client-side MBNXT bucketing state | boolean |
| `experimentsOverride` | Debug experiment override string | string |
| `SelectedRapiExperimentsKey` | RAPI experiment selections | object |
| `kUserDefaultsMyCLOLocalStoreKey` | CLO local store data | object |
| `locationAuthorizationStatus` | Location permission status | integer |
| `GROUPON_COOKIES_SAVED_BCOOKIE_KEY_V2` | Bcookie value (also stored in Keychain) | string |
| `bCookieOverride` | Debug bcookie override | string |
| `appVersionOverride` | Debug app version override | string |

#### Access Patterns

- **Read**: MBNXT mobile shell (`next-pwa-app`) reads these values via the `LegacyDataStore` bridge using `Platform.OS === 'ios'` guard and `Settings.get(key)`
- **Write**: Native iOS app writes via `NSUserDefaults` (Objective-C `GPUserPrefsMapping`); MBNXT writes via `Settings.set(values)`
- **Indexes**: Not applicable — key-value store

### iOS Keychain (`ios-keychain`)

| Property | Value |
|----------|-------|
| Type | secure-store (iOS Keychain + `rn-keychain` bridge) |
| Architecture ref | `continuumIosConsumerApp` |
| Purpose | Secure storage of auth tokens, bcookie, user identity credentials |
| Ownership | owned (on-device) |
| Migrations path | Not applicable — managed by iOS Keychain framework |

#### Key Entities

| Entity / Key | Purpose | Key Fields |
|--------------|---------|-----------|
| `LEGACY_AUTH_TOKEN_KEY` | Authentication token dictionary (plist) | plist dictionary |
| `LEGACY_USER_ID_KEY` | User identity dictionary (plist) | plist dictionary |
| `LEGACY_USER_DETAILS_KEY` | User details dictionary (plist) | plist dictionary |
| bcookie | Session bcookie for Groupon API authentication | string |

#### Access Patterns

- **Read**: MBNXT reads auth state via `RNKeychain.getPlistForKey()` and `RNKeychain.getBCookie()`
- **Write**: App writes via `RNKeychain.setPlist()` and `RNKeychain.setBCookie()`

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Image cache | in-memory / disk (iOS URL cache) | Cached deal images and URLs; cleared on startup via `clearImageAndUrlCacheOnStartup` flag | Not specified |

## Data Flows

User preferences and credentials written by the legacy iOS app are read by the MBNXT mobile shell at startup to determine bucketing state, authentication, location context, and whether to display the legacy or MBNXT experience. This constitutes a one-way data bridge from the legacy app's NSUserDefaults and Keychain to the MBNXT React Native layer via the `LegacyDataStore` bridge module.
