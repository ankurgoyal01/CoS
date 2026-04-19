---
service: "client-id"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Client ID Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [API Proxy Token Sync](api-proxy-token-sync.md) | synchronous | Periodic HTTP poll from API Proxy | API Proxy fetches updated client and token data from `/v3/services/{serviceName}` to enforce rate limits |
| [Client and Token Registration](client-token-registration.md) | synchronous | Operator action via management UI or API | An admin creates a new API client and issues an access token linked to a named service |
| [Scheduled Rate Limit Change](scheduled-rate-limit-change.md) | scheduled | Internal background executor | A pre-configured schedule temporarily overrides token rate limits for a defined time window, then reverts |
| [Self-Service Client Registration](self-service-client-registration.md) | synchronous | Developer action via self-service UI | A developer requests a new client and token via the self-service form; a Jira ticket is created for review |
| [Client Search and Lookup](client-search-lookup.md) | synchronous | API call from API Lazlo or internal tooling | A consumer searches for clients and tokens by token value, email, role, or updated-at timestamp |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |
| Mixed (synchronous trigger + scheduled) | 1 |

## Cross-Service Flows

- [API Proxy Token Sync](api-proxy-token-sync.md) — spans Client ID Service and API Proxy. API Proxy drives the sync cadence; Client ID Service is the read source. See the Continuum architecture model for the container-level relationship.
- [Self-Service Client Registration](self-service-client-registration.md) — spans Client ID Service and the Jira REST API for support ticket creation.
