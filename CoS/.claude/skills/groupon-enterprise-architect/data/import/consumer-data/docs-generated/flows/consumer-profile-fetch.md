---
service: "consumer-data"
title: "Consumer Profile Fetch"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "consumer-profile-fetch"
flow_type: synchronous
trigger: "HTTP GET /v1/consumers/:id"
participants:
  - "continuumConsumerDataService"
  - "continuumConsumerDataMysql"
architecture_ref: "dynamic-consumer-data-profile-fetch"
---

# Consumer Profile Fetch

## Summary

A calling service or internal consumer sends a GET request to retrieve a single consumer profile by its ID. The service authenticates the request via API client credentials, queries MySQL for the consumer record, and returns the serialised profile. This is the primary read path for consumer data across the Continuum platform.

## Trigger

- **Type**: api-call
- **Source**: Any authorized API client (checkout, order management, or other Continuum services)
- **Frequency**: per-request (high-frequency, on every checkout or profile page load)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API client (caller) | Initiates the profile fetch request | No architecture ref in federated model |
| Consumer Data Service API | Validates request, queries MySQL, serialises response | `continuumConsumerDataService` |
| Consumer Data MySQL | Provides the consumer record | `continuumConsumerDataMysql` |

## Steps

1. **Receive request**: API client sends `GET /v1/consumers/:id` with auth credentials.
   - From: API client
   - To: `continuumConsumerDataService`
   - Protocol: REST / HTTP

2. **Validate auth**: Service verifies API client credentials against the `api_clients` table.
   - From: `continuumConsumerDataService`
   - To: `continuumConsumerDataMysql`
   - Protocol: ActiveRecord / MySQL

3. **Query consumer record**: Service executes SELECT on `consumers` table by primary key.
   - From: `continuumConsumerDataService`
   - To: `continuumConsumerDataMysql`
   - Protocol: ActiveRecord / MySQL

4. **Serialise and return**: Service serialises the ActiveRecord object to JSON using oj and returns HTTP 200.
   - From: `continuumConsumerDataService`
   - To: API client
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Consumer ID not found | Return HTTP 404 | Caller receives not-found response |
| Invalid/missing API credentials | Return HTTP 401 or 403 | Caller receives auth error |
| MySQL connection failure | Return HTTP 500 | Caller receives server error; alert fires |

## Sequence Diagram

```
API Client        -> continuumConsumerDataService: GET /v1/consumers/:id
continuumConsumerDataService -> continuumConsumerDataMysql: SELECT * FROM api_clients WHERE token = ?
continuumConsumerDataMysql   --> continuumConsumerDataService: api_client row
continuumConsumerDataService -> continuumConsumerDataMysql: SELECT * FROM consumers WHERE id = ?
continuumConsumerDataMysql   --> continuumConsumerDataService: consumer row
continuumConsumerDataService --> API Client: HTTP 200 JSON consumer profile
```

## Related

- Architecture dynamic view: `dynamic-consumer-data-profile-fetch`
- Related flows: [Consumer Profile Create/Update](consumer-profile-create-update.md)
