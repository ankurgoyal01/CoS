---
service: "itier-3pip-docs"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for itier-3pip-docs (Groupon Simulator).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Partner Authentication](partner-authentication.md) | synchronous | Partner browser request to any protected route | Validates partner session cookie via `continuumUsersService`; redirects unauthenticated users to Groupon login |
| [Partner Onboarding Configuration Load](partner-onboarding-config-load.md) | synchronous | Partner accesses the Groupon Simulator integration setup page | Fetches partner onboarding configuration from PAPI via GraphQL and returns it to the frontend |
| [Test Deal Setup](test-deal-setup.md) | synchronous | Partner opens the Set Up Test Deals page | Loads onboarding config, fetches deal details from Lazlo, and returns enriched test deal configuration |
| [Availability Sync Trigger](availability-sync-trigger.md) | synchronous | Partner clicks "Trigger Availability" in the simulator UI | Validates session, loads onboarding config, identifies inventory product, and calls PAPI triggerAvailability mutation |
| [API Documentation Rendering](api-documentation-rendering.md) | synchronous | Partner navigates to `/3pip/docs` or the Redoc documentation page | Authenticates merchant, merges 3PIP OpenAPI specs, and renders the Redoc documentation page |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The **Partner Onboarding Configuration Load** and **Availability Sync Trigger** flows span multiple services:

- `continuumThreePipDocsWeb` → `continuumUsersService` (session validation)
- `continuumThreePipDocsWeb` → GraphQL PAPI (partner data queries and mutations)
- `continuumThreePipDocsWeb` → `continuumApiLazloService` (deal enrichment)

These are documented in the architecture dynamic view: `dynamic-continuumThreePipDocsWeb` (see [Architecture Context](../architecture-context.md)).
