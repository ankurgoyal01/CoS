---
service: "client-id"
title: "API Proxy Token Sync"
generated: "2026-03-03"
type: flow
flow_name: "api-proxy-token-sync"
flow_type: synchronous
trigger: "Periodic HTTP poll from API Proxy"
participants:
  - "continuumClientIdService"
  - "continuumClientIdReadReplica"
architecture_ref: "dynamic-continuum-client-id"
---

# API Proxy Token Sync

## Summary

API Proxy periodically polls Client ID Service to synchronise its local copy of all client and token data. This data drives runtime access control and rate limit enforcement. The sync is incremental — API Proxy supplies an `updatedAfter` timestamp and receives only tokens modified since that point. Client ID Service serves this request from the MySQL read replica to avoid load on the primary.

## Trigger

- **Type**: api-call (timer-driven on the API Proxy side)
- **Source**: API Proxy periodic background job
- **Frequency**: Periodic (interval configured on the API Proxy side; not defined in this codebase)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Proxy | Initiator — sends incremental sync request with last-known `updatedAfter` timestamp | External consumer |
| Client ID Service | Responder — queries read replica and returns updated client + token records | `continuumClientIdService` |
| MySQL Read Replica | Data source for sync queries | `continuumClientIdReadReplica` |

## Steps

1. **API Proxy sends sync request**: API Proxy calls `GET /v3/services/{serviceName}` with optional query parameters `updatedAfter` (ISO timestamp of last successful sync), `activeOnly` or `active` (filter suspended tokens), and `all` (fetch all records ignoring timestamp).
   - From: API Proxy
   - To: `continuumClientIdService`
   - Protocol: REST (HTTPS/JSON)

2. **Client ID Service queries read replica**: The API Resources component passes the request parameters to the Persistence Layer, which executes a filtered SQL query against `continuumClientIdReadReplica`. If `updatedAfter` is provided, the query filters `api_service_tokens.updated_at > updatedAfter`. If `activeOnly` / `active` is set, suspended tokens are excluded.
   - From: `continuumClientIdApiResources`
   - To: `continuumClientIdPersistence` → `continuumClientIdReadReplica`
   - Protocol: JDBI / MySQL

3. **Assembles response**: The Persistence Layer returns a joined result set of clients, tokens, and service mappings. The `GetClientsAndTokensView` is populated and serialised to JSON.
   - From: `continuumClientIdPersistence`
   - To: `continuumClientIdApiResources`
   - Protocol: In-process

4. **Returns JSON payload to API Proxy**: Client ID Service returns HTTP 200 with the list of updated client + token records. API Proxy updates its local cache and advances its `updatedAfter` cursor to the `updated_at` of the latest token received.
   - From: `continuumClientIdService`
   - To: API Proxy
   - Protocol: REST (HTTPS/JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Read replica unreachable | HikariCP connection timeout (40000ms); JDBI throws exception | HTTP 500 returned to API Proxy; API Proxy retains its previous snapshot |
| `updatedAfter` timestamp skew (GDS cross-env sync) | No automatic recovery in service; tokens imported from PROD retain original `updated_at` | API Proxy may skip newly-imported tokens; manual `reset_clients` command required (see [Runbook](../runbook.md)) |
| Service pod unavailable | Kubernetes readiness probe removes pod from load balancer | API Proxy request fails; retried on next sync cycle |

## Sequence Diagram

```
API Proxy -> continuumClientIdService: GET /v3/services/{serviceName}?updatedAfter=<ts>&activeOnly=true
continuumClientIdService -> continuumClientIdReadReplica: SELECT clients+tokens WHERE updated_at > <ts> AND status = ACTIVE
continuumClientIdReadReplica --> continuumClientIdService: Joined result set (clients, tokens, service_tokens)
continuumClientIdService --> API Proxy: HTTP 200 JSON (GetClientsAndTokensView)
API Proxy -> API Proxy: Update local token cache; advance updatedAfter cursor
```

## Related

- Architecture dynamic view: No dynamic views modeled yet (`views/dynamics.dsl` is empty)
- Related flows: [Client and Token Registration](client-token-registration.md), [Scheduled Rate Limit Change](scheduled-rate-limit-change.md)
- Runbook: [API Proxy sync troubleshooting](../runbook.md)
