---
service: "client-id"
title: "Client Search and Lookup"
generated: "2026-03-03"
type: flow
flow_name: "client-search-lookup"
flow_type: synchronous
trigger: "API call from API Lazlo or internal tooling"
participants:
  - "continuumClientIdService"
  - "continuumClientIdApiResources"
  - "continuumClientIdPersistence"
  - "continuumClientIdReadReplica"
architecture_ref: "dynamic-continuum-client-id"
---

# Client Search and Lookup

## Summary

Client ID Service exposes a multi-field search API used by API Lazlo and internal tooling to look up client records and their associated tokens. Search can be performed by token value, email address, client role, or `updated_at` timestamp. The search API is served from the MySQL read replica. Both v1 (HTML + JSON, `/search`) and v2 (JSON-only, `/v2/search`, `/v2/search/tokens`) surfaces are available.

## Trigger

- **Type**: api-call
- **Source**: API Lazlo, internal management tooling, or operator via management UI
- **Frequency**: On-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Caller (API Lazlo / internal tooling) | Sends search request with field and value parameters | External consumer |
| API Resources | Validates query parameters; delegates to persistence | `continuumClientIdApiResources` |
| Persistence Layer | Executes filtered SQL queries using `SearchResource` / `JoinDao` | `continuumClientIdPersistence` |
| MySQL Read Replica | Source of client and token data for search queries | `continuumClientIdReadReplica` |

## Steps

1. **Caller sends search request**: Caller issues `GET /v2/search` (or `/v2/search/tokens` for token-centric results) with query parameters:
   - `field`: one of `TOKEN_VALUE`, `EMAIL_ADDRESS`, `CLIENT_ROLE`, `UPDATED_AT`, `UNKNOWN`
   - `value`: the search value (PII class 4 for email addresses)
   - `clientStatus`: `ACTIVE`, `SUSPENDED`, or `EITHER`
   - `getAll`: boolean — fetch all records when true (ignores `field`/`value`)
   - `excludeRole`: boolean — omit role information from response
   - From: API Lazlo / tooling
   - To: `continuumClientIdService`
   - Protocol: REST (HTTPS / JSON)

2. **API Resources validates parameters**: The `SearchResource` component parses the `SearchField` enum and `ClientStatus` enum from query parameters and assembles a `GetClientsParams` or `GetTokensParams` object.
   - From: `continuumClientIdApiResources`
   - To: In-process parameter binding
   - Protocol: In-process

3. **Execute search query on read replica**: Persistence Layer executes the appropriate JDBI query on `continuumClientIdReadReplica`. For token-value search, it uses `tokenValue = :value`; for email address, it joins to the users table; for `UPDATED_AT`, it filters `updated_at > :value`.
   - From: `continuumClientIdPersistence`
   - To: `continuumClientIdReadReplica`
   - Protocol: JDBI / MySQL

4. **Map and assemble result**: `ClientsSearchViewMapper` / `SearchViewMapper` maps the raw join rows to the `ClientsSearchView` (for `/v2/search`) or `TokenSearchView` (for `/v2/search/tokens`). `DecoratedClientView` enriches results with associated tokens and user info.
   - From: `continuumClientIdPersistence`
   - To: `continuumClientIdApiResources`
   - Protocol: In-process

5. **Return JSON response**: API Resources serialises the result view to JSON and returns HTTP 200.
   - From: `continuumClientIdApiResources`
   - To: Caller
   - Protocol: REST (HTTPS / JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Read replica unavailable | HikariCP connection timeout (40000ms) | HTTP 500 returned to caller |
| Invalid `field` enum value | JAX-RS parameter binding error | HTTP 400 returned |
| No results found | Empty list returned | HTTP 200 with empty array |
| `field=EMAIL_ADDRESS` with PII value | `value` param has `x-personal-data-class: class4`; handled at the data governance level | Normal query execution; PII handling governed externally |

## Sequence Diagram

```
Caller -> continuumClientIdService: GET /v2/search?field=TOKEN_VALUE&value=<token>&clientStatus=ACTIVE
continuumClientIdApiResources -> continuumClientIdPersistence: search(GetClientsParams{field=TOKEN_VALUE, value=<token>, status=ACTIVE})
continuumClientIdPersistence -> continuumClientIdReadReplica: SELECT clients+tokens WHERE token.value=<token> AND status=ACTIVE
continuumClientIdReadReplica --> continuumClientIdPersistence: join rows (ClientTokenJoinRow[])
continuumClientIdPersistence --> continuumClientIdApiResources: ClientsSearchView
continuumClientIdApiResources --> Caller: HTTP 200 JSON (ClientsSearchView)
```

## Related

- Architecture dynamic view: No dynamic views modeled yet
- Related flows: [API Proxy Token Sync](api-proxy-token-sync.md)
- API surface: [Search endpoints](../api-surface.md)
