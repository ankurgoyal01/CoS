---
service: "consumer-data"
title: "Consumer Profile Create/Update"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "consumer-profile-create-update"
flow_type: synchronous
trigger: "HTTP PUT /v1/consumers/:id"
participants:
  - "continuumConsumerDataService"
  - "continuumConsumerDataMysql"
architecture_ref: "dynamic-consumer-data-profile-update"
---

# Consumer Profile Create/Update

## Summary

A calling service sends a PUT request to create or update a consumer profile. The service validates the request, persists the changes to MySQL, then publishes a consumer change event to both `jms.topic.consumer.v2.consumers` and `jms.topic.consumer.v3.consumers` so that downstream services can react to the updated profile data.

## Trigger

- **Type**: api-call
- **Source**: Checkout services, account management flows, or internal migration tools
- **Frequency**: per-request (on profile edits, checkout updates, backfill operations)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API client (caller) | Submits the profile update payload | No architecture ref in federated model |
| Consumer Data Service API | Validates, persists, and publishes | `continuumConsumerDataService` |
| Consumer Data MySQL | Stores the updated consumer record | `continuumConsumerDataMysql` |
| MessageBus | Delivers change events to downstream consumers | `mbus` (stub) |

## Steps

1. **Receive request**: API client sends `PUT /v1/consumers/:id` with JSON body containing updated profile fields.
   - From: API client
   - To: `continuumConsumerDataService`
   - Protocol: REST / HTTP

2. **Validate auth**: Service verifies API client credentials against `api_clients` table.
   - From: `continuumConsumerDataService`
   - To: `continuumConsumerDataMysql`
   - Protocol: ActiveRecord / MySQL

3. **Validate payload**: Service validates required fields and data types on the incoming JSON body.
   - From: `continuumConsumerDataService`
   - To: `continuumConsumerDataService` (internal)
   - Protocol: direct

4. **Persist consumer record**: Service upserts the consumer row in the `consumers` table via ActiveRecord.
   - From: `continuumConsumerDataService`
   - To: `continuumConsumerDataMysql`
   - Protocol: ActiveRecord / MySQL

5. **Publish change events**: Service publishes a ConsumerUpdated event to `jms.topic.consumer.v2.consumers` and `jms.topic.consumer.v3.consumers`.
   - From: `continuumConsumerDataService`
   - To: MessageBus
   - Protocol: message-bus (messagebus 0.3.7)

6. **Return response**: Service returns HTTP 200 with the updated consumer profile.
   - From: `continuumConsumerDataService`
   - To: API client
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid payload | Return HTTP 422 with validation errors | Caller receives error details; no DB write |
| MySQL write failure | Return HTTP 500 | Caller receives server error; no event published |
| MessageBus publish failure | Event publish fails after DB write | DB updated but downstream out of sync; requires retry or replay |
| Auth failure | Return HTTP 401 or 403 | No write or event |

## Sequence Diagram

```
API Client        -> continuumConsumerDataService: PUT /v1/consumers/:id {profile fields}
continuumConsumerDataService -> continuumConsumerDataMysql: SELECT api_client (auth check)
continuumConsumerDataMysql   --> continuumConsumerDataService: auth ok
continuumConsumerDataService -> continuumConsumerDataMysql: INSERT/UPDATE consumers SET ...
continuumConsumerDataMysql   --> continuumConsumerDataService: write ok
continuumConsumerDataService -> MessageBus: PUBLISH jms.topic.consumer.v2.consumers
continuumConsumerDataService -> MessageBus: PUBLISH jms.topic.consumer.v3.consumers
continuumConsumerDataService --> API Client: HTTP 200 JSON consumer profile
```

## Related

- Architecture dynamic view: `dynamic-consumer-data-profile-update`
- Related flows: [Consumer Profile Fetch](consumer-profile-fetch.md), [Account Creation Async](account-creation-async.md)
