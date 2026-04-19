---
service: "optimus-prime-api"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumOptimusPrimeApiDb"
    type: "postgresql"
    purpose: "Operational state for users, groups, connections, jobs, and run history"
  - id: "continuumOptimusPrimeGcsBucket"
    type: "gcs"
    purpose: "File ingress and egress for ETL workflows"
  - id: "continuumOptimusPrimeS3Storage"
    type: "s3"
    purpose: "File storage for ETL job steps"
---

# Data Stores

## Overview

Optimus Prime API owns three data stores: a PostgreSQL database for all operational state (job definitions, run records, users, groups, and encrypted connection credentials), a Google Cloud Storage bucket for file ingress/egress, and an Amazon S3 bucket for job step file storage. The PostgreSQL database is the primary store and is managed via Flyway schema migrations. The cloud storage buckets are used exclusively for ETL file movement.

## Stores

### Optimus Prime Postgres DB (`continuumOptimusPrimeApiDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumOptimusPrimeApiDb` |
| Purpose | Operational relational datastore for all application state: users, groups, connections, job definitions, run records, run history, and archived runs |
| Ownership | owned |
| Migrations path | Managed by Flyway via `jtier-migrations`; migration files are part of the service artifact |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `users` | User accounts resolved from Active Directory | username, email, status (active/disabled) |
| `groups` | User group memberships | group name, members |
| `connections` | Data source connection configurations with encrypted credentials | connection id, type, username, encrypted credentials |
| `jobs` | ETL job definitions including schedule, NiFi template reference, and source/target config | job id, owner username, schedule cron, status, NiFi process group id |
| `runs` | Active and recent job run records | run id, job id, start time, end time, status |
| `history` | Long-term job run history | run id, job id, outcome, timestamps |
| `archived_runs` | Runs moved from active table by archival Quartz job | run id, job id, archived timestamp |

#### Access Patterns

- **Read**: `opApi_persistenceLayer` (JDBI DAOs) reads job configurations on every scheduled trigger, run status queries, and user/group lookups
- **Write**: `opApi_persistenceLayer` writes job definitions on create/update, persists run records on job start/completion, archives old runs via scheduled Quartz jobs
- **Indexes**: No evidence found in codebase. Indexes on `job_id`, `username`, and run timestamps are expected for query performance.

### Optimus Prime GCS Bucket (`continuumOptimusPrimeGcsBucket`)

| Property | Value |
|----------|-------|
| Type | gcs |
| Architecture ref | `continuumOptimusPrimeGcsBucket` |
| Purpose | Cloud Storage bucket for ETL file ingestion (input files for NiFi flows) and export (output files from completed ETL runs) |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Job input files | Files staged for ingestion into ETL pipelines | blob path, job id, upload timestamp |
| Job output files | Files produced by completed ETL job runs | blob path, job id, run id |

#### Access Patterns

- **Read**: `storageAdapter` reads files from the GCS bucket as part of ETL workflow execution
- **Write**: `storageAdapter` writes output files to the GCS bucket on job completion or at configured export steps

### Optimus Prime S3 Storage (`continuumOptimusPrimeS3Storage`)

| Property | Value |
|----------|-------|
| Type | s3 |
| Architecture ref | `continuumOptimusPrimeS3Storage` |
| Purpose | S3 buckets used by specific Optimus Prime job steps requiring AWS-native storage |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Job step files | Files consumed or produced by S3-based ETL job steps | S3 key, bucket name, job id |

#### Access Patterns

- **Read**: `storageAdapter` reads S3 objects as input for configured job steps
- **Write**: `storageAdapter` writes S3 objects as output for configured job steps

## Caches

> No evidence found in codebase. No Redis, Memcached, or explicit in-memory cache layer is defined in the architecture model beyond standard JDBI connection pooling.

## Data Flows

On each job run, `orchestrationEngine` reads the job configuration from `continuumOptimusPrimeApiDb`, instructs `nifiIntegration` to start or update the NiFi process group, and then writes run status updates back to `continuumOptimusPrimeApiDb`. File-based ETL steps move data to/from `continuumOptimusPrimeGcsBucket` or `continuumOptimusPrimeS3Storage` via `storageAdapter`. Archived run records are periodically moved from the active `runs` table to `archived_runs` by a scheduled Quartz archival job, keeping the hot tables lean.
