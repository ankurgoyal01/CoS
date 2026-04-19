---
service: "contract_service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumContractMysql"
    type: "mysql"
    purpose: "Primary relational datastore for all contract definitions, templates, contracts, versions, and identities"
---

# Data Stores

## Overview

Contract Service owns a single MySQL database (managed via Groupon's DaaS — Database as a Service platform). The database stores all contract definitions, their versioned templates, instantiated contracts, per-update version snapshots, and identity/signature records. There is no caching layer; all reads hit MySQL directly. Master/slave replication is used for data resilience. No external object storage or analytics store is used.

## Stores

### Contract Service MySQL (`continuumContractMysql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumContractMysql` |
| Purpose | Stores contract definitions, templates, contracts, version history, and identity/signature records |
| Ownership | owned |
| Migrations path | `db/migrate/` (standard Rails migrations via `rake db:migrate`) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `contract_definitions` | Stores contract template definitions with schema and locale | `uuid`, `name`, `locale`, `version`, `schema`, `sample_data` |
| `definition_templates` | Stores the XSLT/XSL render templates associated with a definition | `contract_definition_id`, `format` (html/pdf/txt), `template` |
| `contracts` | Stores instantiated merchant contracts | `uuid`, `contract_definition_id`, `signature_id`, `salesforce_id` |
| `contract_versions` | Stores a snapshot of `user_data` on every contract update | `contract_id`, `version`, `user_data` |
| `identities` | Stores the identity record used to sign a contract | `uuid`, `type`, `ip_address`, `name`, `extra_information` |

#### Access Patterns

- **Read**: Lookup contracts by UUID (`find_by_uuid!`) or by Salesforce ID (`find_by_salesforce_id`). Lookup definitions by UUID or by name+version. Version history is eagerly included in contract serialization.
- **Write**: Contract creation writes a new contract and an initial `ContractVersion` record. Each subsequent `update` that changes `user_data` creates an additional `ContractVersion` snapshot. Signing a contract creates and associates an `Identity` record. Contract definitions are immutable after creation if any contracts reference them.
- **Indexes**: No explicit index definitions visible in the repository beyond standard ActiveRecord primary keys. Lookup by `salesforce_id` and by `uuid` columns suggests index coverage on those columns.

## Caches

> No evidence found in codebase. The RUNBOOK.md explicitly states "No cache." No Redis or Memcached integration is present.

## Data Flows

All data flows are synchronous and point-to-point:

1. API request arrives at a Rails controller.
2. The controller writes to or reads from MySQL via ActiveRecord models (`Contract`, `ContractDefinition`, `ContractVersion`, `Identity`).
3. For render requests, the `DocumentRenderer` reads template content from `DefinitionTemplate` (already in MySQL) and merges with contract `user_data` to produce HTML/PDF/text output.
4. No CDC, ETL, or replication into analytics systems is visible in this codebase.

Production database host: `cicero-rw-na-production-db.gds.prod.gcp.groupondev.com` (database: `contract_service_production`).
Staging database host: `cicero-rw-na-staging-db.gds.stable.gcp.groupondev.com` (database: `contract_service`).
