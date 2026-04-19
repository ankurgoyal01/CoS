---
service: "transporter-jtier"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumTransporterMysqlDatabase"
    type: "mysql"
    purpose: "Stores upload jobs, user records, and Salesforce upload metadata"
  - id: "continuumTransporterRedisCache"
    type: "redis"
    purpose: "Caches Salesforce user OAuth tokens and session data"
---

# Data Stores

## Overview

Transporter JTier owns two data stores: a MySQL database for persistent job and user records, and a Redis cache for Salesforce OAuth token storage. Schema migrations are managed by Flyway via the `jtier-migrations` bundle. AWS S3 and GCS serve as ephemeral file staging areas for CSV input and result files but are not owned data stores.

## Stores

### Transporter MySQL (`continuumTransporterMysqlDatabase`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumTransporterMysqlDatabase` |
| Purpose | Stores upload jobs, user records, and Salesforce upload metadata |
| Ownership | owned |
| Migrations path | Managed via `jtier-migrations` / `flyway-core` (Flyway); database name: `transporter` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Upload jobs | Tracks each bulk upload job submission and execution state | Job ID, status, created timestamp, user reference |
| User records | Persists Salesforce user identity and authorization details | User ID, Salesforce user identifier |
| Upload metadata | Associates upload jobs with Salesforce objects and operation type | Object name, operation (insert/update/delete), file reference |

#### Access Patterns

- **Read**: Upload job status queries by ID; full list queries for `GET /v0/getUploads`; user record lookups for token validation on all authenticated endpoints
- **Write**: Insert on upload submission via `POST /v0/upload`; update on job state transitions driven by the `uploadWorker` Quartz job
- **Indexes**: No evidence found in codebase for specific index definitions (managed by Flyway migrations not present in repo root)

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumTransporterRedisCache` | redis | Caches Salesforce user OAuth access tokens and session data to avoid repeated token exchanges with Salesforce | No evidence found in codebase for explicit TTL configuration |

## Data Flows

1. `transporter-itier` submits a CSV upload — the `uploadOrchestration` component writes the job record to MySQL and stores the input file to AWS S3.
2. The `uploadWorker` Quartz job reads pending job records from MySQL, fetches the CSV from S3, calls Salesforce APIs, and writes result files to GCS.
3. Job state is updated in MySQL as the worker progresses through execution.
4. Salesforce user tokens are written to Redis on authentication (`POST /v0/auth`) and read back on subsequent requests to avoid re-authentication on every call.
