---
service: "global_subscription_service"
title: "SMS Consent Removal (GDPR Unsubscribe)"
generated: "2026-03-03"
type: flow
flow_name: "sms-consent-removal"
flow_type: synchronous
trigger: "HTTP DELETE to /scs/v1.0/consent/consumer/{consumer_id}/consent_type/all or per-type variant"
participants:
  - "globalSubscriptionService"
  - "continuumConsentService"
  - "continuumSmsConsentPostgres"
  - "messageBus"
architecture_ref: "components-globalSubscriptionService-components"
---

# SMS Consent Removal (GDPR Unsubscribe)

## Summary

This flow removes SMS consent records for a consumer or phone number, either for all consent types or for a specific consent type. It is used for GDPR right-to-erasure and standard opt-out requests. The service removes the consent record from its database, notifies the Consent Service for regulatory logging, and publishes a GDPR unsubscribe event to MBus so that downstream systems (Rocketman, regulatory-consent-log) can update their own state.

## Trigger

- **Type**: api-call
- **Source**: Consumer-facing frontend, internal compliance tooling, or automated GDPR pipeline
- **Frequency**: On demand (per opt-out or GDPR erasure request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SMS Consent API Resources | Receives and validates the unsubscribe request | `smsConsentApi` |
| Subscription Managers | Orchestrates the removal business logic | `subscriptionManagers` |
| External Service Clients | Calls Consent Service for regulatory sync | `externalServiceClients_GloSubSer` |
| Consent Service | Receives consent removal for regulatory audit trail | `continuumConsentService` |
| SMS Consent Repository | Removes consent records from the database | `smsConsentRepository` |
| SMS Consent Postgres | Stores updated (removed) consent state | `continuumSmsConsentPostgres` |
| Message Bus Publisher | Publishes GDPR unsubscribe event | `globalSubscriptionService_messageBusPublisher` |
| MBus | Routes event to regulatory-consent-log and other consumers | `messageBus` |

## Steps

1. **Receive unsubscribe request**: Client calls one of the DELETE endpoints — by consumer UUID (all or per-type), or by phone number (body-based preferred variants). Query params: `country_code`, `locale`, `client_id`. Request body (`AdditionalAttributesRequest`) carries phone number for phone-based unsubscribes.
   - From: Client
   - To: `smsConsentApi`
   - Protocol: REST / HTTP

2. **Validate request**: API validates `consumer_id` (UUID format) or phone number (E.164 if path-based, or from body); validates `consent_type_uuid` if present.
   - From: `smsConsentApi`
   - To: `subscriptionManagers`
   - Protocol: Direct / Java

3. **Resolve consent records**: Subscription Managers queries SMS Consent Repository for the consumer's or phone's active consent records matching the specified country/locale/client scope.
   - From: `subscriptionManagers`
   - To: `smsConsentRepository` → `continuumSmsConsentPostgres`
   - Protocol: JDBC / PostgreSQL

4. **Remove consent records**: SMS Consent Repository soft-deletes or marks as unsubscribed the matching consent records in `continuumSmsConsentPostgres`. For bulk removal, all active consents are removed; for per-type, only the specified consent type is removed.
   - From: `smsConsentRepository`
   - To: `continuumSmsConsentPostgres`
   - Protocol: JDBC / PostgreSQL

5. **Synchronize with Consent Service**: External Service Clients notifies `continuumConsentService` of the consent removal for the regulatory audit log.
   - From: `externalServiceClients_GloSubSer`
   - To: `continuumConsentService`
   - Protocol: REST / HTTP (Retrofit)

6. **Publish GDPR unsubscribe event**: Message Bus Publisher publishes a GDPR unsubscribe event to MBus containing consumer_id (or phone_number), country_code, and unsubscribe scope (all or per-type).
   - From: `globalSubscriptionService_messageBusPublisher`
   - To: `messageBus`
   - Protocol: MBus

7. **Return response**: API returns HTTP 200 with a `SmsConsentResponse` showing the removed consent records.
   - From: `smsConsentApi`
   - To: Client
   - Protocol: REST / HTTP (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Consumer UUID not found | Return HTTP 404 with `ErrorResponse` | No records removed |
| Phone number not found | Return HTTP 404 `Phone/Consents corresponding to phone number %s not found` | No records removed |
| Consent type UUID not found | Return HTTP 404 with `ErrorResponse` | No records removed |
| Database deletion failure | Exception propagated; HTTP 500 | No records removed; no event published |
| Consent Service sync failure | Logged; removal recorded locally; sync retried | Records removed; regulatory sync delayed |
| MBus publish failure | Logged; removal recorded; downstream notification delayed | Records removed; event delivery delayed |

## Sequence Diagram

```
Client -> smsConsentApi: DELETE /scs/v1.0/consent/consumer/{id}/consent_type/all
smsConsentApi -> subscriptionManagers: process unsubscribe request
subscriptionManagers -> continuumSmsConsentPostgres: SELECT active consents for consumer
continuumSmsConsentPostgres --> subscriptionManagers: consent records
subscriptionManagers -> continuumSmsConsentPostgres: DELETE / mark unsubscribed
continuumSmsConsentPostgres --> subscriptionManagers: OK
subscriptionManagers -> continuumConsentService: notify consent removal
continuumConsentService --> subscriptionManagers: OK
subscriptionManagers -> messageBus: publish GDPR unsubscribe event
messageBus --> subscriptionManagers: acknowledged
smsConsentApi --> Client: 200 OK / SmsConsentResponse
```

## Related

- Architecture dynamic view: No dynamic view defined — see `components-globalSubscriptionService-components`
- Related flows: [SMS Consent Creation](sms-consent-creation.md), [Automatic Subscription via MBus Event](auto-subscription-event.md)
