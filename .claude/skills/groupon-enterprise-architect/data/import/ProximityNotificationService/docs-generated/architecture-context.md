---
service: "proximity-notification-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumProximityNotificationService"
    - "continuumProximityNotificationPostgres"
    - "continuumProximityNotificationRedis"
---

# Architecture Context

## System Context

The Proximity Notification Service is a Continuum platform service owned by the Emerging Channels team. It sits between mobile clients (iOS/Android Groupon apps) and a set of downstream deal and inventory services. Mobile clients poll the service with location coordinates; the service evaluates proximity to active Hotzone deals and decides whether to dispatch push notifications through the Rocketman push delivery service. It consumes audience, coupon, CLO, voucher, and deal annotation data from other Continuum services to enrich notification decisions.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Proximity Notification Service | `continuumProximityNotificationService` | Backend API | Java, Dropwizard | 11 / jtier 5.14.1 | Dropwizard service exposing geofence and hotzone APIs, generating notifications, and orchestrating proximity workflows. |
| Proximity Notification Postgres | `continuumProximityNotificationPostgres` | Database | PostgreSQL | GDS-managed | Primary relational datastore for hotzone, campaign, and send log data. |
| Proximity Notification Redis | `continuumProximityNotificationRedis` | Cache | Redis | Jedis 2.9.0 | Low-latency cache for recent user location and rate-limiting/travel state. |

## Components by Container

### Proximity Notification Service (`continuumProximityNotificationService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Resources | Exposes geofence, hotzone, and operational endpoints over HTTP | Dropwizard Resources / JAX-RS |
| Geofence Workflow | Evaluates user geofence events, computes candidate content, and orchestrates send decisioning | Controller/Workflow |
| Hotzone Workflow | Manages hotzone entities, category campaigns, and administrative operations | Controller/Service |
| Notification Engine | Builds localized notification payloads and tracking IDs before delivery | Notification Domain / Mustache |
| Proximity Client Manager | Coordinates outbound calls and combines responses from dependent services | Service Layer |
| External Service Adapters | HTTP client adapters for TDM, coupon, CLO, push, audience, Watson, and voucher services | Retrofit/OkHttp |
| Persistence Layer | DAO and send-log managers over Postgres-backed storage | JDBI/DAO |
| Cache Access Layer | Redis abstraction for user location history and related transient state | Jedis |
| Rate Limit and Travel Guard | Applies per-user suppression, travel checks, and send gating rules | Domain Guard |
| Hotzone Job Scheduler | Quartz-triggered hotzone generation jobs and batch execution hooks | Quartz Job |
| Health and Metrics | Health checks and service telemetry publishing | Dropwizard Health Check |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumProximityNotificationService` | `continuumProximityNotificationPostgres` | Reads and writes hotzone, campaign, and send-log data | JDBI/JDBC |
| `continuumProximityNotificationService` | `continuumProximityNotificationRedis` | Reads and writes short-lived location and travel state | Jedis/Redis |
| `continuumProximityNotificationService` | `continuumCouponsInventoryService` | Fetches nearby pushable coupons | HTTP/JSON |
| `continuumProximityNotificationService` | `continuumCloInventoryService` | Checks CLO redemption readiness | HTTP/JSON |
| `continuumProximityNotificationService` | `continuumAudienceManagementService` | Fetches audience memberships and affinity scores | HTTP/JSON |
| `continuumProximityNotificationService` | `watsonKv` | Retrieves Watson support data used by proximity flows | HTTP/JSON |
| `continuumProximityNotificationService` | `continuumVoucherInventoryService` | Checks voucher inventory and sold-out state | HTTP/JSON |

> Note: The Rocketman push service (push notification delivery) and Targeted Deal Message service are referenced in code but modeled as stubs in the central workspace. See `stubs.dsl` for details.

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumProximityNotificationService`
- Component: `components-continuumProximityNotificationService`
