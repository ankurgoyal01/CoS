---
service: "mobile-flutter-merchant"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "localSqliteDrift"
    type: "sqlite"
    purpose: "Offline-capable local data persistence for merchant deals, vouchers, and redemption records"
  - id: "sembastStore"
    type: "nosql-embedded"
    purpose: "Lightweight local NoSQL store for app state and ephemeral merchant data"
  - id: "sharedPrefsKeychain"
    type: "key-value"
    purpose: "Secure credential and preference storage (auth tokens, settings)"
---

# Data Stores

## Overview

The Mobile Flutter Merchant app maintains three local data stores on the device. The primary persistent store is a SQLite database accessed through the Drift ORM, used for offline-capable merchant data. A secondary embedded NoSQL store (Sembast) handles lightweight local state. Secure credentials and preferences are stored in platform-native secure storage (SharedPreferences on Android, Keychain on iOS). All canonical merchant data is sourced from Continuum backend services; the local stores serve as a read-through cache and offline buffer.

## Stores

### Local SQLite / Drift (`localSqliteDrift`)

| Property | Value |
|----------|-------|
| Type | sqlite |
| Architecture ref | `continuumMobileFlutterMerchantApp` |
| Purpose | Offline-capable local persistence for merchant deals, vouchers, redemption records, and payment data |
| Ownership | owned (on-device) |
| Migrations path | Managed by Drift ORM migration system within the app source |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Deals | Stores cached deal records for offline browse | deal id, status, title, start/end dates |
| Vouchers | Cached voucher/redemption records for offline lookup | voucher code, status, merchant id, expiry |
| Payments | Cached payment schedule entries | payment id, amount, schedule date, status |
| Redemptions | Local record of processed redemptions | redemption id, voucher code, timestamp, result |

#### Access Patterns

- **Read**: App reads cached records during offline mode or before remote data loads; Drift generates type-safe SQL queries
- **Write**: Records are written after successful API responses to keep the local cache consistent; redemption results are written immediately on processing
- **Indexes**: Drift ORM manages indexes; specific index definitions are internal to the generated schema

---

### Sembast Embedded Store (`sembastStore`)

| Property | Value |
|----------|-------|
| Type | nosql-embedded |
| Architecture ref | `continuumMobileFlutterMerchantApp` |
| Purpose | Lightweight local NoSQL store for ephemeral app state and structured non-relational data |
| Ownership | owned (on-device) |
| Migrations path | Schema-less; Sembast handles versioning via store records |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| App state records | Stores UI state and transient feature data | store key, value blob |

#### Access Patterns

- **Read**: Key-value lookups for UI state rehydration on app start
- **Write**: State writes triggered by Redux actions and feature module transitions
- **Indexes**: Key-based access; no secondary indexes

---

### Secure Preferences / Keychain (`sharedPrefsKeychain`)

| Property | Value |
|----------|-------|
| Type | key-value |
| Architecture ref | `continuumMobileFlutterMerchantApp` |
| Purpose | Secure storage of authentication tokens and user preferences |
| Ownership | owned (on-device, platform-native) |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Auth token | Session token from Google OAuth / Okta | token key, expiry |
| User preferences | App settings and notification preferences | preference keys |

#### Access Patterns

- **Read**: Token retrieved by `mmaAuthenticationModule` on app start and before each API call
- **Write**: Token written after successful OAuth login; preferences written on user settings changes
- **Indexes**: Single-key lookup only

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Drift SQLite local cache | in-memory + on-disk | Caches remote API responses for offline access | Until next successful sync or app reinstall |
| Sembast state cache | in-memory + on-disk | Ephemeral app state between sessions | Until explicitly cleared |

## Data Flows

Remote data is fetched by `mmaApiOrchestrator` from Continuum backend services (deals from `continuumDealManagementApi`, vouchers/dashboard from `continuumUniversalMerchantApi`, payments from `continuumPaymentsService`). Successful responses are persisted to the Drift SQLite store. On app launch or when offline, the app reads from the local SQLite store. Redemption events are written locally before or after confirmation from `continuumUniversalMerchantApi` to support offline-first processing. Auth tokens flow from `googleOAuth` / Okta through `mmaAuthenticationModule` to platform-secure storage.
