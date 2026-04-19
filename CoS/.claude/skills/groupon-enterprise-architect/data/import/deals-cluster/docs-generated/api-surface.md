---
service: "deals-cluster"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

Deals Cluster is a **batch Spark job** — it does not expose any HTTP, gRPC, or WebSocket API endpoints. It is not a server-side service; it runs as a scheduled YARN application on the Cerebro cluster. All cluster output data is consumed by the **Deals Cluster API** (`deals-cluster-api-jtier`), which is a separate service that reads from the PostgreSQL store written by this job.

The job does act as a **consumer** of two REST APIs:

- **Deals Cluster Rules API** — queried at `DealsClusterJob` startup to retrieve clustering rule definitions.
- **Top Clusters Rules API** — queried at `TopClustersJob` startup to retrieve top-cluster rule definitions.

These are read-only integrations; see [Integrations](integrations.md) for details.

## Endpoints

> Not applicable. This service exposes no API endpoints.

## Request/Response Patterns

> Not applicable.

## Rate Limits

> Not applicable.

## Versioning

> Not applicable. The job is versioned via Maven artifact version (currently `1.85-SNAPSHOT`) and deployed as a JAR to Cerebro.

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or GraphQL schema are present in this repository. Rule schema is defined by the Deals Cluster Rules API.
