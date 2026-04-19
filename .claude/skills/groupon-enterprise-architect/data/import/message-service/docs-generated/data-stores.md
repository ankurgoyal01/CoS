---
service: "message-service"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumMessagingMySql"
    type: "mysql"
    purpose: "Campaign metadata, templates, and UI-managed configuration"
  - id: "continuumMessagingRedis"
    type: "redis"
    purpose: "Low-latency cache for campaigns, templates, and notifications"
  - id: "continuumMessagingBigtable"
    type: "bigtable"
    purpose: "Primary user-campaign assignment and message delivery data (cloud)"
  - id: "continuumMessagingCassandra"
    type: "cassandra"
    purpose: "Legacy user-campaign assignment and message delivery data"
---

# Data Stores

## Overview

The CRM Message Service owns four data stores serving distinct roles: MySQL is the system of record for campaign configuration and metadata managed through the UI; Redis provides a low-latency caching layer that accelerates the high-frequency `/api/getmessages` read path; Bigtable is the primary at-scale store for user-campaign assignment and delivery data in cloud deployments; Cassandra serves the same purpose in legacy environments. All stores are accessed through the `messagingPersistenceAdapters` component.

## Stores

### Messaging MySQL (`continuumMessagingMySql`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumMessagingMySql` |
| Purpose | Relational store for campaign metadata, message templates, and all UI-managed configuration |
| Ownership | owned |
| Migrations path | > No evidence found in the architecture inventory |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Campaign | Core campaign record: targeting rules, scheduling, status | Campaign ID, status, audience ID, start/end dates |
| Message template | Content definitions for banners and notifications | Template ID, channel, content fields |
| Campaign audience | Mapping of campaigns to their assigned audiences | Campaign ID, audience ID |

#### Access Patterns

- **Read**: `messagingCampaignOrchestration` and `messagingMessageDeliveryEngine` read campaign metadata during message delivery and campaign evaluation
- **Write**: `messagingCampaignOrchestration` persists campaign state changes on create, update, and approval; `messagingAudienceImportJobs` may update audience assignment mappings
- **Indexes**: No index details available in the architecture inventory

---

### Messaging Redis Cache (`continuumMessagingRedis`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `continuumMessagingRedis` |
| Purpose | Low-latency acceleration of campaign, template, and notification lookups |
| Ownership | owned |
| Migrations path | Not applicable |

#### Access Patterns

- **Read**: `messagingMessageDeliveryEngine` reads cached campaign and template data to avoid repeated MySQL round-trips on each `/api/getmessages` call
- **Write**: `messagingPersistenceAdapters` populates and invalidates cache entries on campaign state changes
- **Indexes**: Not applicable (key-value store)

---

### Messaging Bigtable (`continuumMessagingBigtable`)

| Property | Value |
|----------|-------|
| Type | Google Cloud Bigtable |
| Architecture ref | `continuumMessagingBigtable` |
| Purpose | Primary store for user-campaign assignments and message delivery data in cloud deployments |
| Ownership | owned |
| Migrations path | Not applicable (schema-less) |

#### Access Patterns

- **Read**: `messagingMessageDeliveryEngine` reads user-campaign assignments to determine which messages are eligible for a given user
- **Write**: `messagingAudienceImportJobs` bulk-writes assignment data after processing a scheduled audience refresh; capacity can be scaled via `/api/bigtable/scale`
- **Indexes**: Row key design drives lookup efficiency; no secondary index details in the architecture inventory

---

### Messaging Cassandra (`continuumMessagingCassandra`)

| Property | Value |
|----------|-------|
| Type | Apache Cassandra |
| Architecture ref | `continuumMessagingCassandra` |
| Purpose | Legacy store for user-campaign assignments and message delivery data in non-GCP environments |
| Ownership | owned |
| Migrations path | Not applicable (schema-less) |

#### Access Patterns

- **Read**: Same pattern as Bigtable — user-assignment lookups during message delivery evaluation
- **Write**: `messagingAudienceImportJobs` writes assignment data in environments where Bigtable is not available
- **Indexes**: No details available in the architecture inventory

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumMessagingRedis` | Redis | Campaign and template lookup acceleration | Not documented in architecture inventory |

## Data Flows

- **MySQL -> Redis**: Campaign and template records are loaded from MySQL and cached in Redis; cache entries are invalidated on campaign state changes
- **Audience export (GCP Storage / HDFS) -> Bigtable / Cassandra**: Batch `messagingAudienceImportJobs` download audience export files and write user-campaign assignments to Bigtable (primary) or Cassandra (legacy) after each scheduled audience refresh
- **MySQL -> MBus / EDW**: Campaign metadata written to MySQL is subsequently published to MBus and forwarded to EDW for analytics consumption
