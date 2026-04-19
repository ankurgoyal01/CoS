---
service: "raas"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal]
---

# API Surface

## Overview

The RaaS Info Service (`continuumRaasInfoService`) exposes a REST JSON API over HTTP for querying Redis infrastructure inventory. Consumers are primarily internal operators and tooling that need to inspect cluster topology, database assignments, node health, endpoint addresses, and shard layout. All endpoints return operational metadata sourced from the synchronized MySQL store.

## Endpoints

### Cluster Inventory

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/clusters` | List all managed Redis clusters with metadata | Internal |
| GET | `/dbs` | List all Redis databases across clusters | Internal |
| GET | `/nodes` | List all cluster nodes with status | Internal |
| GET | `/endpoints` | List all database endpoints and addresses | Internal |
| GET | `/shards` | List all shards with topology details | Internal |

### Operational Triggers

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/update/run` | Trigger a synchronous metadata sync from cached snapshots | Internal |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` for all JSON responses
- Standard Rails session/cookie handling for browser-based UI access

### Error format

> No evidence found in the architecture model for a specific error format schema. Standard Rails JSON error responses are expected.

### Pagination

> No evidence found for pagination configuration in the architecture model.

## Rate Limits

> No rate limiting configured.

## Versioning

> No versioning strategy is documented in the architecture model. Endpoints use no URL path version prefix.

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or GraphQL schema discovered in the architecture inventory. Schema is defined implicitly by the ActiveRecord models (`continuumRaasInfoService_raasInfoPersistence`) for clusters, nodes, DBs, endpoints, and shards.
