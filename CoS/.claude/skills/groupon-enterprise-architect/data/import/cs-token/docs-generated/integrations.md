---
service: "cs-token"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 2
---

# Integrations

## Overview

CS Token Service has a minimal integration surface. It depends on one infrastructure service (Redis) and is called by two internal Continuum services (Cyclops and AppOps). There are no external third-party API dependencies.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Redis (csTokenRedis) | Redis TCP | Token payload cache (read/write with TTL) | yes | `csTokenRedis` |

### Redis Detail

- **Protocol**: Redis binary protocol over TCP (SSL in production)
- **Base URL / SDK**: Configured via `Settings.tokenizer_redis.host` / `port`; client initialized via `redis` gem through `Resque.tokenizer_redis`
- **Auth**: TLS password via `TLS_REDIS_PASSWORD` env var (production EMEA); SSL cert validation disabled (`VERIFY_NONE`)
- **Purpose**: Primary and only persistent store for token payloads; keys expire automatically via TTL
- **Failure mode**: Token creation and verification both fail if Redis is unreachable; service returns HTTP 401 on verify, HTTP 500 on create
- **Circuit breaker**: No evidence of circuit breaker; Redis errors propagate as exceptions

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Redis Cache (`csTokenRedis`) | Redis | Token storage and retrieval | `csTokenRedis` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Cyclops (CS agent tooling) | HTTPS/JSON | Requests token creation for CS agents acting on customer accounts; verifies tokens before calling Lazlo |
| AppOps | HTTPS/JSON | Requests token creation for automated operations |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

- **Redis health**: Service checks `Settings.tokenizer_redis.present?` at startup and on each request before any Redis operation. If the setting is absent, token creation/verification endpoints return HTTP 401 `{"message":"forbidden"}`.
- **Retry**: No application-level retry policy found; relies on Redis client defaults.
- **Circuit breaker**: No evidence found in codebase.
- **Redis timeout issues**: Runbook instructs operators to cycle affected pods and escalate to the `#redis-memcached` Google Chat space if issues persist.
