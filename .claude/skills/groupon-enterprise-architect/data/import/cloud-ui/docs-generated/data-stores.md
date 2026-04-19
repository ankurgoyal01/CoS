---
service: "cloud-ui"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumCloudBackendPostgres"
    type: "postgresql"
    purpose: "Primary persistent store for applications, organizations, deployments, and sync state"
---

# Data Stores

## Overview

The Cloud Backend API owns a single PostgreSQL database (`cloud_backend`) managed via Encore's `sqldb` package. The database holds all persistent state for organizations, applications, deployments, and Git sync locks. Schema is managed through versioned SQL migrations in `cloud-backend/api/migrations/`. An in-memory Helm chart index cache and a filesystem-based Helm chart file cache are used as ephemeral performance caches — they hold no authoritative data.

## Stores

### Cloud Backend PostgreSQL (`continuumCloudBackendPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumCloudBackendPostgres` |
| Purpose | Primary persistent store for all Cloud UI state: organizations, applications, deployments, Git sync locks, and Jenkins tracking metadata |
| Ownership | owned |
| Migrations path | `cloud-backend/api/migrations/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `organizations` | Represents a team or GitHub-aligned group that owns applications | `id` (PK, DNS name), `name`, `display_name`, `description`, `created_at`, `updated_at` |
| `applications` | Stores application definitions with full configuration as JSONB | `id` (PK, = name), `name`, `organization_id` (FK), `image`, `port`, `workload_type`, `environment` (JSONB), `labels` (JSONB), `config` (JSONB — HPA/PDB/resources/probes/storage/components/environmentComponents), `main_repo_url`, `secrets_repo_url`, `sync_in_progress`, `sync_started_at` |
| `deployments` | Tracks each deployment lifecycle from creation through GitOps stages | `id` (PK, composite timestamp), `application_id` (FK), `image`, `strategy`, `status`, `phase`, `git_commit_hash`, `jenkins_build_number`, `jenkins_build_url`, `jenkins_last_checked_at`, `environment` (JSONB), `labels` (JSONB) |

#### Access Patterns

- **Read**: Applications are fetched by ID or listed with optional `organization_id` filter and `LIMIT/OFFSET` pagination ordered by `created_at DESC`. Deployments are listed by `application_id` ordered by `created_at DESC`. Deployment status queries fetch by `id` only.
- **Write**: Applications are inserted on creation; updated on configuration change via `UPDATE ... WHERE id = $1`. Deployments are inserted on creation and updated in place to advance phase/status fields and Jenkins metadata. Sync lock state (`sync_in_progress`, `sync_started_at`) is toggled on applications during GitOps sync.
- **Indexes**: `idx_applications_name`, `idx_applications_created_at`, `idx_applications_workload_type`, `idx_applications_config` (GIN on JSONB), `idx_applications_organization_id`, `idx_applications_sync_in_progress` (partial, WHERE TRUE), `idx_deployments_application_id`, `idx_deployments_status`, `idx_deployments_phase`, `idx_deployments_git_commit_hash`

#### Schema Migrations

| Migration | Description |
|-----------|-------------|
| `1_unified_schema.up.sql` | Creates `applications` and `deployments` tables with triggers |
| `2_add_organizations.up.sql` | Creates `organizations` table; adds `organization_id` FK to `applications` |
| `3_remove_template_column.up.sql` | Removes legacy template column |
| `4_add_git_urls.up.sql` | Adds `main_repo_url` and `secrets_repo_url` to `applications` |
| `5_add_deployment_phases.up.sql` | Adds `phase`, `git_commit_hash`, Jenkins tracking columns to `deployments` |
| `6_add_sync_lock.up.sql` | Adds `sync_in_progress` and `sync_started_at` to `applications` for concurrent sync prevention |

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Helm index cache | in-memory (`IndexCacheManager`) | Caches Artifactory Helm repository index to avoid repeated HTTP fetches | 6 hours |
| Helm chart cache | filesystem (`/tmp/helm-chart-cache`) | Caches downloaded `.tgz` chart archives to avoid repeated Artifactory downloads | 24 hours |
| Helm SDK cache | filesystem (`/tmp/helm-cache`, `/tmp/helm-repositories.yaml`) | Helm SDK working files; cleared by the `POST /cloud-backend/helm/clear-cache` endpoint | No explicit TTL |

## Data Flows

All authoritative state resides in PostgreSQL. The Helm caches are write-through: on a cache miss, the system downloads from Artifactory and stores locally; subsequent requests are served from cache until TTL expiry or explicit cache clear. The `config` JSONB column on `applications` holds the full component configuration tree (autoscaling, resources, probes, environment-specific component arrays), eliminating the need for additional normalized tables for configuration data.
