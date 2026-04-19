---
service: "consumer-data"
title: "Location Management"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "location-management"
flow_type: synchronous
trigger: "HTTP requests on /v1/locations"
participants:
  - "continuumConsumerDataService"
  - "continuumConsumerDataMysql"
architecture_ref: "dynamic-consumer-data-location-management"
---

# Location Management

## Summary

Callers use the `/v1/locations` endpoints to create, read, update, and delete physical addresses associated with a consumer. On location writes, the service optionally calls bhoomi to enrich the address with geographic details before persisting to MySQL. After a successful write, a `LocationChanged` event is published to `jms.topic.consumer.v2.locations` to notify downstream services.

## Trigger

- **Type**: api-call
- **Source**: Checkout services, consumer profile management flows
- **Frequency**: per-request (on address save or update at checkout or in profile settings)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API client (caller) | Initiates location CRUD requests | No architecture ref in federated model |
| Consumer Data Service API | Handles request, enriches via bhoomi, persists, publishes | `continuumConsumerDataService` |
| bhoomi | Provides GeoDetails for address enrichment | `bhoomi` (stub) |
| Consumer Data MySQL | Stores location records | `continuumConsumerDataMysql` |
| MessageBus | Delivers location change events to downstream services | `mbus` (stub) |

## Steps

1. **Receive request**: API client sends GET, POST, PUT, or DELETE to `/v1/locations` with auth credentials.
   - From: API client
   - To: `continuumConsumerDataService`
   - Protocol: REST / HTTP

2. **Validate auth**: Service verifies API client credentials against the `api_clients` table.
   - From: `continuumConsumerDataService`
   - To: `continuumConsumerDataMysql`
   - Protocol: ActiveRecord / MySQL

3. **For GET**: Query `locations` table for the consumer's location records and return serialised JSON (flow ends here for reads).
   - From: `continuumConsumerDataService`
   - To: `continuumConsumerDataMysql`
   - Protocol: ActiveRecord / MySQL

4. **For POST/PUT — Enrich location via bhoomi**: Service calls bhoomi with address fields to retrieve geographic details (city, region, coordinates).
   - From: `continuumConsumerDataService`
   - To: bhoomi
   - Protocol: REST / HTTP (typhoeus)

5. **Persist location record**: Service inserts or updates the location row in MySQL with enriched geo fields.
   - From: `continuumConsumerDataService`
   - To: `continuumConsumerDataMysql`
   - Protocol: ActiveRecord / MySQL

6. **For DELETE**: Service deletes the location row from MySQL.
   - From: `continuumConsumerDataService`
   - To: `continuumConsumerDataMysql`
   - Protocol: ActiveRecord / MySQL

7. **Publish location change event**: Service publishes `LocationChanged` to `jms.topic.consumer.v2.locations`.
   - From: `continuumConsumerDataService`
   - To: MessageBus
   - Protocol: message-bus

8. **Return response**: Service returns appropriate HTTP response (200 for GET/PUT, 201 for POST, 204 for DELETE).
   - From: `continuumConsumerDataService`
   - To: API client
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| bhoomi unavailable | Geo enrichment skipped; location saved without enrichment | Degraded but functional; no error to caller |
| MySQL write failure | Return HTTP 500 | No event published; location not saved |
| Location not found (PUT/DELETE) | Return HTTP 404 | No write or event |
| Auth failure | Return HTTP 401 or 403 | No action taken |

## Sequence Diagram

```
API Client        -> continuumConsumerDataService: POST /v1/locations {address fields}
continuumConsumerDataService -> continuumConsumerDataMysql: SELECT api_client (auth)
continuumConsumerDataMysql   --> continuumConsumerDataService: auth ok
continuumConsumerDataService -> bhoomi: GET /geodetails?address=...
bhoomi           --> continuumConsumerDataService: {city, region, coordinates}
continuumConsumerDataService -> continuumConsumerDataMysql: INSERT INTO locations (consumer_id, ...) VALUES (...)
continuumConsumerDataMysql   --> continuumConsumerDataService: write ok
continuumConsumerDataService -> MessageBus: PUBLISH jms.topic.consumer.v2.locations
continuumConsumerDataService --> API Client: HTTP 201 JSON location
```

## Related

- Architecture dynamic view: `dynamic-consumer-data-location-management`
- Related flows: [Consumer Profile Create/Update](consumer-profile-create-update.md), [Preference Management](preference-management.md)
