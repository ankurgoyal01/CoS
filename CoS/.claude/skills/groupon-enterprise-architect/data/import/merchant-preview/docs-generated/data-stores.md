---
service: "merchant-preview"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumMerchantPreviewDatabase"
    type: "mysql"
    purpose: "Primary relational datastore for preview comments, feature records, and workflow state"
---

# Data Stores

## Overview

Merchant Preview owns a single MySQL database as its primary data store. This database holds all preview comments, feature flags/records, and workflow state for the review and approval process. Both the web service (`continuumMerchantPreviewService`) and the cron worker (`continuumMerchantPreviewCronWorker`) access this database directly.

## Stores

### Merchant Preview Database (`continuumMerchantPreviewDatabase`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumMerchantPreviewDatabase` |
| Purpose | Primary relational datastore for preview comments, feature records, and workflow state |
| Ownership | owned |
| Migrations path | > No evidence found in codebase |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| comments | Stores merchant and account manager comments on deal creative | deal_id, author, body, status (open/resolved), created_at |
| feature_records | Tracks deal feature state and preview configuration | deal_id, feature_type, state |
| workflow_state | Tracks approval/rejection status per deal | deal_id, status (pending/approved/rejected), updated_at |

> Specific table names and fields above are inferred from component responsibilities in the architecture model. Exact schema must be verified against database migrations.

#### Access Patterns

- **Read**: `continuumMerchantPreviewService` reads comments and workflow state when rendering preview pages. `continuumMerchantPreviewCronWorker` reads unresolved comments and workflow records on a scheduled basis.
- **Write**: `continuumMerchantPreviewService` writes new comments and updates approval/rejection state when users take actions. `continuumMerchantPreviewCronWorker` may update sync timestamps and status flags after Salesforce sync.
- **Indexes**: > No evidence found in codebase for specific index definitions.

## Caches

> No evidence found in codebase for cache usage. No Redis, Memcached, or in-memory cache is referenced in the architecture model.

## Data Flows

- Preview comment and workflow state originate in `continuumMerchantPreviewDatabase`.
- The cron worker reads unresolved records from the database and pushes updates to `salesForce`.
- Deal creative content is not stored locally; it is fetched on demand from `continuumDealCatalogService` and rendered dynamically.
