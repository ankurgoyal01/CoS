---
service: "kafka-active-audit"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> Not applicable

Kafka Active Audit is a headless worker daemon. It exposes no HTTP, gRPC, or GraphQL endpoints. The service is configured via a flat properties file and environment variables at startup. All output is via emitted metrics (monitord, JMX) and log files.

The `.service.yml` explicitly sets `status_endpoint.disabled: true` and declares `path: /no_http_endpoints`, confirming no HTTP surface exists.

## Endpoints

> No evidence found in codebase.

The service has no inbound network endpoints. It initiates all outbound connections (to Kafka brokers and monitord).

## Request/Response Patterns

### Common headers

> Not applicable — no HTTP surface.

### Error format

> Not applicable — no HTTP surface.

### Pagination

> Not applicable — no HTTP surface.

## Rate Limits

> No rate limiting configured.

The service controls its own production rate via the `producer.events.per.cycle` and `producer.scheduled.rate.ms` configuration properties (default: 10 events per 1000 ms cycle).

## Versioning

> Not applicable — no API versioning; the service has no HTTP surface.

## OpenAPI / Schema References

> No evidence found in codebase.

The `.service.yml` field `schema: disabled` confirms no OpenAPI schema is published.
