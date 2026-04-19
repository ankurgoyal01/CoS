---
service: "push-client-proxy"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumPushClientProxyService"
    - "continuumPushClientProxyPostgresMainDb"
    - "continuumPushClientProxyPostgresExclusionsDb"
    - "continuumPushClientProxyMySqlUsersDb"
    - "continuumPushClientProxyRedisPrimary"
    - "continuumPushClientProxyRedisIncentive"
---

# Architecture Context

## System Context

push-client-proxy sits inside the Continuum platform and serves as the boundary between the external Bloomreach email system and Groupon's internal messaging infrastructure. Bloomreach calls the HTTP email-send API to inject outbound emails; the internal Audience Management Service calls the audience patch/get API to update campaign membership. The service consumes delivery-status events from the Kafka broker and dispatches callback notifications to downstream HTTP endpoints. All stateful data (audiences, email-send records, exclusion denylists, user lookups) is stored in PostgreSQL or MySQL, with Redis used for high-speed metadata caching and distributed rate limiting.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| push-client-proxy service | `continuumPushClientProxyService` | Service | Java 17, Spring Boot 3.5.4 | 0.0.1-SNAPSHOT | Spring Boot API and Kafka consumer service for email delivery orchestration and audience operations |
| push-client-proxy main database | `continuumPushClientProxyPostgresMainDb` | Database | PostgreSQL | — | Primary PostgreSQL database for audience and email-send persistence |
| rocketman exclusions database | `continuumPushClientProxyPostgresExclusionsDb` | Database | PostgreSQL | — | Read-only PostgreSQL exclusions data source for denylist checks |
| users lookup database | `continuumPushClientProxyMySqlUsersDb` | Database | MySQL | — | MySQL data source for user account existence checks |
| primary redis cache | `continuumPushClientProxyRedisPrimary` | Cache | Redis | — | Primary Redis cluster for request metadata and audience keys |
| incentive redis cache | `continuumPushClientProxyRedisIncentive` | Cache | Redis | — | Secondary Redis instance used by audience treatment logic |

## Components by Container

### push-client-proxy service (`continuumPushClientProxyService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Email API Controller (`pcpEmailApiController`) | Handles `/email/verify` and `/email/send-email` endpoints | Spring REST Controller |
| Audience API Controller (`pcpAudienceApiController`) | Handles `/audiences` patch and get endpoints | Spring REST Controller |
| Kafka Delivery Listener (`pcpKafkaDeliveryListener`) | Consumes delivery-status topics and builds callback events | Kafka Listener |
| Kafka Email Send Listener (`pcpKafkaEmailSendListener`) | Consumes `cdp_delivery` / `email-send-topic` messages and dispatches outbound sends | Kafka Listener |
| Email Injector Service (`pcpEmailInjectorService`) | Resolves sender routing and sends emails over SMTP | Service |
| Audience Service (`pcpAudienceService`) | Applies audience patch operations and retrieves counts | Service |
| Message Processing Service (`pcpMessageProcessingService`) | Processes message payloads for listener workflows | Service |
| Subscription Service (`pcpSubscriptionService`) | Evaluates user subscription state before send | Service |
| Rate Limiter Service (`pcpRateLimiterService`) | Enforces API throughput limits with Redis-backed Bucket4j buckets | Service |
| Email Exclusion Service (`pcpEmailExclusionService`) | Evaluates exclusion and wildcard denylist rules | Service |
| User Account Service (`pcpUserAccountService`) | Checks account existence in users lookup data | Service |
| Redis Util (`pcpRedisUtil`) | Stores and retrieves email metadata in Redis | Redis Client |
| Audience Redis Util (`pcpAudienceRedisUtil`) | Reads and updates audience treatment keys in primary/incentive Redis | Redis Client |
| Email API Template (`pcpEmailApiTemplate`) | Posts callback events to downstream HTTP endpoints | HTTP Client |
| Send Email Publisher (`pcpSendEmailPublisher`) | Publishes retry messages to Kafka | Kafka Publisher |
| Metrics Provider (`pcpMetricsProvider`) | Publishes counters and timers to InfluxDB | Metrics Client |
| Audience Repository (`pcpAudienceRepositoryComponent`) | JPA repository for audience entities | Spring Data JPA |
| Email Send Repository (`pcpEmailSendRepositoryComponent`) | JPA repository for email send persistence | Spring Data JPA |
| Exclusion Repository (`pcpExclusionRepositoryComponent`) | JPA repository for exclusions dataset | Spring Data JPA |
| Rocketman Email Lookup Repository (`pcpUserLookupRepositoryComponent`) | JPA repository for user lookup dataset | Spring Data JPA |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `bloomreach` | `continuumPushClientProxyService` | Calls email send/verify APIs | HTTPS |
| `continuumAudienceManagementService` | `continuumPushClientProxyService` | Calls audience patch/get APIs | HTTPS |
| `continuumKafkaBroker` | `continuumPushClientProxyService` | Delivers Kafka topics (`msys_delivery`, `cdp_delivery`) | Kafka |
| `continuumPushClientProxyService` | `continuumKafkaBroker` | Publishes retry messages and consumes/produces delivery events | Kafka |
| `continuumPushClientProxyService` | `continuumPushClientProxyPostgresMainDb` | Reads and writes audience and email-send data | JPA/JDBC |
| `continuumPushClientProxyService` | `continuumPushClientProxyPostgresExclusionsDb` | Reads exclusion denylist data | JPA/JDBC |
| `continuumPushClientProxyService` | `continuumPushClientProxyMySqlUsersDb` | Reads user lookup records | JPA/JDBC |
| `continuumPushClientProxyService` | `continuumPushClientProxyRedisPrimary` | Caches request metadata and audience keys | Redis |
| `continuumPushClientProxyService` | `continuumPushClientProxyRedisIncentive` | Reads and writes incentive audience keys | Redis |
| `continuumPushClientProxyService` | `smtpRelay` | Injects outbound email messages | SMTP |
| `continuumPushClientProxyService` | `influxDb` | Writes operational metrics | HTTP |

## Architecture Diagram References

- Component: `components-pushClientProxyContainer`
- Component detail: `components-pushClientProxyService`
- Dynamic (email request flow): `dynamic-email-request-flow`
- Dynamic (audience patch flow): `dynamic-audience-patch-flow`
