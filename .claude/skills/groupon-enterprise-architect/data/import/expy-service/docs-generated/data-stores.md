---
service: "expy-service"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumExpyMySql"
    type: "mysql"
    purpose: "Primary relational store for Expy service data"
---

# Data Stores

## Overview

Expy Service owns a single primary relational database — `continuumExpyMySql` (MySQL). This database persists all operational data for the service: project registrations, SDK keys, datafile records, feature flag definitions, experiment configurations, audience definitions, access policies, and Quartz job state. An in-memory cache layer (`expyService_cacheLayer`) reduces load on MySQL for frequently read entities such as projects and datafiles.

## Stores

### Expy MySQL (`continuumExpyMySql`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumExpyMySql` |
| Purpose | Primary relational database for all Expy service operational data |
| Ownership | owned |
| Migrations path | > No evidence found in the architecture model — confirm with service owner |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| projects | Stores Optimizely project registrations and metadata | project id, SDK key, name |
| sdk_keys | Maps SDK keys to projects for datafile routing | sdk_key, project_id |
| datafiles | Persists cached copies of Optimizely datafiles per SDK key | sdk_key, datafile content/reference, last_updated |
| features | Feature flag definitions synced from Optimizely | feature_key, project_id, enabled state |
| experiments | Experiment definitions including variation config | experiment_key, project_id, variations |
| audiences | Audience segment definitions | audience_id, conditions |
| access_policies | Access control rules for project/feature access | policy_id, scope |
| quartz_* | Quartz scheduler job and trigger state tables | job_name, trigger_name, next_fire_time |

> Table names are inferred from the service summary and component model. Confirm exact schema with the Optimize team.

#### Access Patterns

- **Read**: Service layer reads projects, SDK keys, and datafiles frequently — served via the in-memory cache layer to minimize DB hits. Feature, experiment, and audience reads are triggered by API requests.
- **Write**: Quartz jobs write updated datafile records and job state on each scheduled execution. API POST/PUT/DELETE operations write feature, experiment, audience, and access-policy mutations.
- **Indexes**: Not directly observable from the architecture model. Expect indexes on `sdk_key`, `project_id`, and `experiment_key` for lookup performance.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `expyService_cacheLayer` | in-memory | Caches projects, datafiles, and Birdcage data to reduce MySQL and external API calls | Not defined in architecture model |

## Data Flows

1. Quartz jobs fetch updated datafiles from the Optimizely CDN and Data Listener via `expyService_externalClients`, then write the new datafile content to `continuumExpyMySql` via `expyService_dataAccessLayer`.
2. The daily S3 copy job reads datafiles from `continuumExpyMySql` (or `optimizelyS3Bucket_84a1`) and writes backup copies to `grouponS3Bucket_7c3d`.
3. API reads for `/datafile/{sdkKey}` are served from the `expyService_cacheLayer`; on cache miss, the data access layer reads from `continuumExpyMySql`.
4. Datafile parse errors are logged to `continuumExpyMySql` for observability and audit.
