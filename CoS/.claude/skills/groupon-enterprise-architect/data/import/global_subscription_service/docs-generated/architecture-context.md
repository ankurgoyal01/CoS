---
service: "global_subscription_service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumPlatform"
  containers:
    - "globalSubscriptionService"
    - "continuumSmsConsentPostgres"
    - "continuumPushTokenPostgres"
    - "continuumPushTokenCassandra"
---

# Architecture Context

## System Context

The Global Subscription Service sits within the Continuum platform and acts as the authoritative subscription management layer for Groupon's consumer-facing products. It is called by mobile apps, web clients, and internal services to manage whether consumers may be contacted via SMS, email, or push notification. It depends on the User Service for consumer identity resolution, the Consent Service for regulatory consent synchronization, and several messaging systems (MBus, Kafka) to propagate subscription state changes to downstream systems such as Rocketman (SMS sending) and EDS (email delivery).

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Global Subscription Service | `globalSubscriptionService` | Backend | Java / Dropwizard / JTier | 1.0.x | Play Framework-era REST service (migrated to JTier/Dropwizard) for SMS/email subscriptions, consent management, and push token APIs |
| SMS Consent Postgres | `continuumSmsConsentPostgres` | Database | PostgreSQL | 42.7.3 driver | Stores SMS consent records, consent types, and phone-to-consumer mappings |
| Push Token Postgres | `continuumPushTokenPostgres` | Database | PostgreSQL | 42.7.3 driver | Stores push token data and push subscription records |
| Push Token Cassandra | `continuumPushTokenCassandra` | Database | Cassandra | — | Legacy store for push token data (read/written for backward compatibility) |

## Components by Container

### Global Subscription Service (`globalSubscriptionService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| SMS Consent API Resources (`smsConsentApi`) | Exposes REST endpoints for SMS consent create/read/update/delete by consumer or phone | Play Framework / Dropwizard JAX-RS |
| Email Subscription API Resources (`emailSubscriptionApi`) | Exposes REST endpoints for email notification subscription preferences | Play Framework / Dropwizard JAX-RS |
| Push Token API Resources (`pushTokenApi`) | Exposes REST endpoints for push token registration, update, and device management | Play Framework / Dropwizard JAX-RS |
| Subscription Managers (`subscriptionManagers`) | Orchestrates business logic for subscription create, update, list, and unsubscribe workflows; invokes risk scoring for double opt-in | Java |
| Push Token Service (`pushTokenService`) | Manages push token and push subscription lifecycle including Cassandra migration | Java |
| SMS Consent Repository (`smsConsentRepository`) | JDBI3-based data access for consent records and consent type lookups | JDBI3 |
| Push Token DAO (`pushTokenDao`) | Data access across PostgreSQL (primary) and Cassandra (legacy) for push tokens | JDBI3 / Cassandra driver |
| Postgres Client (`postgresClient_GloSubSer`) | SQL query templates and row mappers for JTier-managed PostgreSQL | JDBI3 |
| Cassandra Client (`cassandraClient_GloSubSer`) | Cassandra session management and query execution for push token data | Cassandra driver |
| Message Bus Publisher (`globalSubscriptionService_messageBusPublisher`) | Publishes subscription change events and GDPR unsubscribe events to MBus | MBus (jtier-messagebus-client 5.7.3) |
| Kafka Publisher (`globalSubscriptionService_kafkaPublisher`) | Publishes push token create/update events to Kafka cluster | Kafka |
| External Service Clients (`externalServiceClients_GloSubSer`) | Retrofit-based HTTP clients for User Service, Consent Service, Rocketman SMS, EDS, and Geo Services | Retrofit / OkHttp |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `globalSubscriptionService` | `continuumSmsConsentPostgres` | Stores and retrieves consent records | JDBC / PostgreSQL |
| `globalSubscriptionService` | `continuumPushTokenPostgres` | Stores and retrieves push token data | JDBC / PostgreSQL |
| `globalSubscriptionService` | `continuumPushTokenCassandra` | Reads/writes legacy push token data | Cassandra protocol |
| `globalSubscriptionService` | `continuumUserService` | Fetches user account data for consumer identity resolution | REST / HTTP |
| `globalSubscriptionService` | `continuumConsentService` | Synchronizes consent information for regulatory compliance | REST / HTTP |
| `globalSubscriptionService` | `messageBus` | Publishes subscription and GDPR events; consumes travellers, auto-sub, location-sub, RTF, and data migration events | MBus |
| `globalSubscriptionService` | Kafka cluster | Publishes push token create/update events | Kafka TLS |
| `smsConsentApi` | `subscriptionManagers` | Routes consent requests to business logic | Direct / Java |
| `emailSubscriptionApi` | `subscriptionManagers` | Routes email subscription requests to business logic | Direct / Java |
| `pushTokenApi` | `pushTokenService` | Routes push token requests to push token service | Direct / Java |
| `subscriptionManagers` | `smsConsentRepository` | Reads and writes consent data | Direct / Java |
| `subscriptionManagers` | `globalSubscriptionService_messageBusPublisher` | Publishes subscription change events | Direct / Java |
| `pushTokenService` | `pushTokenDao` | Reads and writes push token data | Direct / Java |
| `pushTokenService` | `globalSubscriptionService_kafkaPublisher` | Publishes push token events | Direct / Java |

## Architecture Diagram References

- Component: `components-globalSubscriptionService-components`
