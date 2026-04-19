---
service: "hybrid-boundary"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumHybridBoundaryServiceRegistryTable"
    type: "dynamodb"
    purpose: "Service registration and endpoint configuration state store"
---

# Data Stores

## Overview

Hybrid Boundary uses AWS DynamoDB as its sole persistent data store. All service registration records, endpoint configurations, shift status, authorization policies, and change history are stored in DynamoDB tables. The table names are prefixed with `edge-proxy.<env>` (e.g. `edge-proxy.production`) to provide environment isolation within the same AWS account. There are no relational databases, caches, or additional storage systems.

## Stores

### Hybrid Boundary Service Registry (`continuumHybridBoundaryServiceRegistryTable`)

| Property | Value |
|----------|-------|
| Type | dynamodb |
| Architecture ref | `continuumHybridBoundaryServiceRegistryTable` |
| Purpose | Configuration and service registration state store for edge routing |
| Ownership | owned |
| Migrations path | Not applicable (DynamoDB; schema managed via Terraform) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `edge-proxy.<env>.services` | Stores service and domain registrations with endpoint and routing configuration | `service`, `domain`, `environment`, `namespace`, `clusters`, `protocolType`, `authorization`, `shift`, `version` |
| `edge-proxy.<env>.history` | Stores versioned change history for each domain | `domainName`, `version`, `changeDescription` (method, user, reason, GProd ticket) |

#### Access Patterns

- **Read**: Agent reads all service registrations for a namespace via `GetForNamespace` on every poll cycle (default 30-second interval). API Lambda reads individual service records by `(serviceName, domainName)` composite key for CRUD operations.
- **Write**: API Lambda writes updated service records on each create/update/delete operation. Iterator Lambda applies stepwise weight changes during traffic shifts. All writes increment the `version` counter.
- **Indexes**: Table prefix pattern `edge-proxy.<env>` used in agent (`agent/db/db.go`); specific secondary index definitions managed via Terraform (not visible in application source).

## Caches

> No evidence found in codebase. The agent computes a hash of the current service list to detect changes between poll cycles (in-memory comparison only, not a persistent cache).

## Data Flows

- Agent polls DynamoDB on a 30-second ticker, reads all service registrations for its namespace, compares a hash against the previous cycle, and if changed pushes an updated xDS snapshot to connected Envoy instances.
- API Lambda writes to DynamoDB on every mutating API call. DynamoDB Streams on the service registry table trigger the Registry Lambda (`continuumHybridBoundaryLambda`) to process changes and update DNS records.
- History records are written by the API Lambda on every successful mutation, preserving the full previous configuration snapshot and audit metadata.
