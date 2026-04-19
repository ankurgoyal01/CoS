---
service: "leadminer"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "phoneValidationDb"
    type: "json-file"
    purpose: "Phone number validation reference data"
---

# Data Stores

## Overview

Leadminer is substantially stateless. It owns no relational database or cache. All Place and Merchant data is stored in and retrieved from downstream M3 services (Place Read Service, Place Write Service, M3 Merchant Service). The only local data asset is a bundled JSON file used by the `global_phone` library for phone number validation.

## Stores

### Phone Validation Database (`phoneValidationDb`)

| Property | Value |
|----------|-------|
| Type | JSON file (bundled with gem) |
| Architecture ref | `continuumM3LeadminerService` |
| Purpose | Reference data for parsing and validating international phone numbers |
| Ownership | owned (bundled within `global_phone` gem) |
| Migrations path | Not applicable — static reference file |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Phone data (JSON) | Country-level phone number format and validation rules | country code, national prefix, number patterns |

#### Access Patterns

- **Read**: Loaded at startup or on demand by the `global_phone` gem when validating phone number inputs on Place and Merchant edit forms
- **Write**: Not writable at runtime — updated only by gem upgrades
- **Indexes**: Not applicable

## Caches

> No evidence found in codebase.

## Data Flows

All operational Place and Merchant data flows exclusively through downstream REST APIs:

- Place data: read from `continuumPlaceReadService`, written to `continuumPlaceWriteService`
- Merchant data: read and written via `continuumM3MerchantService`
- Input history: read from `continuumInputHistoryService`

Leadminer does not perform any ETL, CDC, or replication of this data locally.
