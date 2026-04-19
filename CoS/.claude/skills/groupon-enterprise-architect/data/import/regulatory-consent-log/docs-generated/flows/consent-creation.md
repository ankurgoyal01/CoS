---
service: "regulatory-consent-log"
title: "Consent Creation"
generated: "2026-03-03"
type: flow
flow_name: "consent-creation"
flow_type: synchronous
trigger: "POST /v1/consents from a consumer-facing service (Registration, Checkout, Subscription Modal)"
participants:
  - "continuumRegulatoryConsentLogApi"
  - "continuumRegulatoryConsentLogApi_createConsentEndpoint"
  - "continuumRegulatoryConsentLogApi_createConsentService"
  - "continuumRegulatoryConsentLogApi_createConsentTransactionAdapter"
  - "continuumRegulatoryConsentLogDb"
  - "continuumRegulatoryConsentMessageBus"
architecture_ref: "dynamic-consentCreation"
---

# Consent Creation

## Summary

This flow records one or more user consent entries when a consumer-facing action (registration, checkout, email subscription) occurs. The API validates the request, maps payloads to internal models, writes consent rows and a Cronus MBus outbox row atomically to Postgres, and returns immediately. The Cronus Publisher Quartz job (running in the Utility Worker) then picks up the outbox row and publishes the consent log message to the Message Bus asynchronously.

## Trigger

- **Type**: api-call
- **Source**: Consumer-facing services (Registration service, Checkout service, Subscription Modal service) calling `POST /v1/consents` — typically routed through API-Lazlo as a proxy.
- **Frequency**: Per user action (registration, checkout, subscription, cookie acceptance, etc.)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Upstream service (e.g. API-Lazlo) | Routes the `POST /v1/consents` call from consumer flows | External caller |
| Create Consent Endpoint | Receives the HTTP request; validates identifier/consumer rules | `continuumRegulatoryConsentLogApi_createConsentEndpoint` |
| Create Consent Service | Maps `CreateConsentRequestBody` items to internal `CoreModel` objects | `continuumRegulatoryConsentLogApi_createConsentService` |
| Create Consent Transaction Adapter | Atomically persists consent DB rows and Cronus outbox rows | `continuumRegulatoryConsentLogApi_createConsentTransactionAdapter` |
| Regulatory Consent Log Postgres | Stores consent rows and `mbus_messages` outbox rows | `continuumRegulatoryConsentLogDb` |
| Cronus Publisher (Worker) | Periodically reads outbox rows and publishes to MBus | `continuumRegulatoryConsentLogWorker_cronusPublisher` |
| Regulatory Message Bus | Receives published consent log messages | `continuumRegulatoryConsentMessageBus` |

## Steps

1. **Receive request**: Upstream service sends `POST /v1/consents` with `X-API-KEY`, `X-Country-Code`, `X-Locale`, and a JSON body containing a `legalConsents` array.
   - From: upstream service (e.g. API-Lazlo)
   - To: `continuumRegulatoryConsentLogApi_createConsentEndpoint`
   - Protocol: REST / HTTP/JSON

2. **Build consent params**: The endpoint assembles a `CreateConsentParams` object combining the request body with headers (`countryCode`, `locale`, `xClientRole`, `xRemoteUserAgent`, `isConsumerId`).
   - From: `continuumRegulatoryConsentLogApi_createConsentEndpoint`
   - To: `continuumRegulatoryConsentLogApi_createConsentEndpoint` (internal)
   - Protocol: direct

3. **Validate identifier/consumer rule**: If any consent item uses `identifierType = user_id` and `isConsumerId` is not `true`, the endpoint returns `HTTP 400 Bad Request` immediately.
   - From: `continuumRegulatoryConsentLogApi_createConsentEndpoint`
   - To: upstream caller
   - Protocol: REST (error path)

4. **Map to core models**: The `Create Consent Service` converts each `CreateConsentItem` to a `CoreModel` row, injecting context fields (country, locale, client role, user agent).
   - From: `continuumRegulatoryConsentLogApi_createConsentEndpoint`
   - To: `continuumRegulatoryConsentLogApi_createConsentService`
   - Protocol: direct (Java function composition)

5. **Persist atomically**: The `Create Consent Transaction Adapter` writes all consent rows and the corresponding Cronus `mbus_messages` outbox row(s) in a single JDBI transaction to Postgres.
   - From: `continuumRegulatoryConsentLogApi_createConsentService`
   - To: `continuumRegulatoryConsentLogApi_createConsentTransactionAdapter` → `continuumRegulatoryConsentLogDb`
   - Protocol: JDBI / SQL

6. **Return 200**: Endpoint returns `HTTP 200 OK` with the original `CreateConsentRequestBody` as the response body.
   - From: `continuumRegulatoryConsentLogApi_createConsentEndpoint`
   - To: upstream caller
   - Protocol: REST / HTTP/JSON

7. **Async MBus publish (Worker)**: The Cronus Publisher Quartz job in the Utility Worker periodically (approximately every minute) reads pending `mbus_messages` outbox rows from Postgres and publishes them as `ErasureMessage` payloads to the MBus consent log topic, updating `processing_status` and `attempted_at`.
   - From: `continuumRegulatoryConsentLogWorker_cronusPublisher`
   - To: `continuumRegulatoryConsentMessageBus`
   - Protocol: MBus (ActiveMQ Artemis)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `user_id` identifier type without `isConsumerId=true` | Returns `HTTP 400 Bad Request` immediately | Consent not recorded |
| Postgres write failure | JDBI transaction rolls back atomically | No partial consent or outbox row created; upstream receives `HTTP 500` |
| MBus publish failure (from Cronus) | Outbox row `processing_status` updated; retried on next Quartz run (with `attempts` counter and `attempted_at` timestamp) | Consent DB row is already persisted; MBus message retried up to configured attempt limit |
| Invalid API key | `HTTP 401 Unauthorized` | Consent not recorded |

## Sequence Diagram

```
UpstreamService -> CreateConsentEndpoint: POST /v1/consents (X-API-KEY, X-Country-Code, X-Locale, body)
CreateConsentEndpoint -> CreateConsentEndpoint: Build CreateConsentParams; validate identifier/consumer rule
CreateConsentEndpoint -> CreateConsentService: Apply CoreModel mapping
CreateConsentService -> CreateConsentTransactionAdapter: Persist consent rows + outbox rows
CreateConsentTransactionAdapter -> Postgres: INSERT regulatory_consent_logs, mbus_messages (atomic transaction)
Postgres --> CreateConsentTransactionAdapter: Rows committed
CreateConsentTransactionAdapter --> CreateConsentService: Success
CreateConsentService --> CreateConsentEndpoint: CoreModels returned
CreateConsentEndpoint --> UpstreamService: HTTP 200 OK (request body echoed)

Note over CronusPublisher,MessageBus: Async — runs in Utility Worker ~every minute
CronusPublisher -> Postgres: SELECT pending mbus_messages rows
Postgres --> CronusPublisher: Outbox rows
CronusPublisher -> MessageBus: Publish ErasureMessage payloads
MessageBus --> CronusPublisher: ACK
CronusPublisher -> Postgres: UPDATE processing_status = published
```

## Related

- Architecture dynamic view: `dynamic-consentCreation`
- Related flows: [Consent Retrieval](consent-retrieval.md), [User Erasure Pipeline](user-erasure-pipeline.md)
