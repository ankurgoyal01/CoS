---
service: "deal_centre_api"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumDealCentrePostgres"
    type: "postgresql"
    purpose: "Primary datastore for deals, product catalog, inventory, merchants, and buyer workflow data"
---

# Data Stores

## Overview

Deal Centre API owns a single primary PostgreSQL database (`continuumDealCentrePostgres`) that serves as the authoritative store for all deal centre and product catalog state. There are no caches or secondary stores in the active architecture model. All reads and writes from the application layer pass through the `dca_persistenceLayer` component using JPA/Hibernate over JDBC.

## Stores

### Deal Centre Postgres (`continuumDealCentrePostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumDealCentrePostgres` |
| Purpose | Primary datastore for deals, product catalog, inventory, merchants, and buyer workflow data |
| Ownership | owned |
| Migrations path | `> No evidence found — check the service repository for migration tooling (Flyway or Liquibase)` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `deals` | Stores deal records created and managed by merchants | deal ID, merchant ID, status, title, start/end dates |
| `deal_options` | Stores individual purchasable options for a deal | option ID, deal ID, price, inventory count, type |
| `products` | Stores product catalog entries | product ID, name, category, description, attributes |
| `inventory` | Tracks available and reserved inventory per option | option ID, quantity available, quantity reserved |
| `merchants` | Merchant profile data associated with deals | merchant ID, name, contact info, status |
| `buyer_workflows` | State for buyer purchase and checkout workflows | workflow ID, buyer ID, deal ID, option ID, state |

#### Access Patterns

- **Read**: Deal lookups by merchant ID, buyer deal browsing by catalog filters, catalog product lookups by product ID and category
- **Write**: Deal and option creation/update on merchant workflow, inventory decrements on buyer purchase, catalog product upserts on admin action
- **Indexes**: No evidence found — index definitions to be verified in the service repository's migration scripts

## Caches

> Not applicable — no caching layer is modeled for this service.

## Data Flows

All data flows through the `dca_persistenceLayer` component using JPA/Hibernate. Domain services (`dca_domainServices`) read and write via JPA repositories. No CDC, ETL, or replication pipelines are modeled. Event-driven updates (inventory and catalog events from `messageBus`) are processed by `dca_messageBusIntegration`, which calls `dca_domainServices`, which in turn persists state changes to `continuumDealCentrePostgres`.
