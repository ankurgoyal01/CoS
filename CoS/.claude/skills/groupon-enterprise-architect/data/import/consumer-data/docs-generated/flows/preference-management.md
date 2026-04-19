---
service: "consumer-data"
title: "Preference Management"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "preference-management"
flow_type: synchronous
trigger: "HTTP requests on /v1/preferences"
participants:
  - "continuumConsumerDataService"
  - "continuumConsumerDataMysql"
architecture_ref: "dynamic-consumer-data-preference-management"
---

# Preference Management

## Summary

Callers use the `/v1/preferences` endpoints to manage key-value preference records for a consumer. Preferences are persisted directly to MySQL and do not involve external enrichment. This is a straightforward CRUD flow with no async event publishing beyond what the platform standard dictates.

## Trigger

- **Type**: api-call
- **Source**: Consumer profile management flows, personalisation services
- **Frequency**: per-request (on preference save or update in consumer settings)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API client (caller) | Initiates preference CRUD requests | No architecture ref in federated model |
| Consumer Data Service API | Handles request, persists to MySQL, returns response | `continuumConsumerDataService` |
| Consumer Data MySQL | Stores preference records | `continuumConsumerDataMysql` |

## Steps

1. **Receive request**: API client sends GET, POST, PUT, or DELETE to `/v1/preferences` with auth credentials and consumer context.
   - From: API client
   - To: `continuumConsumerDataService`
   - Protocol: REST / HTTP

2. **Validate auth**: Service verifies API client credentials against the `api_clients` table.
   - From: `continuumConsumerDataService`
   - To: `continuumConsumerDataMysql`
   - Protocol: ActiveRecord / MySQL

3. **For GET**: Query `preferences` table for the consumer's preference records and return serialised JSON.
   - From: `continuumConsumerDataService`
   - To: `continuumConsumerDataMysql`
   - Protocol: ActiveRecord / MySQL

4. **For POST/PUT**: Validate preference payload and insert or update the matching row in `preferences` table.
   - From: `continuumConsumerDataService`
   - To: `continuumConsumerDataMysql`
   - Protocol: ActiveRecord / MySQL

5. **For DELETE**: Delete the target preference row from the `preferences` table.
   - From: `continuumConsumerDataService`
   - To: `continuumConsumerDataMysql`
   - Protocol: ActiveRecord / MySQL

6. **Return response**: Service returns HTTP 200 for GET/PUT, 201 for POST, 204 for DELETE with serialised result or empty body.
   - From: `continuumConsumerDataService`
   - To: API client
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Preference not found (PUT/DELETE) | Return HTTP 404 | No write |
| Invalid payload | Return HTTP 422 | No write |
| MySQL write failure | Return HTTP 500 | Preference not saved |
| Auth failure | Return HTTP 401 or 403 | No action |

## Sequence Diagram

```
API Client        -> continuumConsumerDataService: GET /v1/preferences?consumer_id=...
continuumConsumerDataService -> continuumConsumerDataMysql: SELECT api_client (auth)
continuumConsumerDataMysql   --> continuumConsumerDataService: auth ok
continuumConsumerDataService -> continuumConsumerDataMysql: SELECT * FROM preferences WHERE consumer_id = ?
continuumConsumerDataMysql   --> continuumConsumerDataService: preference rows
continuumConsumerDataService --> API Client: HTTP 200 JSON preferences
```

## Related

- Architecture dynamic view: `dynamic-consumer-data-preference-management`
- Related flows: [Location Management](location-management.md), [Consumer Profile Fetch](consumer-profile-fetch.md)
