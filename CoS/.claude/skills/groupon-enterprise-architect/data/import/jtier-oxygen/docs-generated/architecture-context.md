---
service: "jtier-oxygen"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumOxygenService, continuumOxygenPostgres, continuumOxygenRedisCache]
---

# Architecture Context

## System Context

JTier Oxygen is a member of the `continuumSystem` (Continuum Platform). It is deployed as a standalone multi-region service used exclusively by the JTier team for validating platform framework changes. It does not participate in any consumer commerce flow. Its external interactions are: MessageBus (shared Groupon messaging fabric), GitHub Enterprise (external REST API for repo metadata), Postgres (owned relational store), and Redis (owned cache).

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| JTier Oxygen Service | `continuumOxygenService` | Backend | Java, Dropwizard | jtier-service-pom 5.15.0 | Main application container serving HTTP API, broadcast orchestration, scheduled jobs, and all integration points |
| Oxygen Postgres | `continuumOxygenPostgres` | Database | PostgreSQL | - | Primary relational store for greetings, broadcast metadata, and Quartz job persistence |
| Oxygen Redis | `continuumOxygenRedisCache` | Cache | Redis | 5-alpine (local dev) | Key-value cache backing the Redis test resource endpoint (RaaS via Jedis bundle) |

## Components by Container

### JTier Oxygen Service (`continuumOxygenService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| HTTP Resources (`oxygenHttpApi`) | Dropwizard/JAX-RS resources for greetings, messagebus, redis, proxy, broadcasts, and repos endpoints | JAX-RS |
| Broadcast Core (`oxygenBroadcastCore`) | Broadcast service, controller, and message processing logic for queued fanout and metrics collection | Java |
| Persistence Adapters (`oxygenDataAccess`) | JDBI DAO layer and SQL-backed repositories for greetings and broadcast data | JDBI3 |
| MessageBus Client (`oxygenMessageClient`) | Mbus reader/writer integration and destination handling via jtier-messagebus-client | JTier MessageBus |
| GitHub Client (`oxygenGithubClient`) | HTTP client wrapper for GitHub repository star-count lookups | OkHttp |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumOxygenService` | `continuumOxygenPostgres` | Stores greetings, broadcast records, and Quartz scheduler state | JDBC (DaaS-managed) |
| `continuumOxygenService` | `continuumOxygenRedisCache` | Reads and writes key-value cache entries | Redis protocol (Jedis) |
| `continuumOxygenService` | `messageBus` | Publishes and consumes broadcast queue messages | STOMP (ActiveMQ/Artemis) |
| `continuumOxygenService` | `githubEnterprise` | Calls GitHub REST API for repository star metadata | HTTPS REST |
| `oxygenHttpApi` | `oxygenBroadcastCore` | Invokes broadcast orchestration for mass publish/consume and roundtrip endpoints | Direct (in-process) |
| `oxygenHttpApi` | `oxygenDataAccess` | Reads and writes greeting and broadcast data | Direct (in-process) |
| `oxygenHttpApi` | `oxygenGithubClient` | Delegates repository star lookups | Direct (in-process) |
| `oxygenBroadcastCore` | `oxygenDataAccess` | Persists and retrieves broadcast state | Direct (in-process) |
| `oxygenBroadcastCore` | `oxygenMessageClient` | Publishes and consumes queue messages | Direct (in-process) |

## Architecture Diagram References

- Component: `components-oxygen-service`
- Dynamic runtime flow: `dynamic-oxygen-runtime-flow`
