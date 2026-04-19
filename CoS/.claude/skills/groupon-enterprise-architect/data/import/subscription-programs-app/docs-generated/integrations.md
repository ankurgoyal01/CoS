---
service: "subscription-programs-app"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 2
internal_count: 3
---

# Integrations

## Overview

Subscription Programs App integrates with two external systems (KillBill for billing, Rocketman for email) and three internal Continuum services (Incentive Service, Orders Service, TPIS). All outbound HTTP calls use `jtier-retrofit` with `guava-retrying` for retry logic. KillBill is the most critical external dependency — billing lifecycle events drive membership state transitions.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| KillBill | REST (webhook + client) | Subscription billing — creates/manages billing accounts and subscriptions; pushes lifecycle events back via webhook | yes | — |
| Rocketman | REST | Transactional email delivery — sends membership confirmation, cancellation, and payment failure emails to consumers | no | — |

### KillBill Detail

- **Protocol**: REST (outbound via `killbill-client-java 1.0.6`; inbound via HTTP webhook to `POST /select/killbill-event`)
- **Base URL / SDK**: `killbill-client-java` version `1.0.6`
- **Auth**: KillBill API credentials (managed via configuration/secrets)
- **Purpose**: Creates and manages KillBill billing accounts and subscriptions when a Select membership is created; receives payment success/failure/cancellation events via webhook to drive membership state transitions
- **Failure mode**: If KillBill is unavailable during membership creation, the create operation fails and no membership record is committed. Webhook delivery failures are retried by KillBill per its internal retry policy.
- **Circuit breaker**: `guava-retrying` provides retry with backoff; no explicit circuit breaker pattern evidenced

### Rocketman Detail

- **Protocol**: REST (outbound via `jtier-retrofit`)
- **Base URL / SDK**: Internal Continuum Rocketman service endpoint
- **Auth**: Internal service-to-service auth
- **Purpose**: Delivers transactional email to consumers — membership welcome, cancellation confirmation, payment failure notifications; triggered by the `/support/{consumerId}/email` and `/message/{consumerId}` endpoints
- **Failure mode**: Email delivery failure is treated as non-critical; membership state is not rolled back on Rocketman errors
- **Circuit breaker**: `guava-retrying` provides retry; email failures are logged

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Incentive Service | REST (`jtier-retrofit`) | Enrolls active members in loyalty incentives/benefits upon membership activation; queries available incentives | — |
| Orders Service | REST (`jtier-retrofit`) | Queries order history to support eligibility checks and membership context | — |
| TPIS | REST (`jtier-retrofit`) | Optional integration — third-party incentive data; used conditionally based on configuration | — |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Known consumers include consumer-facing frontends (MBNXT) and internal Continuum services that subscribe to the `jms.topic.select.MembershipUpdate` MBus topic to gate behavior on Select membership status.

## Dependency Health

- **KillBill**: `killbill-client-java` handles HTTP-level retries. Webhook receipt must respond HTTP 200 promptly to prevent KillBill retry storms.
- **Incentive Service / Orders Service / TPIS**: `guava-retrying 2.0.0` applied to outbound calls. TPIS is optional and gracefully skipped when unavailable or not configured.
- **Rocketman**: Non-critical path; failures are logged but do not affect membership state.
- **MBus publishing**: `jtier-messagebus-client` handles connection and at-least-once delivery for `jms.topic.select.MembershipUpdate`.
