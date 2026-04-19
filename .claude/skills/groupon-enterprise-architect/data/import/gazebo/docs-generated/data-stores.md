---
service: "gazebo"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumGazeboMysql"
    type: "mysql"
    purpose: "Primary relational store for all editorial content, tasks, users, and messaging data"
  - id: "continuumGazeboRedis"
    type: "redis"
    purpose: "Session data, feature flag state, cached objects"
---

# Data Stores

## Overview

Gazebo uses MySQL as its primary relational data store for all persistent editorial data, and Redis as a supporting cache for session management, feature flag state, and object caching. Both stores are owned by the Gazebo service. The web app, worker, MBus consumer, and cron containers all read from and write to MySQL. The web app and worker use Redis for session and cache operations.

## Stores

### Gazebo MySQL (`continuumGazeboMysql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumGazeboMysql` |
| Purpose | Primary relational store for editorial content, tasks, users, channels, teams, recycled items, outbound messages, and feature flags |
| Ownership | owned |
| Migrations path | `db/migrate/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `deals` | Stores deal metadata and editorial state | deal id, copy fields, status, channel, team |
| `copy_treatments` | Stores versioned deal copy content | deal id, treatment type, content fields, published state |
| `tasks` | Editorial task records including assignment and completion state | task id, deal id, assignee, status, task type, created_at |
| `users` | Editorial staff user profiles and permissions | user id, email, role, team assignments |
| `channels` | Deal distribution channel information | channel id, channel name, attributes |
| `teams` | Editorial team records | team id, team name, member references |
| `recycled_items` | Soft-deleted or abandoned content eligible for recovery | item id, content type, original id, deleted_at |
| `outbound_messages` | Message Bus outbound event records | message id, topic, payload, published_at |
| `feature_flags` | Flipper feature flag configuration | flag name, state, actor rules |

#### Access Patterns

- **Read**: Deal data fetched by deal ID or search criteria; task lists filtered by team, assignee, or status; user lookups by email or ID; checklist state read per deal
- **Write**: Copy treatments saved on each editorial update; task state updated on claim/unclaim/complete; outbound message records created on publish; Salesforce sync writes opportunity and deal data
- **Indexes**: No specific index definitions discoverable from inventory; standard Rails conventions assumed (primary keys, foreign keys on deal_id, user_id)

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumGazeboRedis` | redis | Session data storage, feature flag state via Flipper, cached Ruby objects | No evidence found; TTL managed by Rails session config and Flipper |

## Data Flows

- The `continuumGazeboCron` container periodically pulls data from Salesforce CRM via the Restforce SDK and writes updated deal and opportunity records directly to MySQL.
- The `continuumGazeboMbusConsumer` container processes incoming Message Bus events and writes the resulting deal, task, and notification state changes to MySQL.
- The `continuumGazeboWebApp` reads deal data from `continuumDealCatalogService` and user data from `continuumUsersService` over REST, caching responses in Redis where applicable.
- No CDC, ETL pipeline, or cross-store replication was discovered in the inventory.
