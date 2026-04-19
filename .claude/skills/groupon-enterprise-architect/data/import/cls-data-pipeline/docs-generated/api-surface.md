---
service: "cls-data-pipeline"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

The CLS Data Pipeline does not expose any HTTP, gRPC, or other synchronous API surface. It is a pure data pipeline service: jobs are launched via `spark-submit` on the Cerebro YARN cluster and operate entirely through Kafka consumption, Hive table writes, and HDFS interactions. There are no REST endpoints, GraphQL schemas, or service-to-service RPC interfaces.

## Endpoints

> Not applicable. This service does not expose HTTP or RPC endpoints.

## Request/Response Patterns

> Not applicable. No inbound synchronous interface exists.

## Rate Limits

> Not applicable. No rate limiting configured.

## Versioning

> Not applicable. No API versioning strategy — jobs are versioned via the assembly JAR version (e.g., `cls-data-pipeline-assembly-1.3.0.jar`).

## OpenAPI / Schema References

> Not applicable. No OpenAPI spec, proto files, or GraphQL schema exist in this repository.
