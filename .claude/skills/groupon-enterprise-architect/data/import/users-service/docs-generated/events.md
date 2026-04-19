---
service: "users-service"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [mbus, gbus, activemq]
---

# Events

## Overview

Users Service publishes account lifecycle and authentication events asynchronously via the GBus/ActiveMQ Message Bus Broker (`continuumUsersMessageBusBroker`). Event publishing is decoupled from the HTTP request path: the API writes a `MessageBusMessage` record to MySQL and enqueues a Resque job; the Resque worker then reads the record and publishes to the JMS topic via GBus/STOMP. The service also consumes security and identity topics through the `continuumUsersMessageBusConsumer` process.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `account` | `account.created` | New account created via `POST /v1/accounts` | account_id, email, locale, created_at |
| `account` | `account.registered` | Account registration completed | account_id, email, registration_source |
| `account` | `account.deactivated` | Account deactivated or GDPR erasure processed | account_id, reason |
| `account` | `account.reactivated` | Dormant/sleeper account reactivated | account_id |
| `authentication` | `authentication.completed` | Successful authentication via any strategy | account_id, auth_strategy, device_fingerprint, timestamp |
| `email_verification` | `email_verification.completed` | Email verification nonce confirmed | account_id, email |

### account.created Detail

- **Topic**: `account`
- **Trigger**: Account Strategies completes a new account creation; Account & Auth Event Publishers formats and queues the payload
- **Payload**: account_id, email, locale, created_at
- **Consumers**: Downstream Continuum services requiring account onboarding notifications
- **Guarantees**: at-least-once (Resque retry with backoff)

### account.registered Detail

- **Topic**: `account`
- **Trigger**: Registration flow completes; distinct from creation when identity verification is required
- **Payload**: account_id, email, registration_source
- **Consumers**: Downstream Continuum services, UDS fan-out job
- **Guarantees**: at-least-once

### account.deactivated Detail

- **Topic**: `account`
- **Trigger**: Account deactivation API call or GDPR erasure (`POST /erasure`)
- **Payload**: account_id, reason
- **Consumers**: Downstream Continuum services requiring offboarding
- **Guarantees**: at-least-once

### account.reactivated Detail

- **Topic**: `account`
- **Trigger**: Sleeper Account Resurrection Job reactivates a dormant account
- **Payload**: account_id
- **Consumers**: Downstream Continuum services
- **Guarantees**: at-least-once

### authentication.completed Detail

- **Topic**: `authentication`
- **Trigger**: Authentication Controller successfully authenticates a user via any strategy
- **Payload**: account_id, auth_strategy, device_fingerprint, timestamp
- **Consumers**: Security / fraud monitoring services; downstream session services
- **Guarantees**: at-least-once

### email_verification.completed Detail

- **Topic**: `email_verification`
- **Trigger**: Email Verifications Controller confirms nonce during `PUT /v1/email_verifications/:nonce`
- **Payload**: account_id, email
- **Consumers**: Downstream Continuum services awaiting verified email status
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `bemod.suspiciousBehavior` | Suspicious behavior signal | Forced Password Reset Handler | Invalidates tokens, resets password, sends notification email |
| Identity Service topics | Identity events | Dog Food Event Handler | Marks `MessageBusMessage` records as consumed; records timing metrics |

### bemod.suspiciousBehavior Detail

- **Topic**: `bemod.suspiciousBehavior`
- **Handler**: `continuumUsersMessageBusConsumer_forcedPasswordResetHandler` — loads affected accounts, invalidates credentials, and triggers password reset notification via `continuumUsersMessageBusConsumer_mailer`
- **Idempotency**: Records processed per account_id; duplicate signals for the same account are safely re-processed as password is already reset
- **Error handling**: Message Handler Base provides shared error normalization; failed messages are logged; retry strategy governed by GBus consumer configuration
- **Processing order**: Unordered

### Identity Service Events Detail

- **Topic**: Identity Service topics (subscriptions defined in messagebus.yml)
- **Handler**: `continuumUsersMessageBusConsumer_dogFoodEventHandler` — marks `MessageBusMessage` records as "eaten" and records delivery latency metrics to `continuumUsersMetricsStore`
- **Idempotency**: Record update is idempotent on message ID
- **Error handling**: Errors normalized by Message Handler Base; logged to `loggingStack`
- **Processing order**: Unordered

## Dead Letter Queues

> No dead letter queue configuration discoverable from the architecture inventory. DLQ policies are governed by the GBus/ActiveMQ broker configuration managed outside this service.
