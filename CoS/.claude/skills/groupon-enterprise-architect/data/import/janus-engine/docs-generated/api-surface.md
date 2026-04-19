---
service: "janus-engine"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> Not applicable

Janus Engine exposes no REST, gRPC, GraphQL, or WebSocket API surface. It is a pure stream-processing service that interacts exclusively via MBus topic subscriptions (inbound) and Kafka topic publications (outbound). Health is signaled via a filesystem liveness flag rather than an HTTP health endpoint. There are no external callers that invoke this service synchronously.

## Endpoints

> No evidence found

No HTTP or RPC endpoints are defined. The service does not bind a server port for external requests.

## Request/Response Patterns

> Not applicable

No request/response pattern applies. All I/O is event-driven via MBus and Kafka.

## Rate Limits

> No rate limiting configured.

## Versioning

> Not applicable

No API versioning strategy — the service has no external API.

## OpenAPI / Schema References

> No evidence found

No OpenAPI spec, proto files, or GraphQL schema exist for this service. Event payload schemas are governed by the Janus metadata service mapper definitions.
