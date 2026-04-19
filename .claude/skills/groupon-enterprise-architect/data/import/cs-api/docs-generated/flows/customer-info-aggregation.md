---
service: "cs-api"
title: "Customer Info Aggregation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "customer-info-aggregation"
flow_type: synchronous
trigger: "Agent opens customer record in Cyclops UI"
participants:
  - "customerSupportAgent"
  - "continuumCsApiService"
  - "csApi_apiResources"
  - "serviceClients"
  - "cacheClients"
  - "continuumUsersService"
  - "continuumConsumerDataService"
  - "continuumAudienceManagementService"
  - "continuumCsRedisCache"
architecture_ref: "dynamic-cs-api"
---

# Customer Info Aggregation

## Summary

This flow assembles a unified customer profile for a CS agent by fanning out to multiple Continuum services. When an agent opens a customer record, CS API concurrently (or sequentially) fetches user account data, consumer profile data, and audience segment information, then merges the results into a single response. Aggregated data may be cached in `continuumCsRedisCache` to reduce downstream load on repeat views.

## Trigger

- **Type**: api-call
- **Source**: Cyclops CS agent web application (GET `/customer-attributes`)
- **Frequency**: On-demand; each time an agent opens or refreshes a customer record

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cyclops CS Agent App | Requests customer data | `customerSupportAgent` |
| CS API Service | Orchestrates aggregation | `continuumCsApiService` |
| API Resources | Handles HTTP request; assembles response | `csApi_apiResources` |
| Service Clients | Issues downstream HTTP calls | `serviceClients` |
| Cache Clients | Reads/writes aggregated result from/to Redis | `cacheClients` |
| Users Service | Provides user account and profile data | `continuumUsersService` |
| Consumer Data Service | Provides consumer preferences and profile | `continuumConsumerDataService` |
| Audience Management Service | Provides audience segments and attributes | `continuumAudienceManagementService` |
| CS Redis Shared Cache | Caches aggregated customer data | `continuumCsRedisCache` |

## Steps

1. **Receive customer attributes request**: Cyclops sends GET `/customer-attributes?customerId=<id>`.
   - From: `customerSupportAgent`
   - To: `csApi_apiResources`
   - Protocol: REST / HTTPS

2. **Check cache**: `cacheClients` checks `continuumCsRedisCache` for a cached aggregated result.
   - From: `cacheClients`
   - To: `continuumCsRedisCache`
   - Protocol: Redis

3. **Fetch user account data** (on cache miss): `serviceClients` queries `continuumUsersService` for account and profile information.
   - From: `serviceClients`
   - To: `continuumUsersService`
   - Protocol: HTTP

4. **Fetch consumer profile data** (on cache miss): `serviceClients` queries `continuumConsumerDataService` for preference and consumer data.
   - From: `serviceClients`
   - To: `continuumConsumerDataService`
   - Protocol: HTTP

5. **Fetch audience segments** (on cache miss): `serviceClients` queries `continuumAudienceManagementService` for audience membership.
   - From: `serviceClients`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTP

6. **Assemble aggregated response**: `csApi_apiResources` merges user, consumer, and audience data into a single customer attributes object.
   - From: `csApi_apiResources`
   - To: `csApi_apiResources`
   - Protocol: Internal

7. **Write to cache**: `cacheClients` writes the merged result to `continuumCsRedisCache`.
   - From: `cacheClients`
   - To: `continuumCsRedisCache`
   - Protocol: Redis

8. **Return aggregated customer data**: Response returned to Cyclops.
   - From: `csApi_apiResources`
   - To: `customerSupportAgent`
   - Protocol: REST / HTTPS / JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Users Service unavailable | HTTP call fails | Partial response returned or 503; agent sees incomplete profile |
| Consumer Data Service unavailable | HTTP call fails | Partial response returned; consumer preferences missing |
| Audience Management unavailable | HTTP call fails | Partial response returned; audience segments missing |
| Cache read failure | Proceeds without cache | Full downstream fan-out occurs; degraded latency |

## Sequence Diagram

```
CyclopsUI      -> csApi_apiResources  : GET /customer-attributes?customerId=X
csApi_apiResources -> cacheClients    : Check cache
cacheClients -> continuumCsRedisCache : GET customer:X (Redis)
continuumCsRedisCache --> cacheClients : Cache miss
csApi_apiResources -> serviceClients  : Fetch user data
serviceClients -> continuumUsersService : GET user (HTTP)
continuumUsersService --> serviceClients : User data
csApi_apiResources -> serviceClients  : Fetch consumer data
serviceClients -> continuumConsumerDataService : GET consumer (HTTP)
continuumConsumerDataService --> serviceClients : Consumer data
csApi_apiResources -> serviceClients  : Fetch audience segments
serviceClients -> continuumAudienceManagementService : GET audience (HTTP)
continuumAudienceManagementService --> serviceClients : Audience data
csApi_apiResources -> cacheClients    : Write aggregated result
cacheClients -> continuumCsRedisCache : SET customer:X (Redis)
csApi_apiResources --> CyclopsUI      : 200 { customerAttributes }
```

## Related

- Architecture dynamic view: `dynamic-cs-api` (not yet defined in DSL)
- Related flows: [Agent Session Creation](agent-session-creation.md), [Deal and Order Inquiry](deal-order-inquiry.md)
