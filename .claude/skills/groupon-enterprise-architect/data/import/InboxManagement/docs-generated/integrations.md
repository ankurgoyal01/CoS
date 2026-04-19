---
service: "inbox_management_platform"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 4
internal_count: 3
---

# Integrations

## Overview

InboxManagement integrates with four external services (Campaign Management, CAS, RocketMan, and EDW) and relies on three internal Continuum data stores (Redis, Postgres, Kafka). All external service calls are made from dedicated integration client components within `continuumInboxManagementCore`. The service is consumed by Campaign Management (upstream trigger) and RocketMan (downstream delivery).

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Campaign Management API | rest | Fetch CampaignSendEvents and campaign metadata | yes | not in federated model |
| CAS (Campaign Arbitration Service) | rest | Filter and suppress dispatch candidates | yes | not in federated model |
| RocketMan Dispatch | kafka | Deliver final SendEvents to channel delivery system | yes | not in federated model |
| Enterprise Data Warehouse (EDW) | hive-jdbc | Load user attributes for synchronization | no | `edw` |

### Campaign Management API Detail

- **Protocol**: REST
- **Base URL / SDK**: `inbox_campaignManagementClient` (dedicated REST client component)
- **Auth**: Internal service authentication
- **Purpose**: `inbox_coordinationWorker` calls this client to load campaign send event details needed to build dispatch candidates
- **Failure mode**: Coordination work for the affected campaign is paused; error state recorded in Postgres; retry on next cycle
- **Circuit breaker**: Configurable via admin config key in Postgres

### CAS (Campaign Arbitration Service) Detail

- **Protocol**: REST
- **Base URL / SDK**: `inbox_arbitrationClient` (dedicated REST client component)
- **Auth**: Internal service authentication
- **Purpose**: Filters send candidates — suppresses users who should not receive a given communication based on arbitration rules (frequency caps, exclusions, preferences)
- **Failure mode**: CAS unavailability blocks dispatch for affected campaigns; circuit breaker can be configured to fail-open or fail-closed via admin config
- **Circuit breaker**: Yes — configurable via `/im/admin/config/{key}` endpoint

### RocketMan Dispatch Detail

- **Protocol**: Kafka
- **Base URL / SDK**: `inbox_rocketmanPublisher` (Kafka producer using kafka_2.12 0.10.2.1)
- **Auth**: Kafka cluster authentication
- **Purpose**: Final step in the send workflow — publishes serialized SendEvents to the RocketMan Kafka topic for email/push/SMS delivery
- **Failure mode**: Dispatch queue backs up in Redis; queue monitor alerts on depth; retries governed by Kafka producer retry config
- **Circuit breaker**: Kafka producer error handling via retries

### Enterprise Data Warehouse (EDW) Detail

- **Protocol**: Hive JDBC (hive-jdbc 2.0.0)
- **Base URL / SDK**: EDW Hive endpoint; accessed by `inbox_userSyncProcessor`
- **Auth**: Hive JDBC credentials (managed via config/secrets)
- **Purpose**: Periodic batch loads of user attributes used to enrich dispatch eligibility decisions
- **Failure mode**: Stale user attribute data is used; sync falls behind but dispatch continues with cached state
- **Circuit breaker**: No — EDW is non-critical path; failures tolerated with stale data

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Inbox Management Redis | Redis protocol | Priority queues (calc, dispatch), user locks, transient state | `continuumInboxManagementRedis` |
| Inbox Management Postgres | JDBC | Runtime config and send error state persistence | `continuumInboxManagementPostgres` |
| Kafka event bus | Kafka | Consuming UserProfileEvents, SendErrorEvents, SubscriptionEvents, CampaignSendEvents | not in federated model |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Campaign Management | kafka/mbus | Publishes CampaignSendEvents that trigger the coordination workflow |
| User Profile system | kafka | Publishes UserProfileEvents consumed by the user sync processor |
| Admin operators / tooling | rest | Use `/im/admin/config/*` endpoints for operational configuration |

> Upstream consumers are also tracked in the central architecture model.

## Dependency Health

- `inbox_adminApi` exposes `/grpn/healthcheck` for liveness checks across all daemon containers.
- Circuit breakers for Campaign Management API and CAS are runtime-configurable via `/im/admin/config/{key}` — allowing operators to open circuits without redeployment.
- `inbox_queueMonitor` continuously measures queue depths and emits metrics; alerts fire when calc or dispatch queues exceed configured thresholds.
- Redis and Postgres connection health is implicitly monitored through daemon liveness; degradation surfaces via failed processing cycles.
