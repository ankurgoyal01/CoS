---
service: "inbox_management_platform"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumInboxManagementCore, continuumInboxManagementAdminUi, continuumInboxManagementRedis, continuumInboxManagementPostgres]
---

# Architecture Context

## System Context

InboxManagement is a set of containers within the `continuumSystem` (Continuum Platform) — Groupon's core commerce and marketing engine. It sits between Campaign Management (upstream trigger) and RocketMan (downstream channel delivery), acting as the orchestration hub that coordinates when, to whom, and how communications are dispatched. It interacts with CAS for arbitration filtering, EDW for user attribute enrichment, and Kafka for async event consumption and publication.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Inbox Management Core Daemons | `continuumInboxManagementCore` | Backend | Java | 11 | Runs coordination, dispatch, user-sync, queue-monitor, and error-listener workers for inbox send orchestration |
| Inbox Management Admin UI | `continuumInboxManagementAdminUi` | WebApp | Java/Jetty | — | Web and daemonized admin control plane for queue inspection, config, and throttle operations |
| Inbox Management Redis | `continuumInboxManagementRedis` | Cache/Database | Redis | — | Sharded Redis backing calc and dispatch priority queues, user locks, and transient state |
| Inbox Management Postgres | `continuumInboxManagementPostgres` | Database | PostgreSQL | — | Operational relational store for runtime config and send error state |

## Components by Container

### Inbox Management Core Daemons (`continuumInboxManagementCore`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `inbox_coordinationWorker` | Dequeues calc-queue users, loads campaign events, and prepares dispatch candidates | Java |
| `inbox_campaignManagementClient` | Integration client to fetch campaign send events from Campaign Management | Java/REST client |
| `inbox_arbitrationClient` | Integration client to filter send candidates via CAS (Campaign Arbitration Service) | Java/REST client |
| `inbox_dispatchScheduler` | Moves eligible users/events into dispatch-ready state and schedules work | Java |
| `inbox_rocketmanPublisher` | Publishes final send events to RocketMan delivery integration via Kafka | Java/Kafka |
| `inbox_userSyncProcessor` | Consumes UserProfileEvents and updates inbox user state | Java/Kafka |
| `inbox_queueMonitor` | Collects queue depth and health metrics for calc and dispatch flows | Java |
| `inbox_configAndStateAccess` | Shared DAO/service boundary for runtime config and durable state persistence | Java |

### Inbox Management Admin UI (`continuumInboxManagementAdminUi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `inbox_adminApi` | Operational REST endpoints for queue inspection, throttle configuration, daemon flags, and circuit breaker management | Java/REST |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumInboxManagementAdminUi` | `continuumInboxManagementCore` | Uses operational APIs and shared services | Internal |
| `continuumInboxManagementCore` | `continuumInboxManagementRedis` | Reads/writes queues, locks, and transient state | Redis protocol |
| `continuumInboxManagementCore` | `continuumInboxManagementPostgres` | Reads/writes config and durable operational state | JDBC |
| `continuumInboxManagementCore` | `edw` | Loads user attributes for synchronization | Hive JDBC |
| `inbox_coordinationWorker` | `inbox_campaignManagementClient` | Requests campaign send events | Internal |
| `inbox_coordinationWorker` | `inbox_arbitrationClient` | Filters candidates with CAS | Internal |
| `inbox_coordinationWorker` | `inbox_dispatchScheduler` | Schedules dispatch work | Internal |
| `inbox_dispatchScheduler` | `inbox_rocketmanPublisher` | Emits dispatch payloads | Internal |
| `inbox_userSyncProcessor` | `inbox_configAndStateAccess` | Reads/writes sync state | Internal |
| `inbox_queueMonitor` | `inbox_configAndStateAccess` | Reads queue/state metadata | Internal |
| `inbox_adminApi` | `inbox_configAndStateAccess` | Manages runtime config and state | Internal |

## Architecture Diagram References

- Container: `containers-inbox-management`
- Component (Core): `components-inbox-management-core`
- Component (Admin): `components-inbox-management-admin`
- Dynamic (Coordination flow): `dynamic-inbox-core-coordination`
