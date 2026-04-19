---
service: "amsJavaScheduler"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

AMS Java Scheduler exposes no inbound API surface. It is a purely outbound, cron-triggered batch service. All runtime invocations are initiated by Kubernetes CronJobs — there are no HTTP endpoints, gRPC services, or message-queue consumers that external callers can reach. The service acts as a caller, not a server.

For the APIs it calls against `continuumAudienceManagementService`, see [Integrations](integrations.md).

## Endpoints

> Not applicable — this service does not expose any inbound endpoints.

## Request/Response Patterns

### Common headers

> Not applicable — this service does not serve HTTP requests.

### Error format

> Not applicable — this service does not serve HTTP requests.

### Pagination

> Not applicable — this service does not serve HTTP requests.

## Rate Limits

> No rate limiting configured. This service is an outbound batch scheduler with no inbound interface.

## Versioning

> Not applicable — no API is exposed.

## OpenAPI / Schema References

> Not applicable — no API schema exists for this service.
