---
service: "global_subscription_service"
title: "Automatic Subscription via MBus Event"
generated: "2026-03-03"
type: flow
flow_name: "auto-subscription-event"
flow_type: asynchronous
trigger: "MBus event on travellers, auto-sub, location-sub, or RTF topics"
participants:
  - "globalSubscriptionService"
  - "continuumSmsConsentPostgres"
  - "messageBus"
architecture_ref: "components-globalSubscriptionService-components"
---

# Automatic Subscription via MBus Event

## Summary

This flow handles the automatic enrollment of a consumer into SMS subscription lists in response to platform-generated MBus events. Upstream Groupon systems publish events to MBus topics (travellers, auto-sub, location-sub, RTF) that signal that a consumer should be automatically subscribed to a relevant consent type. The Global Subscription Service consumes these events and creates consent records without requiring a direct API call from the consumer.

## Trigger

- **Type**: event
- **Source**: Upstream Groupon platform systems publishing to MBus — travellers topic (`mbusTravellersConfiguration`), auto-sub topic (`mbusAutosubConfiguration`), location-sub topic (`mbusLocationSubConfiguration`), RTF topic (`mbusRtfConfiguration`)
- **Frequency**: Event-driven — triggered when platform signals a qualifying consumer action (e.g., user books travel, user opts into location-based promotions)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MBus | Delivers the inbound subscription trigger event | `messageBus` |
| Subscription Managers | Processes the event and creates consent records | `subscriptionManagers` |
| SMS Consent Repository | Checks for existing consent and persists new consent | `smsConsentRepository` |
| SMS Consent Postgres | Stores the auto-created consent record | `continuumSmsConsentPostgres` |
| Message Bus Publisher | Publishes confirmation subscription change event | `globalSubscriptionService_messageBusPublisher` |

## Steps

1. **Receive inbound MBus event**: The MBus consumer thread (enabled when `messageBusConsumersEnabled` is true) receives an event from one of the auto-subscription topics. The event contains consumer_id, country_code, locale, and the target consent type(s).
   - From: `messageBus`
   - To: `subscriptionManagers` (via MBus consumer configured by `mbusAutosubConfiguration` / `mbusTravellersConfiguration` / `mbusLocationSubConfiguration` / `mbusRtfConfiguration`)
   - Protocol: MBus

2. **Check for existing consent**: Subscription Managers queries SMS Consent Repository to determine whether the consumer already has an active consent for the target consent type in the given country/locale. Prevents duplicate consent records (idempotency check).
   - From: `subscriptionManagers`
   - To: `smsConsentRepository` → `continuumSmsConsentPostgres`
   - Protocol: JDBC / PostgreSQL

3. **Create consent record** (if not already subscribed): SMS Consent Repository inserts a new consent record for the consumer, consent type, country, and locale with status active. No phone number is required — this creates a consent entry for the consumer UUID directly.
   - From: `smsConsentRepository`
   - To: `continuumSmsConsentPostgres`
   - Protocol: JDBC / PostgreSQL

4. **Publish subscription change event**: Message Bus Publisher publishes a subscription CREATE event to MBus to notify downstream systems of the new consent.
   - From: `globalSubscriptionService_messageBusPublisher`
   - To: `messageBus`
   - Protocol: MBus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Consumer already subscribed (duplicate event) | Idempotency check prevents double-insert; event acknowledged | No-op — existing consent preserved |
| Consumer not found in User Service | Logged; event acknowledged | Consent not created; event dropped |
| Database write failure | Logged; event may be retried by MBus (at-least-once) | Retry on next delivery; possible duplicate if idempotency check fails on retry |
| MBus consumer disabled (`messageBusConsumersEnabled=false`) | Events not consumed; queued in MBus | Events accumulate until consumer is re-enabled |
| Downstream publish failure | Logged; inbound event processed successfully | Consent created; downstream notification delayed |

## Sequence Diagram

```
UpstreamPlatform -> messageBus: publish auto-subscription trigger event
messageBus -> subscriptionManagers: deliver event (travellers/auto-sub/location-sub/RTF topic)
subscriptionManagers -> continuumSmsConsentPostgres: SELECT existing consent for consumer + consent_type
continuumSmsConsentPostgres --> subscriptionManagers: no existing consent (or exists)
subscriptionManagers -> continuumSmsConsentPostgres: INSERT consent record (if not exists)
continuumSmsConsentPostgres --> subscriptionManagers: OK
subscriptionManagers -> messageBus: publish subscription CREATE event
messageBus --> subscriptionManagers: acknowledged
```

## Related

- Architecture dynamic view: No dynamic view defined — see `components-globalSubscriptionService-components`
- Related flows: [SMS Consent Creation](sms-consent-creation.md), [SMS Consent Removal](sms-consent-removal.md)
