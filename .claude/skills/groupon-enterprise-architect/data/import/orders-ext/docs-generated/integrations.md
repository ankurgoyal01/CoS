---
service: "orders-ext"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 3
---

# Integrations

## Overview

Orders Ext integrates with 3 external partners (PayPal, KillBill/Adyen, Accertify) and calls 3 internal Groupon services (Fraud Arbiter Service, Users Service, internal MessageBus). All outbound HTTP calls are made via the `schema_driven_client` gem (backed by Faraday/Typhoeus), which reads endpoint configuration from JSON schema descriptors in `api_schemas/`. The service also writes to a Redis instance (Resque queue) consumed by orders-worker.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| PayPal API | REST/HTTPS | Verify webhook signature authenticity for billing agreement events | yes | — |
| KillBill | REST/HTTPS | Forward Adyen payment notification by region (US/EMEA) | yes | — |
| Accertify | Inbound webhook (push) | Receive fraud review resolutions via XML callback | yes | — |
| Signifyd | Inbound webhook (push) | Receive fraud decision review callbacks | yes | — |

### PayPal API Detail

- **Protocol**: REST/HTTPS
- **Base URL**: `https://api.paypal.com/v1/` (production), `https://api.sandbox.paypal.com/v1/` (non-prod)
- **Auth**: Username/password (`PAY_PAL_USERNAME`, `PAY_PAL_PASSWORD` env vars in production)
- **Purpose**: Verifies that inbound webhooks were genuinely sent by PayPal by calling `POST /v1/notifications/verify-webhook-signature`; configured webhook ID is `19Y70743S88976739` (production)
- **Failure mode**: HTTP 400 is returned to the PayPal caller if verification fails; unhandled exceptions return HTTP 500
- **Circuit breaker**: No — uses `schema_driven_client` with connect timeout 500 ms, response timeout 3000 ms

### KillBill Detail

- **Protocol**: REST/HTTPS
- **Base URL**: `http://killbill-us/1.0/kb/` (US region), `http://killbill-emea/1.0/kb/` (EMEA region)
- **Auth**: API key + API secret per region (configuration in `config/cloud/<env>/killbill.yml`)
- **Purpose**: Proxies Adyen payment notifications through to KillBill's `POST /1.0/kb/paymentGateways/notification/killbill-adyen` endpoint; the response is passed back to the caller unchanged
- **Failure mode**: Timeout (code 0) is converted to HTTP 504 and returned to caller
- **Circuit breaker**: No

### Accertify (inbound)

- **Protocol**: HTTP Basic authenticated POST (inbound webhook push)
- **Auth**: HTTP Basic credentials from `config/auth.yml` (production values injected via `ACCERTIFY_PASSWORD` env var)
- **Purpose**: Receives XML fraud review resolution decisions and enqueues async order resolution jobs
- **Failure mode**: HTTP 400 returned on bad credentials or malformed XML

### Signifyd (inbound)

- **Protocol**: HMAC-SHA256 signed POST (inbound webhook push)
- **Auth**: HMAC-SHA256 — `SIGNIFYD-SEC-HMAC-SHA256` header is validated against `SIGNIFYD_API_KEY` env var
- **Purpose**: Receives fraud decision review callbacks and forwards to Fraud Arbiter Service
- **Failure mode**: HTTP 401 on invalid signature; HTTP 200 returned for unsupported event types

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Fraud Arbiter Service | REST/HTTP | Forward Signifyd decision review payload for processing | — |
| Users Service | REST/HTTP | Look up admin account by domain (`internal.na`) and email address for Accertify resolution attribution | `continuumUsersService` |
| MessageBus (STOMP/JMS) | STOMP | Publish `PaypalBillingAgreementCancelled` events to `jms.topic.BillingRecords.PaypalBillingAgreementEvents` | `messageBus` |

### Fraud Arbiter Service Detail

- **Protocol**: REST/HTTP
- **Base URL**: `http://fraud-arbiter.production.service` (production)
- **Auth**: API key via `FRAUD_ARBITER_API_KEY` env var
- **Purpose**: Receives normalized Signifyd decision review payloads and applies fraud decisioning logic
- **Failure mode**: Logged via STENO_LOGGER; error response passed back to Signifyd caller
- **Circuit breaker**: No; `max_retries: 1`, connect timeout 2000 ms, response timeout 15000 ms (production)

### Users Service Detail

- **Protocol**: REST/HTTP
- **Base URL**: `http://users-service.production.service/users/v1/` (production)
- **Auth**: Client ID via `USERS_SERVICE_API_KEY` env var; `client_id: <REDACTED>`
- **Purpose**: Resolves admin email to user account ID for Accertify resolution audit trail
- **Failure mode**: Returns `nil`; falls back to a default service account as admin ID
- **Circuit breaker**: No; connect timeout 275 ms, response timeout 750 ms

### MessageBus Detail

- **Protocol**: STOMP over TCP
- **Producer address** (production): `mbus-na-snc1-prod.grpn-dse-prod.us-west-1.aws.groupondev.com:61613`
- **Auth**: Username/password (rocketman credentials from `config/messagebus.yml`)
- **Purpose**: Delivers `PaypalBillingAgreementCancelled` events to downstream billing consumers
- **Failure mode**: Retries up to 5 times (200 ms interval) on `Timeout::Error`; logs failure if all retries exhausted

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Accertify (fraud partner) | HTTP Basic webhook POST | Pushes fraud resolution decisions |
| Signifyd (fraud partner) | HMAC webhook POST | Pushes fraud decision review callbacks |
| PayPal (payment partner) | Webhook POST | Pushes billing agreement lifecycle events |
| KillBill/Adyen (payment processor) | HTTP POST | Pushes Adyen payment notifications for proxying |

> Upstream consumers of the published MessageBus events are tracked in the central architecture model.

## Dependency Health

- All outbound HTTP calls use configurable timeouts via `schema_driven_client` (connect and response timeouts per `api_schemas/*.json` and cloud config files)
- MessageBus client reconnects automatically on timeout via `MESSAGEBUS_CLIENT.stop` / `MESSAGEBUS_CLIENT.start` before retry
- Redis connection failures during Resque enqueue are caught and logged; a `EnqueueFailure` is raised and HTTP 200 with `"failure"` body is returned to Accertify
- No circuit breakers are configured
