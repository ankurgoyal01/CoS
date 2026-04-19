---
service: "gpapi"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumGpapiDb"
    type: "postgresql"
    purpose: "Primary relational store for vendor portal entities"
---

# Data Stores

## Overview

gpapi owns a single PostgreSQL database (`continuumGpapiDb`) as its primary data store. This database holds all vendor-portal-specific entities that are not delegated to downstream microservices: vendors, users, products, items, contracts, features, validations, inventory records, approvals, and bank information. No caching layer or additional data stores are identified in the service inventory.

## Stores

### Goods Product API Database (`continuumGpapiDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumGpapiDb` |
| Purpose | Primary relational store for all vendor portal domain entities |
| Ownership | owned |
| Migrations path | `db/migrate/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `products` | Vendor product catalog entries managed through the portal | product_id, vendor_id, status, title, category_id |
| `items` | Individual item records within products | item_id, product_id, sku, price, status |
| `vendors` | Vendor account records for portal users | vendor_id, name, status, compliance_status |
| `users` | Vendor portal user accounts | user_id, email, vendor_id, role, status |
| `contracts` | Vendor contract records and lifecycle state | contract_id, vendor_id, status, start_date, end_date |
| `features` | Feature flag and capability records per vendor | feature_id, vendor_id, feature_name, enabled |
| `validations` | Validation rule records for vendor workflow checks | validation_id, entity_type, rule, status |
| `inventory` | Inventory allocation records for vendor items | inventory_id, item_id, quantity, warehouse |
| `approvals` | Approval workflow records for products and contracts | approval_id, entity_type, entity_id, approver_id, status |
| `bank_info` | Vendor bank account details for payment setup | bank_info_id, vendor_id, account_number_masked, routing_number_masked |

#### Access Patterns

- **Read**: Vendor Portal UI requests drive reads by vendor_id, product_id, item_id, and contract_id for display and form-population purposes
- **Write**: Create and update operations are triggered by vendor portal form submissions; approval state transitions update `approvals` and parent entity `status` fields
- **Indexes**: No specific index evidence available; standard Rails primary key and foreign key indexes expected on `vendor_id`, `product_id`, `item_id`, and `contract_id` columns

## Caches

> No evidence found in codebase. No Redis, Memcached, or in-memory cache layer is identified for this service.

## Data Flows

All reads and writes to `continuumGpapiDb` are performed directly by `continuumGpapiService` via ActiveRecord (Rails ORM). There is no CDC pipeline, ETL process, or replication identified from the inventory. Downstream microservices (Goods Product Catalog, Goods Inventory Service, etc.) maintain their own separate stores; gpapi does not replicate data to them but instead issues API calls to keep them in sync when vendor portal actions occur.
