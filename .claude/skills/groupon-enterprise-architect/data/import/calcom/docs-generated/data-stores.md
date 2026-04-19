---
service: "calcom"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumCalcomPostgres"
    type: "postgresql"
    purpose: "Scheduling, account, configuration, and workflow state data"
---

# Data Stores

## Overview

Calcom uses a single GDS-managed PostgreSQL database as its primary and only data store. Both the web/API service (`continuumCalcomService`) and the background worker (`continuumCalcomWorkerService`) read from and write to the same database. The database is hosted on AWS in the us-west-1 region in a multi-tenant configuration managed by Groupon's GDS (Global Data Services) team. No cache layer is deployed at the Groupon level.

## Stores

### Cal.com PostgreSQL (`continuumCalcomPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumCalcomPostgres` |
| Purpose | Stores all scheduling, user account, configuration, and background job/workflow state data |
| Ownership | shared (multi-tenant GDS-managed) |
| Migrations path | Managed by upstream Cal.com (Prisma migrations inside the Docker image) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `users` | User accounts and roles | `id`, `email`, `role` (e.g., `ADMIN`), `password`, `twoFactorEnabled` |
| Bookings | Meeting/appointment records | Booking details, attendees, time slots |
| Event types | Configurable event/meeting types per user | Duration, slug, availability rules |
| Availability | User availability schedules | Time ranges, days of week |
| Workflows | Background job and reminder workflow definitions | Trigger rules, steps, state |

> Specific table schema is defined by the upstream Cal.com Prisma schema. Groupon does not own or extend the schema.

#### Environment Databases

| Environment | Database Name | Host | AWS Account | AWS Region |
|-------------|--------------|------|-------------|------------|
| Staging | `calcom_stg` | `pg-noncore-emea-561-stg` | grpn-stable | us-west-1 |
| Production | `calcom_prod` | `pg-noncore-us-057-prod` | grpn-prod | us-west-1 |

#### Access Patterns

- **Read**: The Scheduling API reads user availability, event type definitions, and booking records to render pages and validate new booking requests. The Worker reads pending workflow jobs and reminder schedules.
- **Write**: The Scheduling API writes new booking records and updates booking state. The Worker writes workflow execution state and job completion records.
- **Indexes**: Managed by upstream Cal.com Prisma schema.

## Caches

> No evidence found in codebase. No external cache (Redis, Memcached) is configured at the Groupon deployment layer.

## Data Flows

Scheduling data flows in a single direction: the `continuumCalcomService` writes new bookings and queues background jobs, while `continuumCalcomWorkerService` reads pending jobs and updates workflow state. Both containers share the same PostgreSQL database instance. There is no CDC, ETL pipeline, or replication to downstream systems configured at the Groupon level.

Database backups and recovery are managed by the GDS team. For recovery requests, contact the GDS team via the [#gds-daas](https://chat.google.com/room/AAAAIGlgIi0?cls=7) Gchat channel. For production issues, use the [#production](https://chat.google.com/room/AAAAOTeTjHg?cls=7) channel.
