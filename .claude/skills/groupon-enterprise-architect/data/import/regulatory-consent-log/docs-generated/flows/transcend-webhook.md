---
service: "regulatory-consent-log"
title: "Transcend Webhook and Access Upload"
generated: "2026-03-03"
type: flow
flow_name: "transcend-webhook"
flow_type: asynchronous
trigger: "Inbound Transcend webhook POST event (GDPR access or erasure request)"
participants:
  - "continuumRegulatoryConsentLogApi"
  - "continuumRegulatoryConsentLogApi_registerUserEventEndpoint"
  - "continuumRegulatoryConsentLogApi_transcendUsersEventService"
  - "continuumRegulatoryConsentLogApi_registerUserEventDBI"
  - "continuumRegulatoryConsentLogWorker"
  - "continuumRegulatoryConsentLogWorker_asyncUserEventExecutor"
  - "continuumRegulatoryConsentLogWorker_asyncUserEventHandlerService"
  - "continuumRegulatoryConsentLogDb"
  - "transcendPrivacyPlatform"
  - "livingSocialTranscendApi"
  - "lazloApi"
  - "livingSocialLazloApi"
architecture_ref: "dynamic-transcendWebhook"
---

# Transcend Webhook and Access Upload

## Summary

This flow handles inbound GDPR access and erasure request events from the Transcend Privacy Platform. When Transcend sends a webhook callback, the RCL API verifies the JWT signature, records the event, and initiates the appropriate flow (access data retrieval or erasure confirmation). An async Quartz job in the Utility Worker then processes any pending events by uploading user data to the Lazlo API or confirming erasure to the Transcend API, supporting both Groupon and LivingSocial brands.

## Trigger

- **Type**: event (inbound webhook from Transcend Privacy Platform)
- **Source**: Transcend Privacy Platform sends an HTTP POST to the RCL `Register User Event Endpoint` when a GDPR data access or erasure request is initiated.
- **Frequency**: Per GDPR subject rights request received by Groupon via Transcend.

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Transcend Privacy Platform | Sends GDPR access / erasure webhook events | `transcendPrivacyPlatform` |
| Register User Event Endpoint | Receives the webhook POST; validates JWT | `continuumRegulatoryConsentLogApi_registerUserEventEndpoint` |
| Transcend Users Event Service | Verifies JWT signature; routes to erasure or access workflow; persists event record | `continuumRegulatoryConsentLogApi_transcendUsersEventService` |
| Register User Event DBI | Persists user event status and audit records to Postgres | `continuumRegulatoryConsentLogApi_registerUserEventDBI` |
| Regulatory Consent Log Postgres | Stores pending user event records | `continuumRegulatoryConsentLogDb` |
| Async User Event Executor (Worker) | Quartz job that triggers async processing of pending events | `continuumRegulatoryConsentLogWorker_asyncUserEventExecutor` |
| Async User Event Handler Service (Worker) | Processes pending events; uploads data to Lazlo / Transcend | `continuumRegulatoryConsentLogWorker_asyncUserEventHandlerService` |
| Lazlo API | Receives access-data upload for Groupon brand | `lazloApi` |
| LivingSocial Lazlo API | Receives access-data upload for LivingSocial brand | `livingSocialLazloApi` |
| LivingSocial Transcend API | Receives brand-specific erasure confirmations for LivingSocial | `livingSocialTranscendApi` |

## Steps

1. **Transcend sends webhook**: Transcend Privacy Platform POSTs an access or erasure event to the RCL `Register User Event Endpoint`, including a JWT in the request for signature verification.
   - From: `transcendPrivacyPlatform`
   - To: `continuumRegulatoryConsentLogApi_registerUserEventEndpoint`
   - Protocol: REST / HTTP/JSON (webhook)

2. **Verify JWT signature**: The `Transcend Users Event Service` verifies the JWT signature using `java-jwt` (auth0 library) to authenticate the webhook origin.
   - From: `continuumRegulatoryConsentLogApi_registerUserEventEndpoint`
   - To: `continuumRegulatoryConsentLogApi_transcendUsersEventService`
   - Protocol: direct (Java)

3. **Record event**: The `Register User Event DBI` persists the user event record (status: pending, event type, user identifier, audit details) to Postgres.
   - From: `continuumRegulatoryConsentLogApi_transcendUsersEventService`
   - To: `continuumRegulatoryConsentLogApi_registerUserEventDBI` → `continuumRegulatoryConsentLogDb`
   - Protocol: JDBI / SQL

4. **Return acknowledgment**: The endpoint returns an HTTP acknowledgment to Transcend (webhook ACK).
   - From: `continuumRegulatoryConsentLogApi_registerUserEventEndpoint`
   - To: `transcendPrivacyPlatform`
   - Protocol: REST / HTTP/JSON

5. **Async processing — Quartz job fires**: The `Async User Event Executor` Quartz job in the Utility Worker fires periodically, discovers pending user event records in Postgres, and invokes the `Async User Event Handler Service`.
   - From: `continuumRegulatoryConsentLogWorker_asyncUserEventExecutor`
   - To: `continuumRegulatoryConsentLogWorker_asyncUserEventHandlerService`
   - Protocol: direct (Quartz / Java)

6a. **Access request — upload to Lazlo**: For a GDPR access request, the `Async User Event Handler Service` collects consent records and uploads them to the Lazlo API (Groupon brand) or LivingSocial Lazlo API (LivingSocial brand).
   - From: `continuumRegulatoryConsentLogWorker_asyncUserEventHandlerService`
   - To: `lazloApi` or `livingSocialLazloApi`
   - Protocol: REST / HTTP/JSON

6b. **Erasure request — confirm to Transcend**: For a GDPR erasure event, the handler confirms erasure completion to the Transcend Privacy Platform (Groupon brand) or LivingSocial Transcend API.
   - From: `continuumRegulatoryConsentLogWorker_asyncUserEventHandlerService`
   - To: `transcendPrivacyPlatform` or `livingSocialTranscendApi`
   - Protocol: REST / HTTP/JSON

7. **Update event status**: The handler updates the user event record in Postgres to reflect the completed status.
   - From: `continuumRegulatoryConsentLogWorker_asyncUserEventHandlerService`
   - To: `continuumRegulatoryConsentLogDb`
   - Protocol: JDBI / SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid JWT signature | `HTTP 401 Unauthorized` returned to Transcend | Event not recorded |
| Postgres write failure on event record | `HTTP 500` returned; Transcend expected to retry webhook | Event not stored; webhook retried by Transcend |
| Lazlo API unreachable during async upload | Event remains in pending state in Postgres | Retried on next Quartz job execution |
| Transcend API unreachable for erasure confirmation | Event remains in pending state in Postgres | Retried on next Quartz job execution |
| Brand determination failure | Event processing deferred | Manual investigation required |

## Sequence Diagram

```
Transcend -> RegisterUserEventEndpoint: POST webhook (JWT, event payload)
RegisterUserEventEndpoint -> TranscendUsersEventService: Verify JWT and route event
TranscendUsersEventService -> RegisterUserEventDBI: Persist event record (status=pending)
RegisterUserEventDBI -> Postgres: INSERT user_event
Postgres --> RegisterUserEventDBI: OK
RegisterUserEventEndpoint --> Transcend: HTTP 200 ACK

Note over AsyncUserEventExecutor: Quartz job fires periodically in Utility Worker
AsyncUserEventExecutor -> AsyncUserEventHandlerService: Process pending events
AsyncUserEventHandlerService -> Postgres: SELECT pending user_events

alt Access request (Groupon brand)
    AsyncUserEventHandlerService -> LazloAPI: Upload access data
    LazloAPI --> AsyncUserEventHandlerService: OK
else Access request (LivingSocial brand)
    AsyncUserEventHandlerService -> LivingSocialLazloAPI: Upload access data
    LivingSocialLazloAPI --> AsyncUserEventHandlerService: OK
else Erasure confirmation (Groupon brand)
    AsyncUserEventHandlerService -> TranscendPrivacyPlatform: Confirm erasure
    TranscendPrivacyPlatform --> AsyncUserEventHandlerService: OK
else Erasure confirmation (LivingSocial brand)
    AsyncUserEventHandlerService -> LivingSocialTranscendAPI: Confirm erasure
    LivingSocialTranscendAPI --> AsyncUserEventHandlerService: OK
end

AsyncUserEventHandlerService -> Postgres: UPDATE user_event status=completed
```

## Related

- Architecture dynamic view: `dynamic-transcendWebhook`
- Related flows: [User Erasure Pipeline](user-erasure-pipeline.md), [Consent Creation](consent-creation.md)
