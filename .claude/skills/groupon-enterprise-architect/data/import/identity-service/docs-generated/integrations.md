---
service: "identity-service"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 0
internal_count: 3
---

# Integrations

## Overview

identity-service has three primary internal dependencies: the Groupon Message Bus (Thrift g-bus) for async event exchange, the GDPR Platform for erasure request orchestration and compliance confirmation, and RaaS (Rewards-as-a-Service) for identity-linked reward operations. All integrations are internal to the Groupon ecosystem. There are no external third-party API dependencies in the inventory.

## External Dependencies

> No evidence found of external third-party API dependencies.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Message Bus (Thrift g-bus) | Thrift / g-bus | Publish identity lifecycle events; consume GDPR erasure and audit events | `messageBus` |
| GDPR Platform | mbus / REST (to be confirmed) | Receive erasure requests; confirm erasure completion | `gdprPlatform` |
| RaaS (Rewards-as-a-Service) | REST / mbus (to be confirmed) | Identity-linked reward operations | `raas` |

### Message Bus (Thrift g-bus) Detail

- **Protocol**: Thrift over Groupon internal Message Bus
- **Base URL / SDK**: `messagebus` gem 0.3.6 (publishing), `g-bus` gem 0.0.1 (consumption)
- **Auth**: Internal service credentials managed by Message Bus infrastructure
- **Purpose**: Publishes `identity.v1.event`, `identity.v1.c2.event`, and `gdpr.account.v1.erased.complete` events; consumes GDPR erasure requests and dog-food audit events
- **Failure mode**: Publishing failures are buffered via the `message_bus_messages` outbox table. Consumption failures are retried via Resque with dead-letter fallback.
- **Circuit breaker**: No evidence found

### GDPR Platform Detail

- **Protocol**: To be confirmed — likely message bus event delivery
- **Base URL / SDK**: To be confirmed
- **Auth**: Internal Groupon service auth
- **Purpose**: Sends erasure requests to identity-service for compliance processing; receives `gdpr.account.v1.erased.complete` confirmation events
- **Failure mode**: GDPR erasure jobs are retried via Resque if processing fails
- **Circuit breaker**: No evidence found

### RaaS (Rewards-as-a-Service) Detail

- **Protocol**: To be confirmed
- **Base URL / SDK**: To be confirmed
- **Auth**: To be confirmed
- **Purpose**: Identity-linked reward operations tied to account lifecycle events
- **Failure mode**: To be confirmed by service owner
- **Circuit breaker**: No evidence found

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Groupon web and mobile applications | REST / Bearer JWT | Identity CRUD operations |
| Partner services | REST / Bearer JWT | Identity lookup and attribute management |
| GDPR Platform | mbus | Sending erasure requests; receiving erasure completion events |
| Downstream Mbus consumers | Thrift / g-bus | Consuming `identity.v1.event` and `identity.v1.c2.event` lifecycle events |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

- **Message Bus**: Publishing health is monitored via the `message_bus_messages` outbox — a growing backlog of unpublished messages indicates a Message Bus connectivity issue.
- **PostgreSQL**: ActiveRecord connection errors surface as HTTP 500 responses from the API; monitored via application logs and Sonoma metrics.
- **Redis**: Connection failures affect both caching (degraded performance, fallback to database reads) and Resque job processing (worker stalls).
- **GDPR Platform / RaaS**: No specific health check or circuit breaker patterns documented in the inventory. Contact the service owner for current resilience configuration.
