---
service: "cs-token"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for CS Token Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Token Creation](token-creation.md) | synchronous | `POST /api/v1/:country_code/token` from Cyclops or AppOps | CS agent requests a scoped auth token for a customer action; token generated, encrypted, and cached in Redis |
| [Token Verification](token-verification.md) | synchronous | `GET /api/v1/:country_code/verify_auth` from Cyclops or downstream service | Caller verifies an existing token is valid for a specific method and consumer; returns customer and agent identity on success |
| [Test Token Creation](test-token-creation.md) | synchronous | `POST /api/v1/:country_code/token/create_token` from test tooling | Creates a long-lived (30-day) token for testing purposes; gated by `test_enabled` setting |
| [Service Health Check](service-health-check.md) | synchronous | `GET /heartbeat.txt` from load balancer | Load balancer probes service liveness; response determines pool membership |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- Token creation is always initiated by `customerServiceApps` (Cyclops or AppOps) and directly precedes a Lazlo API call that consumes the issued token for the scoped action.
- Token verification is called by Cyclops before delegating a customer action to Lazlo, ensuring the agent-scoped token has not expired and matches the intended method and consumer.
- No dynamic views are defined in the architecture DSL at this time (`views/dynamics.dsl` contains no entries).
