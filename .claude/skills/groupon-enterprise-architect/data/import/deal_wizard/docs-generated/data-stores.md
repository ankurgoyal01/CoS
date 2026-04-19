---
service: "deal_wizard"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "dealWizardMysql"
    type: "mysql"
    purpose: "Primary relational store for deal templates, questions, locales, and fine prints"
  - id: "dealWizardRedisCache_8a31"
    type: "redis"
    purpose: "Session cache and feature flag storage"
  - id: "salesForce"
    type: "external-crm"
    purpose: "System of record for Salesforce Opportunities and Accounts"
---

# Data Stores

## Overview

Deal Wizard maintains a MySQL relational database as its primary owned data store, holding the configuration data that drives wizard flows (templates, questions, locales, fine prints). Redis is used for session caching and locale feature flags. Salesforce acts as an external system of record for all deal and merchant CRM data; the service reads Opportunities and Accounts from Salesforce and persists completed deals back to it.

## Stores

### MySQL (`dealWizardMysql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumDealWizardWebApp` (owned by container) |
| Purpose | Stores deal templates, wizard question definitions, locale configurations, and fine print content |
| Ownership | owned |
| Migrations path | `db/migrate/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `deal_templates` | Reusable deal structure templates applied during wizard creation | id, name, locale, structure |
| `questions` | Wizard step question definitions and validation rules | id, step, text, type, required |
| `locales` | Locale and region configuration for deal fine prints and pricing | id, code, region, currency |
| `fine_prints` | Legal and merchant fine print content by locale and deal type | id, locale_id, content, category |
| `delayed_jobs` | `delayed_job` background job queue (MySQL-backed) | id, handler, run_at, failed_at, last_error |

#### Access Patterns

- **Read**: Wizard UI reads templates, questions, locales, and fine prints at each wizard step; lookups are primarily by locale and deal type
- **Write**: Admin configuration changes update templates, questions, and fine prints; delayed_job enqueues and dequeues background Salesforce tasks
- **Indexes**: Expected indexes on `locale_id`, `deal_template_id`, and `delayed_jobs.run_at` for performance

### Redis (`dealWizardRedisCache_8a31`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `redisCache` component within `continuumDealWizardWebApp` |
| Purpose | Session cache for authenticated sales user sessions; locale feature flag reads |
| Ownership | shared (Groupon Redis cluster) |
| Migrations path | Not applicable |

#### Key Entities

> No evidence found for specific Redis key schema documentation.

#### Access Patterns

- **Read**: Session lookup on every authenticated request; locale flag checks during wizard rendering
- **Write**: Session write on user login (Salesforce OAuth callback); flag writes via admin tooling
- **Indexes**: Key-based access only

### Salesforce (`salesForce`)

| Property | Value |
|----------|-------|
| Type | external-crm |
| Architecture ref | `salesForce` (external stub in `continuumSystem`) |
| Purpose | System of record for Salesforce Opportunities, Accounts, and deal submission status |
| Ownership | external |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `Opportunity` | Salesforce Opportunity linked to a deal wizard session | Id, Name, StageName, AccountId, DealWizardStatus |
| `Account` | Merchant/account record associated with a deal | Id, Name, BillingAddress, OwnerId |

#### Access Patterns

- **Read**: Fetches Opportunity and Account data during deal creation wizard steps; reads deal status for the monitoring endpoint
- **Write**: Persists completed deal data back to Salesforce Opportunities via `POST /api/v1/create_salesforce_deal`

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `dealWizardRedisCache_8a31` | redis | User session state and locale feature flags | Session-based; TTL managed by Rails session configuration |

## Data Flows

- MySQL is read heavily during wizard step rendering and written during background Salesforce job processing (delayed_job)
- Redis session store is read on every authenticated request and written on OAuth login
- Salesforce data flows in both directions: Opportunity/Account data is pulled into the wizard UI at deal creation time, and completed deal data is pushed back to Salesforce on submission
