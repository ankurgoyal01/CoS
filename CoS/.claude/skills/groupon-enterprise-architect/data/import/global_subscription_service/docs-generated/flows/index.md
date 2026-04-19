---
service: "global_subscription_service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for the Global Subscription Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [SMS Consent Creation](sms-consent-creation.md) | synchronous | API call — `POST /scs/v1.0/consent/consumer/{id}` | Consumer opts into SMS notifications for a consent type |
| [SMS Consent Removal (GDPR Unsubscribe)](sms-consent-removal.md) | synchronous | API call — `DELETE /scs/v1.0/consent/consumer/{id}/consent_type/all` | Consumer or system removes all SMS consents (GDPR-compliant) |
| [Push Token Registration](push-token-registration.md) | synchronous | API call — `POST /push-token/device-token` | Mobile device registers a push notification token |
| [Automatic Subscription via MBus Event](auto-subscription-event.md) | asynchronous | MBus event (auto-sub, travellers, location-sub, RTF topics) | Consumer is automatically subscribed based on an inbound platform event |
| [Push Token Data Migration](push-token-data-migration.md) | asynchronous | MBus data migration event | Push token records are migrated from Cassandra to PostgreSQL |
| [Subscription List Management](subscription-list-management.md) | synchronous | API call — `POST/PUT /lists/list/{country_code}/{list_type}/{list_id}` | Admin creates or updates an email/SMS subscription list definition |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- The SMS consent creation flow involves `continuumUserService` (consumer identity) and `continuumConsentService` (regulatory sync), then publishes a subscription change event to MBus consumed by Rocketman and regulatory-consent-log.
- The push token registration flow publishes to Kafka, which is consumed by push notification routing services.
- The GDPR unsubscribe flow publishes to MBus and is consumed by the Consent Service for regulatory logging.
- Automatic subscription events originate from upstream Groupon platform systems and are consumed by this service to drive consent creation without a direct API call.
