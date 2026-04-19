---
service: "cs-token"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumCsTokenService]
---

# Architecture Context

## System Context

CS Token Service is a backend Rails API within the Continuum platform that sits between Cyclops (the CS agent web tooling) and Lazlo (the order management API). Cyclops requests token creation on behalf of CS agents acting on customer accounts; Lazlo consumes the token on subsequent calls to authorize the scoped action. The service has no database of its own — all state is held in a Redis cache (`csTokenRedis`) with TTL-based expiry.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| CS Token Service | `continuumCsTokenService` | Service | Ruby on Rails | 2.6.3 | Rails API service that creates and verifies customer service auth tokens |
| Token Redis Cache | `csTokenRedis` (stub) | Cache | Redis | — | Stores token payloads keyed by (optionally encrypted) token string; TTL-controlled |

## Components by Container

### CS Token Service (`continuumCsTokenService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `TokenController` | Handles token creation (`POST /api/v1/:country_code/token`) and verification (`GET /api/v1/:country_code/verify_auth`) API requests; enforces API key and client ID validation | Ruby on Rails controller |
| `TokensHelper` | Generates random tokens (`SecureRandom.hex(32)`), optionally encrypts them with AES-256-GCM, computes per-method expiration, and reads/writes token payloads in Redis | Ruby helper module |
| `HeartbeatController` | Serves `/heartbeat.txt` for load balancer health probing | Ruby on Rails controller |
| `StatusController` | Serves `/status.json` with service status and Git revision | Ruby on Rails controller |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `customerServiceApps` (Cyclops / AppOps) | `continuumCsTokenService` | Requests token creation and verification | HTTPS/JSON |
| `continuumCsTokenService` | `csTokenRedis` | Caches token payloads with TTL; retrieves token data on verify | Redis |

## Architecture Diagram References

- System context: `contexts-cs-token`
- Container: `containers-cs-token`
- Component: `components-cs-token-service`
