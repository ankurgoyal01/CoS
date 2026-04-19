---
service: "client-id"
title: "Client and Token Registration"
generated: "2026-03-03"
type: flow
flow_name: "client-token-registration"
flow_type: synchronous
trigger: "Operator action via management UI or JSON API"
participants:
  - "continuumClientIdService"
  - "continuumClientIdApiResources"
  - "continuumClientIdPersistence"
  - "continuumClientIdDatabase"
architecture_ref: "dynamic-continuum-client-id"
---

# Client and Token Registration

## Summary

An authorised operator (API admin) creates a new API client record and associates one or more access tokens with it. Tokens are then mapped to named services to define which service endpoints the client can call and at what rate limits. This flow is performed via the HTML management UI or directly via the REST API. All writes go to the primary MySQL database.

## Trigger

- **Type**: user-action (admin via management UI) or api-call
- **Source**: Authorised internal operator via browser (management UI) or HTTP client
- **Frequency**: On-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator (admin) | Initiates client creation; supplies client type, role, owner userId | External actor |
| Client ID Service (API Resources) | Validates and processes HTTP request; delegates to persistence | `continuumClientIdApiResources` |
| Persistence Layer | Executes INSERT statements for client and token records | `continuumClientIdPersistence` |
| MySQL Primary | Stores new client, token, and service-token records | `continuumClientIdDatabase` |

## Steps

1. **Operator loads client creation form**: Operator navigates to `GET /clients/new?userId=<id>`. Client ID Service renders the `ClientEditView` HTML form pre-populated with the owner's user ID.
   - From: Operator browser
   - To: `continuumClientIdService`
   - Protocol: REST (HTTP, `text/html`)

2. **Operator submits new client**: Operator fills out the form and submits `POST /clients`. The API Resources component validates the form data (client type, role, description).
   - From: Operator browser
   - To: `continuumClientIdApiResources`
   - Protocol: REST (HTTP form POST)

3. **Persist client record**: Persistence Layer executes `INSERT INTO api_clients (user_id, role, client_type, description, suspended, created_at, updated_at)`. The new client's auto-generated ID is returned.
   - From: `continuumClientIdPersistence`
   - To: `continuumClientIdDatabase`
   - Protocol: JDBI / MySQL

4. **Operator creates a token for the client**: Operator navigates to `GET /tokens/new?clientId=<new-id>` and submits `POST /tokens` with the token value, rate limits, and status.
   - From: Operator browser
   - To: `continuumClientIdApiResources`
   - Protocol: REST (HTTP)

5. **Persist token record**: Persistence Layer executes `INSERT INTO api_tokens (api_client_id, value, client_rate_limit, ip_rate_limit, status, redirect_host, version_number, updated_at)`.
   - From: `continuumClientIdPersistence`
   - To: `continuumClientIdDatabase`
   - Protocol: JDBI / MySQL

6. **Operator maps token to a service**: Operator navigates to `GET /services/tokens/new?serviceName=<name>&tokenValue=<value>` and submits `POST /services/tokens` to create a service-token mapping with per-service rate limits.
   - From: Operator browser
   - To: `continuumClientIdApiResources`
   - Protocol: REST (HTTP)

7. **Persist service-token mapping**: Persistence Layer executes `INSERT INTO api_service_tokens (api_client_id, api_token_id, service_name, client_rate_limit, ip_rate_limit, status, updated_at)`.
   - From: `continuumClientIdPersistence`
   - To: `continuumClientIdDatabase`
   - Protocol: JDBI / MySQL

8. **API Proxy picks up changes on next sync**: On the next API Proxy sync cycle, the new token's `updated_at` will be after the proxy's cursor, so it will be included in the incremental sync response.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Duplicate token value | Database unique constraint violation | HTTP error returned; operator must supply a different token value |
| Invalid client role or type | Validation at API Resources layer | HTTP 400 returned; form re-rendered with error |
| MySQL primary unavailable | HikariCP connection timeout | HTTP 500 returned; no partial state created if within a transaction |
| Unauthorised operator | OGWall filter blocks request | HTTP 403 returned before processing |

## Sequence Diagram

```
Operator -> continuumClientIdService: GET /clients/new?userId=<id>
continuumClientIdService --> Operator: HTML form (ClientEditView)
Operator -> continuumClientIdApiResources: POST /clients (form data)
continuumClientIdApiResources -> continuumClientIdPersistence: insertClient(client)
continuumClientIdPersistence -> continuumClientIdDatabase: INSERT INTO api_clients
continuumClientIdDatabase --> continuumClientIdPersistence: new client id
continuumClientIdPersistence --> continuumClientIdApiResources: client record
continuumClientIdApiResources --> Operator: redirect to /clients/{id}
Operator -> continuumClientIdApiResources: POST /tokens (tokenValue, rateLimits)
continuumClientIdApiResources -> continuumClientIdPersistence: insertToken(token)
continuumClientIdPersistence -> continuumClientIdDatabase: INSERT INTO api_tokens
continuumClientIdDatabase --> continuumClientIdPersistence: new token id
Operator -> continuumClientIdApiResources: POST /services/tokens (serviceName, tokenValue)
continuumClientIdApiResources -> continuumClientIdPersistence: insertServiceToken(serviceToken)
continuumClientIdPersistence -> continuumClientIdDatabase: INSERT INTO api_service_tokens
```

## Related

- Architecture dynamic view: No dynamic views modeled yet
- Related flows: [API Proxy Token Sync](api-proxy-token-sync.md), [Self-Service Client Registration](self-service-client-registration.md)
