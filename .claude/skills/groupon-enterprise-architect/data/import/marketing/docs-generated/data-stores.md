---
service: "marketing"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumMarketingPlatformDb"
    type: "mysql"
    purpose: "Primary relational store for campaign, subscription, and inbox data"
---

# Data Stores

## Overview

The Marketing & Delivery Platform owns a single MySQL database provisioned via Database-as-a-Service (DaaS). This database stores campaign definitions, scheduling metadata, consumer subscription preferences, inbox messages, and delivery tracking records. The platform manages its own data stores as stated in the container description.

## Stores

### Marketing Platform Database (`continuumMarketingPlatformDb`)

| Property | Value |
|----------|-------|
| Type | MySQL (DaaS) |
| Architecture ref | `continuumMarketingPlatformDb` |
| Purpose | Primary relational data store for campaign, subscription, inbox, and delivery data |
| Ownership | owned |
| Migrations path | > No evidence found in codebase. |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `campaigns` (inferred) | Stores campaign definitions and lifecycle state | campaign_id, name, status, schedule, targeting_rules |
| `inbox_messages` (inferred) | User messaging inbox records | message_id, user_id, campaign_id, status, created_at |
| `subscriptions` (inferred) | Topic and user subscription preferences | subscription_id, user_id, topic, opt_in_status |
| `delivery_log` (inferred) | Campaign delivery tracking and metrics | delivery_id, campaign_id, user_id, channel, status, delivered_at |

> Entity/table details are inferred from component responsibilities. No schema definitions were found in the codebase.

#### Access Patterns

- **Read**: Campaign retrieval for management UI, inbox queries per user, subscription preference lookups
- **Write**: Campaign creation and status transitions, inbox message insertion on delivery, subscription opt-in/opt-out updates
- **Indexes**: > No evidence found in codebase.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| > No evidence found in codebase. | | | |

> No cache containers (Redis, Memcached) are defined in the architecture model for this service.

## Data Flows

- Campaign and delivery event data is published to the shared **Message Bus** (`messageBus`) via the Kafka Logging component for downstream analytics consumption.
- ETL/replication patterns to EDW or BigQuery are not explicitly modeled for this service's database, though other Continuum databases follow this pattern.
