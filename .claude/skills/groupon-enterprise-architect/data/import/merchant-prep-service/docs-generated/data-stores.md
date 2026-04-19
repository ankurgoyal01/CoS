---
service: "merchant-prep-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumMerchantPrepPrimaryDb"
    type: "postgresql"
    purpose: "Primary domain state: onboarding steps, audit log, TIN validation, scheduled jobs"
  - id: "continuumMerchantPrepMecosDb"
    type: "postgresql"
    purpose: "Read-only merchant backend configuration (MECOS)"
---

# Data Stores

## Overview

The Merchant Preparation Service owns two PostgreSQL databases provisioned via the Groupon DaaS (Database-as-a-Service) platform. The primary database (`continuumMerchantPrepPrimaryDb`) holds all merchant prep domain state. The MECOS database (`continuumMerchantPrepMecosDb`) is read-only from the service's perspective and contains merchant backend configuration data. Schema migrations are managed by Flyway via the `jtier-migrations` and `jtier-quartz-postgres-migrations` bundles. All database access uses JDBI 3 DAOs.

## Stores

### Merchant Prep Primary DB (`continuumMerchantPrepPrimaryDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumMerchantPrepPrimaryDb` |
| Purpose | Primary domain state — merchant onboarding workflow tracking, audit entries, TIN validation results, Quartz job tables, payment change state |
| Ownership | owned |
| Migrations path | Flyway migrations managed via `jtier-migrations` bundle; init schema in `.init/init.sql` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `merchant_self_prep.*` (schema) | All merchant prep domain tables live in the `merchant_self_prep` schema | — |
| Account Steps | Tracks which prep steps a merchant account has completed | Salesforce account ID, step name, completion state |
| Opportunity Steps | Tracks prep step completion state per opportunity | Salesforce account ID, opportunity ID, step state |
| Audit Entry | Immutable audit log of all merchant data changes | Salesforce account ID, change type, timestamp, user |
| TIN Validation Result | Stores results of TIN validation attempts | Salesforce account ID, TIN, validation status, timestamp |
| Onboarding Status | Merchant Center onboarding checklist item states | Salesforce account ID, checklist ID, status |
| Onboarding Campaign | Campaign onboarding popup dismissal state | Salesforce account ID, checklist ID |
| Survey Eligible Merchant | Tracks merchants eligible for monthly survey dispatch | Salesforce account ID, eligibility status |
| Beta Program | Beta subscription membership per merchant | Program name, merchant ID, user ID |
| Change Payment | State machine for in-progress payment information change requests | Case ID, payment info, status |
| Last Login | Cached last-login timestamps for merchant users | Salesforce account ID, last login timestamp |
| Navigation Template | Merchant Center navigation templates (device/OS/region-aware) | Template ID, device type, OS, region |

#### Access Patterns

- **Read**: DAOs query by Salesforce account ID or opportunity ID; navigation templates queried by device type, OS, and region combination.
- **Write**: Step completion states updated on merchant action; audit entries appended on each data mutation; TIN validation results inserted after each validation call.
- **Indexes**: Not directly visible in source; standard primary-key and foreign-key indexes implied by DaaS-managed Flyway migrations.

### Merchant Prep MECOS DB (`continuumMerchantPrepMecosDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumMerchantPrepMecosDb` |
| Purpose | Read-only merchant backend configuration data |
| Ownership | shared (MECOS system) |
| Migrations path | Not owned by this service |

#### Key Entities

> No evidence found in codebase of specific table names accessed from MECOS DB. The configuration DAO (`DataSourceConfig`) exposes a separate `mecosDb` data source used by the service for configuration reads.

#### Access Patterns

- **Read**: Service reads merchant backend configuration from MECOS on demand.
- **Write**: Not applicable — this service has read-only access.
- **Indexes**: Not applicable.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| In-process caches | in-memory (JTier `hk2-di-caching`) | Response caching for Salesforce and downstream reads to reduce latency | Configured via `caches` section of JTier YAML config |

## Data Flows

- Merchant prep state written to `continuumMerchantPrepPrimaryDb` synchronously on every successful API mutation.
- MECOS configuration read from `continuumMerchantPrepMecosDb` at request time.
- Audit entries appended to the primary database on each data change event.
- Quartz job state tables in the primary database track scheduled job execution history (last-login sync, monthly survey).
