---
service: "mx-merchant-access"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumAccessPostgres"
    type: "postgresql"
    purpose: "Primary datastore for all merchant access entities, contacts, roles, audit records"
---

# Data Stores

## Overview

The Merchant Access Service owns a single PostgreSQL database (`merchant_access`) as its primary and only persistent store. All access entities — contacts, roles, rights, primary contacts, future contacts, merchant groups, and audit records — reside in this database under the `access_service` schema. Schema migrations are managed with Liquibase. An optional in-process EhCache layer can be enabled for read-heavy paths.

## Stores

### Merchant Access Postgres (`continuumAccessPostgres`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL (42.7.3 driver) |
| Architecture ref | `continuumAccessPostgres` |
| Purpose | Primary datastore for merchant access entities, contacts, role bindings, and audit records |
| Ownership | owned |
| Migrations path | `access-infrastructure/src/main/resources/` (Liquibase changelogs: `merchant_access_master.xml`, `merchant_access_schema.xml`, `merchant_disabled_notifications_changelog.xml`) |
| Default schema | `access_service` |
| Provisioning | DaaS (Database-as-a-Service) — declared in `.service.yml` dependencies |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `application` | Defines applications that can have roles and rights | `id`, `name`, `description`, `created_at` |
| `role` | Roles within an application, used to group access rights | `id`, `application_id`, `name`, `description` |
| `access_right` | Denormalized rights per role (each role gets its own copy) | `id`, `name`, `role_id` |
| `merchant_contact` | User-to-merchant binding (the core access relationship) | `id`, `contact_uuid`, `account_uuid`, `merchant_uuid`, `active` |
| `merchant_access` | Role assignment for a merchant contact | `id`, `contact_id`, `role_id`, `active` |
| `primary_contact` | The designated primary contact for a merchant | `id`, `identity_uuid`, `merchant_uuid`, `active` |
| `future_contact` | Invited users not yet registered, awaiting merchant access | `id`, `merchant_uuid`, `email`, `status`, `retries`, `country_code`, `email_template` |
| `merchant_group` | Groups of related merchants sharing an access context | `id`, `group_id`, `merchant_uuid`, `active` |
| `merchant_disabled_notifications` | Notification groups explicitly disabled per merchant contact | `id`, `account_uuid`, `merchant_uuid`, `notification_group` |
| `audit` | Immutable audit log of all write operations | `id`, `user_type`, `user_id`, `entity_type`, `old_id`, `new_id`, `created_at` |

#### Access Patterns

- **Read**: Contacts are looked up by `account_uuid`, `merchant_uuid`, or the combination of both. Primary contacts are fetched by `merchant_uuid`. Roles are read as a full catalog. Future contacts are queried by `merchant_uuid`.
- **Write**: Contact creation inserts into `merchant_contact` and `merchant_access`; deletion soft-deletes by setting `active = false`. Primary contact assignment inserts into `primary_contact` and deactivates the previous entry. Every write produces a row in `audit`.
- **Indexes**: `merchant_group` has a unique partial index on `merchant_uuid WHERE active = true`, and a partial index on `group_id WHERE active = true`. `merchant_disabled_notifications` has a unique constraint on `(account_uuid, merchant_uuid, notification_group)`.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `mas-ehcache` | in-memory (EhCache 2.8.1) | Optional read cache, controlled by `mas.ehcache_enabled` property; configurable via `mas-ehcache.xml` classpath resource | Configured in `mas-ehcache.xml` |

## Data Flows

All data flows through the JPA/Hibernate ORM layer from the service application container directly to the PostgreSQL database. There is no CDC, ETL, or replication configured in this repository. Account lifecycle events received from MBus trigger soft-delete or deactivation write operations, which are the only externally-driven data mutations.
