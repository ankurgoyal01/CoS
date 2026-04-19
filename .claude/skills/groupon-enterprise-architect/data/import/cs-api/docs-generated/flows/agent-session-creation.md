---
service: "cs-api"
title: "Agent Session Creation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "agent-session-creation"
flow_type: synchronous
trigger: "Agent login action in Cyclops UI"
participants:
  - "customerSupportAgent"
  - "continuumCsApiService"
  - "csApi_apiResources"
  - "authModule"
  - "serviceClients"
  - "continuumCsTokenService"
  - "cacheClients"
  - "csApiRedis"
architecture_ref: "dynamic-cs-api"
---

# Agent Session Creation

## Summary

This flow handles the creation of an authenticated agent session when a customer support agent logs in to the Cyclops platform. CS API validates the agent's identity by requesting a CS-specific token from `continuumCsTokenService`, validates the JWT, and stores the resulting session in Redis so subsequent requests can be authenticated without a round-trip to the token service.

## Trigger

- **Type**: user-action
- **Source**: Cyclops CS agent web application (POST `/sessions`)
- **Frequency**: On-demand; once per agent login

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cyclops CS Agent App | Initiates session creation request | `customerSupportAgent` |
| CS API Service | Orchestrates session creation | `continuumCsApiService` |
| API Resources | Receives and validates HTTP request | `csApi_apiResources` |
| Auth/JWT Module | Validates and signs JWT | `authModule` |
| Service Clients | Calls CS Token Service | `serviceClients` |
| CS Token Service | Issues CS-specific token | `continuumCsTokenService` |
| Cache Clients | Stores session in Redis | `cacheClients` |
| CS API Redis | Persists session token | `csApiRedis` |

## Steps

1. **Receive login request**: Cyclops sends POST `/sessions` with agent credentials or upstream auth token.
   - From: `customerSupportAgent`
   - To: `csApi_apiResources`
   - Protocol: REST / HTTPS

2. **Validate inbound token**: `authModule` validates the inbound authentication material (JWT or upstream token).
   - From: `csApi_apiResources`
   - To: `authModule`
   - Protocol: Internal

3. **Request CS token**: `serviceClients` calls `continuumCsTokenService` to obtain a CS-scoped token for the agent.
   - From: `serviceClients`
   - To: `continuumCsTokenService`
   - Protocol: HTTP

4. **Sign session JWT**: `authModule` signs a session JWT using the JJWT library with the returned CS token payload.
   - From: `authModule`
   - To: `csApi_apiResources`
   - Protocol: Internal

5. **Store session in Redis**: `cacheClients` writes the session token to `csApiRedis` keyed by session ID.
   - From: `cacheClients`
   - To: `csApiRedis`
   - Protocol: Redis

6. **Return session response**: `csApi_apiResources` returns the session ID and JWT to the Cyclops application.
   - From: `csApi_apiResources`
   - To: `customerSupportAgent`
   - Protocol: REST / HTTPS / JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| CS Token Service unavailable | HTTP call fails; exception propagated | 503 returned to Cyclops; agent cannot log in |
| Invalid agent credentials | `authModule` rejects token | 401 returned to Cyclops |
| Redis write failure | `cacheClients` raises exception | Session not persisted; 500 returned |

## Sequence Diagram

```
CyclopsUI      -> csApi_apiResources  : POST /sessions (credentials)
csApi_apiResources -> authModule      : Validate inbound token
csApi_apiResources -> serviceClients  : Request CS token
serviceClients -> continuumCsTokenService : GET CS token (HTTP)
continuumCsTokenService --> serviceClients : CS token response
serviceClients --> csApi_apiResources : Token received
csApi_apiResources -> authModule      : Sign session JWT
authModule --> csApi_apiResources     : Signed JWT
csApi_apiResources -> cacheClients    : Store session
cacheClients -> csApiRedis            : SET session:<id> (Redis)
csApiRedis --> cacheClients           : OK
csApi_apiResources --> CyclopsUI      : 201 { sessionId, jwt }
```

## Related

- Architecture dynamic view: `dynamic-cs-api` (not yet defined in DSL)
- Related flows: [Agent Ability Check](agent-ability-check.md), [Customer Info Aggregation](customer-info-aggregation.md)
