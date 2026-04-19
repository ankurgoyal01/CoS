---
service: "client-id"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumClientIdDatabase"
    type: "mysql"
    purpose: "Primary read-write datastore for all client-id domain entities"
  - id: "continuumClientIdReadReplica"
    type: "mysql"
    purpose: "Read replica for high-volume query paths"
---

# Data Stores

## Overview

Client ID Service owns two MySQL datastores: a primary read-write instance and a read replica. All writes go to the primary. High-volume read paths (API Proxy token sync, client search) are directed to the read replica. In production the service connects via GDS-managed Cloud SQL (GCP US) and RDS (AWS EU) endpoints. Database replication is managed externally by GDS across all regions.

## Stores

### Client ID MySQL — Primary (`continuumClientIdDatabase`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumClientIdDatabase` |
| Purpose | Primary read-write store for all client-id domain entities |
| Ownership | owned |
| Migrations path | `src/main/resources/db/` (managed by jtier-daas conventions) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `api_clients` | API client records — identity, type, role, suspended status, owner | `id`, `user_id`, `role`, `client_type`, `suspended`, `created_at`, `updated_at` |
| `api_tokens` | Access tokens belonging to clients — value, rate limits, status, version | `id`, `api_client_id`, `value`, `client_rate_limit`, `ip_rate_limit`, `status`, `redirect_host`, `version_number`, `updated_at` |
| `api_services` | Named API services that tokens can be mapped to | `id`, `name`, `description` |
| `api_service_tokens` | Junction table mapping tokens to services with per-service rate limits | `id`, `api_client_id`, `api_token_id`, `service_name`, `client_rate_limit`, `ip_rate_limit`, `status`, `updated_at` |
| `mobiles` | Mobile app version metadata associated with clients | `id`, `api_client_id`, `platform`, `mobile_role`, `country_code`, `download_url`, `force_update_at`, `suggest_update_at`, `upgrade_throttle` |
| `schedules` | Scheduled temporary rate-limit changes | `id`, `token`, `service_name`, `start_time`, `end_time`, `temp_client_limit`, `temp_ip_limit`, `original_client_limit`, `original_ip_limit`, `status`, `started`, `user`, `description` |
| `recaptcha_configurations` | Per-client reCAPTCHA site key and default threshold configuration | `id`, `api_client_id`, `site_key`, `default_threshold`, `region`, `suspended`, `updated_at` |
| `recaptcha_thresholds` | Per-client, per-action reCAPTCHA score thresholds | `id`, `api_client_id`, `action`, `threshold`, `required`, `required_since_version`, `headers_bypass`, `region`, `updated_at` |
| `users` | Internal admin user records for the management UI | `id`, `email_address`, `permalink`, `pager_address`, `status` |

#### Access Patterns

- **Read**: Point lookups by client ID, token value, email address, role, and `updated_at` timestamp; join queries combining clients + tokens + services
- **Write**: Insert and update for all entity types; schedule start/revert updates rate-limit columns on `api_service_tokens`
- **Indexes**: `updated_at` columns are used for incremental sync (`WHERE updated_at > :updatedAt`); `api_client_id` foreign keys indexed for join performance

### Client ID MySQL — Read Replica (`continuumClientIdReadReplica`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumClientIdReadReplica` |
| Purpose | Read-replica for high-volume query paths (API Proxy sync, search) |
| Ownership | owned |
| Migrations path | Not applicable — read-only replica |

#### Access Patterns

- **Read**: Same query patterns as primary (search by token value, email, role, `updated_at`; `/v3/services/{serviceName}` sync)
- **Write**: Not applicable — replica receives replication stream only
- **Connection pool size**: 30 (production), compared to 5 for the primary write connection pool

## Caches

> No evidence found in codebase. Client ID Service does not use Redis, Memcached, or any in-memory caching layer.

## Data Flows

Database replication topology (all replication managed by GDS):

| Instance | Role | Replication Source |
|----------|------|--------------------|
| `prod-us-west-1` (GCP) | Primary | None (canonical primary) |
| `prod-us-central1` (GCP) | Replica | `prod-us-west-1` |
| `prod-eu-west-1` (AWS) | Replica | `prod-us-west-1` |
| `staging-us-west-1` (GCP) | Staging primary | `prod-us-west-1` |
| `staging-us-west-2` (AWS) | Staging replica | `staging-us-west-1` |
| `staging-europe-west1` (GCP) | Staging replica | `staging-us-west-1` |
| `staging-us-central1` (GCP) | Staging replica | `staging-us-west-1` |

Production connection endpoints (from `src/main/resources/config/cloud/production-us-central1.yml`):

- **Primary (NA)**: `client-id-rw-na-production-db.gds.prod.gcp.groupondev.com` — database `client_id_production`
- **Read replica (NA)**: `client-id-ro-na-production-db.gds.prod.gcp.groupondev.com` — database `client_id_production`
