---
service: "global_subscription_service"
title: "Push Token Registration"
generated: "2026-03-03"
type: flow
flow_name: "push-token-registration"
flow_type: synchronous
trigger: "HTTP POST to /push-token/device-token"
participants:
  - "globalSubscriptionService"
  - "continuumPushTokenPostgres"
  - "continuumPushTokenCassandra"
  - "kafkaCluster"
architecture_ref: "components-globalSubscriptionService-components"
---

# Push Token Registration

## Summary

This flow handles the registration of a new push notification device token from a mobile client. The service accepts the token, consumer association, device type, and country context, writes the record to both the primary PostgreSQL store and the legacy Cassandra store (during the migration period), and publishes a push token create event to Kafka for downstream push notification routing services.

## Trigger

- **Type**: api-call
- **Source**: Mobile app (consumer, enterprise, or Asia consumer app types)
- **Frequency**: On demand — when a user installs or re-activates the Groupon app on a device

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Push Token API Resources | Receives and validates the token registration request | `pushTokenApi` |
| Push Token Service | Orchestrates the token creation business logic | `pushTokenService` |
| Push Token DAO | Persists the token to PostgreSQL and Cassandra | `pushTokenDao` |
| Postgres Client | Executes SQL insert/upsert for push token data | `postgresClient_GloSubSer` |
| Cassandra Client | Writes to legacy Cassandra push token store | `cassandraClient_GloSubSer` |
| Push Token Postgres | Primary push token store | `continuumPushTokenPostgres` |
| Push Token Cassandra | Legacy push token store | `continuumPushTokenCassandra` |
| Kafka Publisher | Publishes push token create event to Kafka | `globalSubscriptionService_kafkaPublisher` |
| Kafka cluster | Delivers event to push notification routing consumers | `kafkaCluster_unknown_2f91` |

## Steps

1. **Receive token registration request**: Mobile client sends `POST /push-token/device-token` with a `CreatePushDeviceTokenRequest` body. Headers: `X-REMOTE-USER-AGENT` (app type classification), `X-BRAND` (brand context), `X-COUNTRY-CODE` (country).
   - From: Mobile app client
   - To: `pushTokenApi`
   - Protocol: REST / HTTP

2. **Validate request**: Push Token API validates the request body (device token value, consumer_id UUID, app_type enum: consumer / enterprise / asia_consumer). Returns HTTP 400 if JSON is unparseable.
   - From: `pushTokenApi`
   - To: `pushTokenService`
   - Protocol: Direct / Java

3. **Write token to PostgreSQL**: Push Token DAO upserts the push device token record into `continuumPushTokenPostgres` with status `activating` (initial registration state).
   - From: `pushTokenDao` → `postgresClient_GloSubSer`
   - To: `continuumPushTokenPostgres`
   - Protocol: JDBC / PostgreSQL

4. **Write token to Cassandra** (migration period): Cassandra Client writes the same token record to `continuumPushTokenCassandra` for backward compatibility.
   - From: `pushTokenDao` → `cassandraClient_GloSubSer`
   - To: `continuumPushTokenCassandra`
   - Protocol: Cassandra protocol

5. **Publish push token create event**: Kafka Publisher publishes a push token create event to the Kafka cluster (endpoint: `KAFKA_ENDPOINT`) over TLS, containing device_token, consumer_id, app_type, country_code, status.
   - From: `globalSubscriptionService_kafkaPublisher`
   - To: Kafka cluster
   - Protocol: Kafka TLS

6. **Return response**: API returns HTTP 200 with the created `PushDeviceToken` record (including assigned status and metadata).
   - From: `pushTokenApi`
   - To: Mobile app client
   - Protocol: REST / HTTP (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unparseable JSON body | Return HTTP 400 `Unable to process JSON` | Token not registered |
| Kafka TLS connection failure | Logged; token written to DB; event delivery delayed | Token registered in DB; downstream notification delayed |
| PostgreSQL write failure | Exception propagated; HTTP 500 | Token not registered; no event published |
| Cassandra write failure | Logged; PostgreSQL record preserved | Token registered in Postgres; Cassandra copy may be absent |
| Invalid division UUID | Return HTTP 400 | Token not registered |

## Sequence Diagram

```
MobileApp -> pushTokenApi: POST /push-token/device-token
pushTokenApi -> pushTokenService: create token request
pushTokenService -> continuumPushTokenPostgres: UPSERT push_device_tokens
continuumPushTokenPostgres --> pushTokenService: OK
pushTokenService -> continuumPushTokenCassandra: write legacy token record
continuumPushTokenCassandra --> pushTokenService: OK
pushTokenService -> kafkaCluster: publish push token CREATE event
kafkaCluster --> pushTokenService: acknowledged
pushTokenApi --> MobileApp: 200 OK / PushDeviceToken[]
```

## Related

- Architecture dynamic view: No dynamic view defined — see `components-globalSubscriptionService-components`
- Related flows: [Push Token Data Migration](push-token-data-migration.md)
