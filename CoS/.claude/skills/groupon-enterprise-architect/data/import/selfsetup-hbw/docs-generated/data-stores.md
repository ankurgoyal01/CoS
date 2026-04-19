---
service: "selfsetup-hbw"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumSsuDatabase"
    type: "mysql"
    purpose: "Stores merchant self-setup configuration state and cron job queue"
---

# Data Stores

## Overview

selfsetup-hbw owns a single MySQL database (`continuumSsuDatabase`) which persists in-progress and completed self-setup configuration for merchants. The database also supports the cron job infrastructure for scheduling reminder emails and DWH reconciliation tasks. Salesforce is the authoritative system of record for merchant opportunity and account data; the MySQL store holds SSU-specific operational state only.

## Stores

### SSU HBW Database (`continuumSsuDatabase`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumSsuDatabase` |
| Purpose | Stores merchant self-setup configuration, wizard progress state, and cron job queue entries |
| Ownership | owned |
| Migrations path | > No evidence found of a migrations directory in the inventory |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Setup configuration | Persists the merchant's completed or in-progress HBW setup (availability, capping, service details) | merchant/opportunity identifier, country, setup state, timestamps |
| Job queue | Holds pending tasks for the reminder and DWH reconciliation cron jobs | job type, scheduled_at, status, retries |

#### Access Patterns

- **Read**: Setup wizard steps read existing configuration to pre-populate forms; `/api/opportunity` lookup may check local cached state
- **Write**: Each wizard step writes partial or complete configuration on form submission; cron jobs write job queue entries and update job status
- **Indexes**: > No evidence found of specific index definitions in the inventory

## Caches

> No evidence found of a dedicated caching layer (Redis, Memcached, or in-memory cache). The service reads directly from MySQL and Salesforce on each request.

## Data Flows

Merchant setup data originates in Salesforce (opportunity/account) and is pulled into the application at session start via the `selfsetupHbw_ssuSalesforceClient`. The merchant's configuration choices are persisted to `continuumSsuDatabase` during the wizard. On final submission, the `selfsetupHbw_ssuSalesforceClient` and `selfsetupHbw_ssuBookingToolClient` push the configuration outbound to Salesforce and BookingTool respectively. The DWH reconciliation cron job reads local MySQL state and pushes updates to the data warehouse.
