---
service: "mbus-sigint-configuration-v2"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumMbusSigintConfigurationDatabase"
    type: "postgresql"
    purpose: "Primary persistence for all MBus configuration, request, scheduling, and deployment metadata"
---

# Data Stores

## Overview

The service owns a single PostgreSQL database as its primary data store. All configuration state — clusters, destinations, diverts, credentials, access permissions, redelivery settings, change requests, delete requests, deploy schedules, and GprodConfig — is persisted here. Schema migrations are managed by Flyway via `jtier-migrations`, with 22 versioned migration scripts in `src/main/resources/db/migration/`. The Quartz job scheduler also stores its trigger and job state in this same database.

## Stores

### MBus Sigint Configuration Database (`continuumMbusSigintConfigurationDatabase`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumMbusSigintConfigurationDatabase` |
| Purpose | Stores all cluster topology, change workflow, scheduling, and deployment metadata |
| Ownership | owned |
| Migrations path | `src/main/resources/db/migration/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `cluster` | Represents a named MBus broker cluster | `id` (varchar PK), `name` |
| `request` | Change request record linking a service team's topology change to a lifecycle workflow | `id` (serial PK), `service_name`, `requestor_username`, `requestor_email`, `created_time`, `status` |
| `config_entry` | Tracks individual configuration entries associated with a request | `id` (serial PK), foreign key to `request` |
| `destination` | Queue or topic within a cluster | `id`, `cluster_id`, `config_entry_id`, `name`, `destination_type` (`TOPIC`/`QUEUE`), `confidential` |
| `divert` | Message divert rule (from address to forwarding address) | `id`, `cluster_id`, `config_entry_id`, `from`, `to` |
| `user_credential` | Artemis user credential per cluster and environment | `id`, `cluster_id`, `config_entry_id`, `environment_type`, `role`, `username`, `password` |
| `access_permission` | Defines PRODUCER/CONSUMER access between a role and a destination | `id`, `cluster_id`, `config_entry_id`, `role`, `destination_name`, `access_type`, `environment_type` |
| `environment_config_entry` | Maps a config entry to an environment type (PROD/TEST) | `id`, `config_entry_id`, `environment_type` |
| `redelivery_setting` | Redelivery policy per destination and environment | `id`, `cluster_id`, `config_entry_id`, `destination_id`, `environment_type`, `max_delivery_attempts`, `redelivery_delay`, `redelivery_delay_multiplier`, `max_redelivery_delay`, `dedicated_dlq` |
| `deploy_schedule` | Quartz cron schedule for automated deployments | `cluster_id`, `environment_type` (composite PK), `cron_tab`, `enabled` |
| `gprod_config` | Production change metadata for a cluster used in ProdCat/Jira | `cluster_id` (PK), `impacted_systems`, `data_centers`, `regions` |
| `delete_request` | Records a request to delete configuration entries | `id`, `requestor_*`, `created_time`, `status`, `jira_ticket` |
| `delete_request_config_entry` | Maps a delete request to specific config entry IDs | `delete_request_id`, `config_entry_id` |

#### Access Patterns

- **Read**: Domain services and API resources query configuration by `cluster_id` and `environment_type` for rendering deployment configuration and satisfying GET requests. The Quartz `DeployConfigJob` reads scheduled deployments on trigger.
- **Write**: Change-request creation inserts into `request`, `config_entry`, `destination`, `divert`, `user_credential`, `access_permission`, and `redelivery_setting` atomically. State transitions update `request.status` and `config_entry` entries through the workflow lifecycle.
- **Indexes**: Unique constraints on `destination(name, cluster_id)` and `user_credential(cluster_id, environment_type, username)` enforce configuration uniqueness per cluster.

## Caches

> No evidence found in codebase. No in-memory or external cache (Redis, Memcached) is configured.

## Data Flows

All writes originate from API requests (change-request creation, approval actions, admin deploys) or Quartz job state updates. No CDC, ETL, or replication patterns are in use. Schema migrations run automatically at service startup via Flyway (jtier-migrations). Quartz job/trigger state is co-located in the same PostgreSQL database using the `jtier-quartz-postgres-migrations` schema.
