---
service: "billing-record-options-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Billing Record Options Service (BROS).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Payment Methods by Country Query](payment-methods-by-country.md) | synchronous | HTTP GET request with country code | Resolves and returns a filtered, ranked list of payment methods for a specific country |
| [Payment Methods by Provider Query](payment-methods-by-provider.md) | synchronous | HTTP GET request with payment provider ID | Returns payment method details for a specific provider |
| [Client Type Resolution](client-type-resolution.md) | synchronous | Embedded in every payment methods request | Determines the client type (e.g., touch/mobile vs. desktop) from user-agent and role headers |
| [Database Migration](database-migration.md) | batch | Manual CLI invocation or AUTOMIGRATE on startup | Applies Flyway schema migrations to the bros PostgreSQL database |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

All runtime flows for BROS are self-contained within the service boundary. BROS does not call other Groupon microservices. The two cross-boundary interactions are:
- Reads from `daasPostgresPrimary` (DaaS PostgreSQL) — see [Payment Methods by Country Query](payment-methods-by-country.md)
- Reads from `raasRedis` (RAAS Redis cache) — embedded in all query flows

Consumer-to-BROS HTTP flows are tracked in the central Continuum architecture model under `continuumSystem`.
