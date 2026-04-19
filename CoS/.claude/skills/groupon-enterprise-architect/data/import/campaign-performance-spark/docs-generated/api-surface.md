---
service: "campaign-performance-spark"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

Campaign Performance Spark is a headless streaming job with no inbound HTTP, gRPC, or GraphQL API surface. It exposes no endpoints to external callers. All data ingestion is driven by consuming the `janus-all` Kafka topic; all output is written directly to PostgreSQL. Downstream services (such as `campaign-performance-app`) read from the shared PostgreSQL database to serve query results.

## Endpoints

> Not applicable. This service does not expose any HTTP, gRPC, or other network endpoints.

## Request/Response Patterns

### Common headers

> Not applicable.

### Error format

> Not applicable.

### Pagination

> Not applicable.

## Rate Limits

> Not applicable. No inbound API surface is exposed.

## Versioning

> Not applicable. No API versioning strategy applies to this service.

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or GraphQL schema exist in this repository. The service produces and consumes internal data schemas (`CampaignMetric`, `JanusRecord`) defined in `src/main/java/com/groupon/mars/campaignperformance/models/`.
