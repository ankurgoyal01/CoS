---
service: "mirror-maker-kubernetes"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

MirrorMaker Kubernetes does not expose any HTTP, gRPC, or REST API endpoints. It is a pure worker/consumer process that connects outbound to Kafka brokers. There is no inbound network interface beyond the Jolokia JMX agent (port 8778), which is internal to the pod and scraped only by the co-located Telegraf sidecar for metrics collection.

## Endpoints

> Not applicable. This service exposes no externally accessible endpoints.

The Jolokia agent is available at `http://localhost:8778/jolokia` within the pod for the Telegraf sidecar. This is not a public or service-to-service API.

## Request/Response Patterns

### Common headers

> Not applicable.

### Error format

> Not applicable.

### Pagination

> Not applicable.

## Rate Limits

> Not applicable. No inbound API surface exists.

## Versioning

> Not applicable.

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or GraphQL schema found in the repository.
