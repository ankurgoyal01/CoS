---
service: "billing-record-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 2
---

# Integrations

## Overview

Billing Record Service has three external dependencies (PCI-API for token lifecycle, Braintree for one-time tokens, and the Groupon Message Bus for async event exchange) and two internal Continuum service dependencies (Checkout Reloaded and Orders). Circuit breaking via Netflix Hystrix is configured for external HTTP calls. The service depends on Groupon DaaS for database management and RaaS (Redis-as-a-Service) for cache infrastructure.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| PCI-API | HTTPS REST | Token lifecycle management: delete tokens when no longer required by any purchaser | yes | `paymentGateways` |
| Braintree | HTTPS SDK | Generate one-time payment tokens for Grubhub integration | no | `paymentGateways` |
| Groupon Message Bus (mbus) | STOMP/JMS | Consume GDPR erasure and token-deletion events; publish IRR completion events | yes | `messageBus` |
| Adyen | HTTPS API | PSP purchaser reference storage and token management | yes | `paymentGateways` |

### PCI-API Detail

- **Protocol**: HTTPS REST (HTTP/JSON, with GraphQL endpoints referenced in pom.xml via `ggqlc`)
- **Base URL / SDK**: Internal Groupon PCI-API service (referenced in `.service.yml` dependencies as `pci-api`)
- **Auth**: Internal service credentials (managed via `cap-secrets` / `billing-record-service-secrets`)
- **Purpose**: When a billing record is deactivated or a purchaser invokes GDPR erasure, BRS checks whether the associated token is still used by other purchasers. If not, it calls PCI-API to delete the credit card token from the PCI vault.
- **Failure mode**: PCI token deletion failure is logged; billing record status update still commits. Hystrix circuit breaker limits cascading failures.
- **Circuit breaker**: Yes — Netflix Hystrix (version 1.5.10)

### Braintree Detail

- **Protocol**: HTTPS via `braintree-java` SDK (version 2.73.0)
- **Base URL / SDK**: `com.braintreepayments.gateway:braintree-java:2.73.0`
- **Auth**: Braintree merchant credentials (stored in `cap-secrets`)
- **Purpose**: Generates Braintree one-time payment tokens for the Grubhub integration via `POST /v2/{countryCode}/users/{purchaserId}/billingrecords/{billingRecordId}/braintree/onetimetoken/grubhub`
- **Failure mode**: Returns error response to caller; Hystrix circuit breaker limits cascading failures
- **Circuit breaker**: Yes — Netflix Hystrix (version 1.5.10)

### Groupon Message Bus (mbus) Detail

- **Protocol**: STOMP/JMS via `mbus-client` (version 1.3.1)
- **Base URL / SDK**: `com.groupon.messagebus:mbus-client:1.3.1`
- **Auth**: Internal mbus credentials (stored in `cap-secrets`)
- **Purpose**: Receives GDPR IRR erasure commands (qualifier: `erasure`) and token-deletion commands (qualifier: `tokenerasure`); publishes IRR completion acknowledgement events
- **Failure mode**: Messages are not acknowledged on handler failure, causing redelivery. `messagebus.enabled` flag allows disabling locally.
- **Circuit breaker**: No — mbus client does not use Hystrix

### Adyen Detail

- **Protocol**: HTTPS API
- **Base URL / SDK**: Adyen PSP API (referenced via `TokenStore.ADYEN` and `PspPurchaserDataModel.pspName = ADYEN`)
- **Auth**: Adyen API credentials (stored in `cap-secrets`)
- **Purpose**: Stores Adyen shopper references per purchaser (`pspPurchaserReference`); token types include ONECLICK, RECURRING, COMBINED
- **Failure mode**: Token operations fail gracefully; circuit breaker limits cascading failures
- **Circuit breaker**: Yes — Netflix Hystrix

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Orders MySQL (legacy) | JDBC | Reads legacy Orders data to migrate billing records during the orders-to-BRS backfill migration | not modeled in federated DSL |
| DaaS (Database-as-a-Service) | Infrastructure | Manages PostgreSQL replication (master/slave) and backup | not modeled |
| RaaS (Redis-as-a-Service) | Infrastructure | Manages Redis instance lifecycle | not modeled |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| `continuumCheckoutReloadedService` | HTTP/JSON | Creates, updates, and retrieves billing records during checkout flows |
| `continuumOrdersService` | HTTP/JSON | Looks up billing records by legacy order references |

> Upstream consumers are also tracked in the central architecture model at `continuumBillingRecordService` container relationships.

## Dependency Health

- Netflix Hystrix circuit breakers wrap HTTP calls to PCI-API and Braintree. Open-circuit fallbacks return error responses to callers.
- The Groupon Message Bus uses the `ConsumerImpl` and `ProducerImpl` from `mbus-client`; polling is done via `receiveImmediate()` with safe-ack (`ackSafe`) to avoid message loss.
- PostgreSQL and Redis connectivity is managed via DBCP connection pools; health is surfaced at `/grpn/healthcheck`.
