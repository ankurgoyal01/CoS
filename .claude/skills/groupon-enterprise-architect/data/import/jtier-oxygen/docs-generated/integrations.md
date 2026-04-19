---
service: "jtier-oxygen"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 2
---

# Integrations

## Overview

JTier Oxygen integrates with four dependencies: two shared internal Groupon infrastructure services (MessageBus and DaaS Postgres) and two external systems (GitHub Enterprise API and RaaS Redis). All integrations are exercised intentionally as part of the service's role as a JTier building-block validation harness. The service is not consumed by any other production service.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GitHub Enterprise API | REST (HTTPS) | Fetch repository star counts for the `/repos/{team}/{repo}` endpoint | No | `githubEnterprise` |
| MessageBus (ActiveMQ/Artemis) | STOMP | Publish and consume broadcast queue messages for load testing and roundtrip validation | No | `messageBus` |

### GitHub Enterprise API Detail

- **Protocol**: HTTPS REST
- **Base URL**: `https://api.github.groupondev.com` (configured via `githubUrl` in YAML config; e.g. `src/main/resources/config/development.yml`)
- **Auth**: Not explicitly configured in inventory; standard GitHub Enterprise token-based auth is expected via `jtier-okhttp` / `jtier-retrofit` client infrastructure
- **Purpose**: The `GET /repos/{team}/{repo}` endpoint delegates to the GitHub client to look up star counts — used to validate outbound HTTP client functionality
- **Failure mode**: Endpoint returns an error if GitHub Enterprise is unreachable; no fallback or caching is implemented
- **Circuit breaker**: Not evidenced in inventory

### MessageBus (ActiveMQ/Artemis) Detail

- **Protocol**: STOMP over TCP (port 61613)
- **Base URL / SDK**: `jtier-messagebus-client` library; destinations configured in `messagebus.destinations` YAML block
- **Auth**: Username/password per destination (populated via JTier secrets infrastructure)
- **Purpose**: Core integration for broadcast fanout testing — Oxygen publishes messages to `jms.queue.JtierOxygen` and `jms.queue.JTierOxygen` queues and consumes them back to measure throughput, detect broker gaps, and validate durable queue behavior
- **Failure mode**: Broadcast throughput stalls; `BroadcastStats` will show stagnant `numSends` and `updatedAt` timestamps
- **Circuit breaker**: Not evidenced in inventory; uses JTier standard retry infrastructure

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| DaaS (Postgres) | JDBC (DaaS-managed pool) | Managed PostgreSQL access for greetings and broadcast data | `continuumOxygenPostgres` |
| RaaS (Redis) | Redis protocol (Jedis) | Managed Redis access for key-value test operations | `continuumOxygenRedisCache` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. JTier Oxygen is an internal tooling service with no known production service consumers. It is invoked by JTier team engineers and CI integration tests.

## Dependency Health

- **Postgres**: DaaS provides managed connection pooling and health monitoring. If Postgres is unavailable, greetings and broadcast endpoints return errors. Quartz jobs will fail to acquire locks.
- **Redis**: If Redis is unavailable, `POST /redis` and `GET /redis/{key}` endpoints will return errors. No fallback is implemented.
- **MessageBus**: If the broker is down, publish and consume endpoints return errors. Broadcast messages will stop circulating. No automatic restart of a broadcast is implemented.
- **GitHub Enterprise**: If the API is unreachable, the `/repos/{team}/{repo}` endpoint returns an error. No cached fallback is implemented.
- The development config exposes a `selfCheckHttpClient` (connectTimeout: 300ms, readTimeout: 500ms) for internal health verification; the `selfCheckUrl` points to the service's own base URL per environment.
