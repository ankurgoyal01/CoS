---
service: "mds-feed-job"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> Not applicable

MDS Feed Job does not expose any REST, gRPC, GraphQL, or other API surface. It is a Spark batch job submitted via Livy or an external scheduler. All job inputs are provided as job arguments or configuration files at submission time. There are no inbound HTTP endpoints, no webhooks, and no programmatic API for callers to invoke.

## Endpoints

> No evidence found. This service exposes no inbound endpoints.

## Request/Response Patterns

> Not applicable

## Rate Limits

> Not applicable. No inbound API surface; no rate limiting configured.

## Versioning

> Not applicable. Job versioning is managed via artifact versioning in Maven (pom.xml) and deployment pipeline.

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or GraphQL schema exist. See [Integrations](integrations.md) for the APIs this job calls as a client.
