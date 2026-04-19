---
service: "deletion_service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 4
---

# Integrations

## Overview

The Deletion Service has one active external dependency (Rocketman transactional email API) and four internal Groupon service dependencies: the MBUS message bus, the Orders database, and two currently-disabled databases (CI PostgreSQL and GIS PostgreSQL). Three additional integrations (Commerce Interface, Goods Inventory, Smart Routing) are implemented but disabled in production. All active outbound HTTP calls use the JTier Retrofit client. Database connections use the JTier DaaS connection pool abstractions.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Rocketman Transactional API | REST | Send Attentive SMS consent deletion notification emails | Yes (for ATTENTIVE erase option) | `rocketmanTransactionalApi` (external) |

### Rocketman Transactional API Detail

- **Protocol**: REST / HTTPS
- **Base URL / SDK**: Configured via `rocketmanServiceClient` (`RetrofitConfiguration`) in the application config; endpoint path is `POST /transactional/sendmessage`
- **Auth**: Configuration-managed credentials via `rocketmanClient` Retrofit configuration
- **Purpose**: When the `ATTENTIVE` erase option is selected and the `SMS_CONSENT_SERVICE` integration is active, the Deletion Service calls Rocketman to send a templated email notification triggering Attentive SMS consent removal. The email recipient (`emailTo`), CC address (`carbonCopy`), and email type (`emailType`) are all configured via `AttentiveConfiguration`.
- **Failure mode**: If Rocketman returns `success=false`, an `IntegrationFailedException` is thrown, the erase service task is marked as failed, and the request is retried on the next scheduler cycle.
- **Circuit breaker**: No evidence found in codebase of a circuit breaker; failures propagate as exceptions and are handled by the retry scheduler.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| MBUS (`jms.topic.gdpr.account.v1.erased`) | MBUS (JMS topic) | Receives account GDPR erase events | `mbusGdprAccountErasedTopic` (external to DSL workspace) |
| MBUS (`jms.topic.scs.subscription.erasure`) | MBUS (JMS topic) | Receives SMS consent erasure events | `mbusScsSubscriptionErasureTopic` (external to DSL workspace) |
| MBUS (`jms.queue.gdpr.account.v1.erased.complete`) | MBUS (JMS queue) | Publishes erase completion events | `mbusGdprAccountErasedCompleteQueue` (external to DSL workspace) |
| Orders Service (MySQL) | JDBC / MySQL | Reads fulfillment IDs and anonymises order PII | `ordersMySql` (external to DSL workspace) |

### MBUS Detail

- **Protocol**: JTier `jtier-messagebus-client` over JMS
- **Configuration**: Two separate `MbusConfiguration` objects — `messageBus` (for default erasures) and `smsConsentMessageBus` (for Attentive/SMS consent erasures)
- **Enabled**: Controlled by the `flags.runMBusWorker` feature flag; if `false`, MBUS consumers are not started
- **Failure mode**: Failed messages are NACKed; MBUS broker handles redelivery

### Orders MySQL Detail

- **Protocol**: JDBC via JTier `jtier-daas-mysql` and JDBI
- **Configuration**: `ordersMySQL` (`MySQLConfig`) in application config
- **Purpose**: Reads fulfillment line items to gate erasure (no orders = skip) and updates fulfillment records to anonymise customer PII
- **Failure mode**: JDBC exceptions propagate, mark the `ORDERS` service task as failed, and trigger a retry on the next scheduler cycle

## Disabled Integrations

The following integrations are implemented in source but currently disabled (commented out in `EraseRequestAction`):

| Service | Integration Class | Reason |
|---------|-----------------|--------|
| Commerce Interface (`goods_commerce_interface`) | `CommerceInterfaceIntegration` | Configuration disabled; CI PostgreSQL (`ciPostgres`) required |
| Goods Inventory Service (`goods-inventory-service`) | `GoodsInventoryIntegration` | Configuration disabled; GIS PostgreSQL (`gisPostgres`) required |
| Smart Routing Service (`goods-outbound-controller`) | `SmartRoutingIntegration` | Configuration disabled; SRS MySQL (`srsMySQL`) required |

The following service types are treated as decommissioned and handled by `DecommissionedIntegration` (no-op):

- `ONLINE_RETURN_CENTRE` (`gfi`)
- `DCOR` (`dcor_service`)
- `GOODS_LABEL_API` (`goods-label-api`)

## Consumed By

> Upstream consumers are tracked in the central architecture model. The Deletion Service is invoked by:
> - GDPR account management pipeline (publishes to `jms.topic.gdpr.account.v1.erased`)
> - SMS consent system (publishes to `jms.topic.scs.subscription.erasure`)
> - Admin operators via the REST API (manual erasure submission)

## Dependency Health

- **MBUS**: JTier MBUS client manages connection lifecycle. Worker activation is gated by the `flags.runMBusWorker` flag.
- **Orders MySQL**: JTier DaaS connection pool manages pool sizing and health. DaaS connection limits are the documented bottleneck (see OWNERS_MANUAL).
- **Rocketman API**: Retrofit client with no explicit timeout or retry configuration evidenced in source; failure is surfaced as a task-level error and retried by the Quartz scheduler.
- **Deletion Service DB**: JTier DaaS PostgreSQL pool; database connection limit is the primary service bottleneck per the OWNERS_MANUAL.
