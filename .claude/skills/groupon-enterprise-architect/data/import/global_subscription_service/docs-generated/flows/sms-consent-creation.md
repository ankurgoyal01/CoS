---
service: "global_subscription_service"
title: "SMS Consent Creation"
generated: "2026-03-03"
type: flow
flow_name: "sms-consent-creation"
flow_type: synchronous
trigger: "HTTP POST to /scs/v1.0/consent/consumer/{consumer_id}"
participants:
  - "globalSubscriptionService"
  - "continuumUserService"
  - "continuumConsentService"
  - "continuumSmsConsentPostgres"
  - "messageBus"
architecture_ref: "components-globalSubscriptionService-components"
---

# SMS Consent Creation

## Summary

This flow handles a consumer opting into SMS notifications for a specific consent type (taxonomy) at a given country and locale. The service validates the consumer's identity, normalizes the phone number, applies double opt-in risk scoring, persists the consent record, and publishes a subscription event to MBus for downstream systems including Rocketman (SMS sending) and the regulatory consent log.

## Trigger

- **Type**: api-call
- **Source**: Mobile app, web frontend, or internal service — `POST /scs/v1.0/consent/consumer/{consumer_id}`
- **Frequency**: On demand (per consumer opt-in action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SMS Consent API Resources | Receives and validates the inbound consent request | `smsConsentApi` |
| Subscription Managers | Orchestrates the consent creation business logic | `subscriptionManagers` |
| External Service Clients | Calls User Service and Consent Service | `externalServiceClients_GloSubSer` |
| User Service | Resolves consumer identity and validates consumer exists | `continuumUserService` |
| Consent Service | Synchronizes consent decision for regulatory compliance | `continuumConsentService` |
| SMS Consent Repository | Persists the consent record to the database | `smsConsentRepository` |
| SMS Consent Postgres | Stores the consent record | `continuumSmsConsentPostgres` |
| Message Bus Publisher | Publishes subscription change event | `globalSubscriptionService_messageBusPublisher` |
| MBus | Routes the event to Rocketman, regulatory-consent-log, and other consumers | `messageBus` |

## Steps

1. **Receive consent request**: The client sends `POST /scs/v1.0/consent/consumer/{consumer_id}` with `country_code`, `locale`, `client_id` query params and a `ConsentRequest` body containing the phone number and consent type UUID.
   - From: Client (mobile app / web frontend)
   - To: `smsConsentApi`
   - Protocol: REST / HTTP

2. **Validate request parameters**: SMS Consent API Resources validate that `country_code`, `locale`, and `client_id` are present and non-null; validates the phone number format using libphonenumber (E.164 normalization).
   - From: `smsConsentApi`
   - To: `subscriptionManagers`
   - Protocol: Direct / Java

3. **Fetch consumer identity**: External Service Clients calls User Service to confirm the consumer UUID is valid and to retrieve account context.
   - From: `externalServiceClients_GloSubSer`
   - To: `continuumUserService`
   - Protocol: REST / HTTP (Retrofit)

4. **Look up consent type**: Subscription Managers queries the consent type cache (then database on miss) to resolve the consent type UUID for the given `country_code`, `locale`, and `client_id`.
   - From: `subscriptionManagers`
   - To: `smsConsentRepository` → `continuumSmsConsentPostgres`
   - Protocol: JDBC / PostgreSQL

5. **Apply risk scoring**: For double opt-in consent types, Subscription Managers invokes `double-optin-riskscoring-lib` to assess whether the phone number/consumer combination should proceed directly or require double opt-in confirmation.
   - From: `subscriptionManagers`
   - To: Risk scoring library (in-process)
   - Protocol: Direct / Java

6. **Persist consent record**: SMS Consent Repository upserts the consent record (consumer UUID, phone UUID, consent type UUID, status, country/locale) into `continuumSmsConsentPostgres`.
   - From: `smsConsentRepository`
   - To: `continuumSmsConsentPostgres`
   - Protocol: JDBC / PostgreSQL

7. **Synchronize with Consent Service**: External Service Clients notifies `continuumConsentService` of the new consent decision for regulatory audit trail.
   - From: `externalServiceClients_GloSubSer`
   - To: `continuumConsentService`
   - Protocol: REST / HTTP (Retrofit)

8. **Publish subscription event**: Message Bus Publisher publishes a subscription change event (CREATE operation) to MBus containing consumer_id, phone_number, consent_type UUID, country_code, locale.
   - From: `globalSubscriptionService_messageBusPublisher`
   - To: `messageBus`
   - Protocol: MBus

9. **Return response**: The API returns HTTP 201 (created) or 200 (already exists) with a `SmsConsentResponse` payload containing the consent record.
   - From: `smsConsentApi`
   - To: Client
   - Protocol: REST / HTTP (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Consumer UUID not found (User Service 404) | Return HTTP 404 with `ErrorResponse` | Consent not created |
| Invalid or unrecognized phone number | libphonenumber normalization fails; return HTTP 400 | Consent not created |
| Unknown phone type in request | Return HTTP 400 `AN_UNKNOWN_PHONE_TYPE_WAS_PASSED` | Consent not created |
| Consent type not found for locale | Return HTTP 404 with `ErrorResponse` | Consent not created |
| Database write failure | Exception propagated; HTTP 500 | Consent not created; no event published |
| Consent Service sync failure | Logged; consent recorded locally; sync retried | Consent created; regulatory sync delayed |
| MBus publish failure | Logged; consent recorded; downstream notification delayed | Consent created; event delivery delayed |

## Sequence Diagram

```
Client -> smsConsentApi: POST /scs/v1.0/consent/consumer/{id}
smsConsentApi -> subscriptionManagers: process consent request
subscriptionManagers -> continuumUserService: GET /consumer/{id}
continuumUserService --> subscriptionManagers: consumer details
subscriptionManagers -> continuumSmsConsentPostgres: lookup consent type
continuumSmsConsentPostgres --> subscriptionManagers: consent type record
subscriptionManagers -> riskScoringLib: score double-opt-in risk
riskScoringLib --> subscriptionManagers: risk score / decision
subscriptionManagers -> continuumSmsConsentPostgres: upsert consent record
continuumSmsConsentPostgres --> subscriptionManagers: OK
subscriptionManagers -> continuumConsentService: sync consent decision
continuumConsentService --> subscriptionManagers: OK
subscriptionManagers -> messageBus: publish subscription CREATE event
messageBus --> subscriptionManagers: acknowledged
smsConsentApi --> Client: 201 Created / SmsConsentResponse
```

## Related

- Architecture dynamic view: No dynamic view defined — see `components-globalSubscriptionService-components`
- Related flows: [SMS Consent Removal](sms-consent-removal.md), [Automatic Subscription via MBus Event](auto-subscription-event.md)
