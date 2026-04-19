---
service: "coupons-inventory-service"
title: "Client Authentication"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "client-authentication"
flow_type: synchronous
trigger: "Every incoming API request"
participants:
  - "continuumCouponsInventoryService_auth"
  - "continuumCouponsInventoryService_clientRepository"
  - "continuumCouponsInventoryService_clientCache"
  - "continuumCouponsInventoryService_jdbiInfrastructure"
architecture_ref: "dynamic-client-authentication"
---

# Client Authentication

## Summary

This flow handles authentication and authorization for every incoming API request. The Client Identity & Authorization component (registered as a Jersey filter at bootstrap) intercepts each request, extracts the client identifier, loads the corresponding client record from the Client Repository (backed by an in-memory ConcurrentHashMap cache with Postgres fallback), and either allows the request to proceed or returns an unauthorized response.

## Trigger

- **Type**: api-call
- **Source**: Every incoming HTTP request to any API endpoint
- **Frequency**: per-request (high frequency, on every API call)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Client Identity & Authorization | Jersey filter that intercepts requests and enforces auth | `continuumCouponsInventoryService_auth` |
| Client Repository | Loads client records for authentication and authorization | `continuumCouponsInventoryService_clientRepository` |
| Client Cache | In-memory ConcurrentHashMap cache of client records | `continuumCouponsInventoryService_clientCache` |
| Jdbi Persistence Infrastructure | Database layer for loading client records on cache miss | `continuumCouponsInventoryService_jdbiInfrastructure` |

## Steps

1. **Intercept request**: The Client Identity & Authorization filter (CISAuthenticator / ClientIdAuthFilter) intercepts the incoming HTTP request and extracts the client identifier from request headers.
   - From: `External caller`
   - To: `continuumCouponsInventoryService_auth`
   - Protocol: Jersey filter interception

2. **Load client record**: The auth component requests the client record from the Client Repository.
   - From: `continuumCouponsInventoryService_auth`
   - To: `continuumCouponsInventoryService_clientRepository`
   - Protocol: Jdbi

3. **Check in-memory cache**: The Client Repository checks the in-memory Client Cache for a cached client record.
   - From: `continuumCouponsInventoryService_clientRepository`
   - To: `continuumCouponsInventoryService_clientCache`
   - Protocol: In-process cache lookup

4. **Cache hit path**: If the client record is found in the cache, skip to step 6.

5. **Cache miss -- query database**: On cache miss, the Client Repository queries Postgres via Jdbi to load the client record, then caches it in the Client Cache.
   - From: `continuumCouponsInventoryService_clientRepository`
   - To: `continuumCouponsInventoryService_jdbiInfrastructure`
   - Protocol: Jdbi, Postgres

6. **Authorize request**: The CISAuthorizer checks client permissions against the requested resource and operation. If authorized, the request proceeds to the API resource. If not authorized, an unauthorized response is returned.
   - From: `continuumCouponsInventoryService_auth`
   - To: `API resource (productApi, unitApi, reservationApi, clickApi, availabilityApi)`
   - Protocol: Jersey filter chain

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing client identifier | Auth filter rejects request immediately | Client receives 401 Unauthorized |
| Unknown client ID | Client Repository returns null; auth rejects | Client receives 401 Unauthorized |
| Insufficient permissions | CISAuthorizer denies access | Client receives 403 Forbidden |
| Database unavailable (cache miss) | Jdbi throws exception during client lookup | Client receives 500 Internal Server Error |
| Stale cache entry | Client Cache serves outdated permissions | Request may be incorrectly authorized/denied until service restart clears cache |

## Sequence Diagram

```
Caller -> Auth Filter: HTTP request with client-id header
Auth Filter -> Client Repository: loadClient(clientId)
Client Repository -> Client Cache: get(clientId)
alt cache hit
    Client Cache --> Client Repository: cached client record
else cache miss
    Client Cache --> Client Repository: null
    Client Repository -> Jdbi Infrastructure: SELECT client WHERE id = ?
    Jdbi Infrastructure --> Client Repository: client record
    Client Repository -> Client Cache: put(clientId, clientRecord)
end
Client Repository --> Auth Filter: client record
Auth Filter -> Auth Filter: authorize(client, resource, operation)
alt authorized
    Auth Filter -> API Resource: proceed with request
else unauthorized
    Auth Filter --> Caller: 401/403 response
end
```

## Related

- Architecture component view: `components-continuum-coupons-inventory-service`
- Related flows: All API flows depend on this authentication flow executing first
