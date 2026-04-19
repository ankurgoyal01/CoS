---
service: "push-infrastructure"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 6
internal_count: 2
---

# Integrations

## Overview

Push Infrastructure integrates with six external delivery and infrastructure systems (SMTP relay, SMS Gateway, FCM, APNs, Kafka, RabbitMQ) and two internal Continuum platform dependencies (MBus broker, Redis/PostgreSQL shared infrastructure). All outbound delivery channels are critical-path dependencies — unavailability of any channel results in delivery failures for that channel. Kafka is the primary high-volume event source; RabbitMQ carries delivery status back to the platform.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| SMTP Service | SMTP | Outbound email delivery | yes | `externalSmtpService_2a7d` |
| SMS Gateway | HTTP/SMPP | Outbound SMS delivery | yes | — |
| Firebase Cloud Messaging (FCM) | HTTPS SDK | Android push notification delivery | yes | — |
| Apple Push Notification service (APNs) | HTTPS SDK | iOS push notification delivery | yes | — |
| Kafka Cluster | Kafka protocol | Event-triggered message ingestion (7 topics) | yes | `externalKafkaCluster_2f8c` |
| RabbitMQ Broker | AMQP | Delivery status event publishing (`status-exchange`) | yes | `externalRabbitMqBroker_4a6b` |
| InfluxDB | InfluxDB line protocol | Operational metrics time-series storage | no | `externalInfluxDb_9e3c` |
| HDFS | Hadoop RPC | Batch delivery log archival | no | `externalHdfs_7c9d` |

### SMTP Service Detail

- **Protocol**: SMTP
- **Base URL / SDK**: `externalSmtpService_2a7d` (external SMTP relay)
- **Auth**: SMTP AUTH credentials (managed via config/secrets)
- **Purpose**: Delivers rendered email messages to end-user mailboxes; the sole outbound email transport
- **Failure mode**: Email delivery fails; message state set to error in PostgreSQL; error record created for retry
- **Circuit breaker**: No evidence found in inventory

### SMS Gateway Detail

- **Protocol**: HTTP or SMPP (gateway-dependent)
- **Base URL / SDK**: External SMS gateway endpoint (config-driven)
- **Auth**: API key or account credentials (managed via config/secrets)
- **Purpose**: Delivers SMS messages to user mobile numbers
- **Failure mode**: SMS delivery fails; error recorded; retry available via `/errors/retry`
- **Circuit breaker**: No evidence found in inventory

### Firebase Cloud Messaging (FCM) Detail

- **Protocol**: HTTPS (FCM v1 API or legacy HTTP API)
- **Base URL / SDK**: Google FCM SDK / HTTP API
- **Auth**: Firebase service account credentials (managed via config/secrets)
- **Purpose**: Delivers push notifications to Android devices
- **Failure mode**: Push delivery fails; error recorded; retry available
- **Circuit breaker**: No evidence found in inventory

### Apple Push Notification service (APNs) Detail

- **Protocol**: HTTPS / HTTP/2 (APNs provider API)
- **Base URL / SDK**: Apple APNs HTTP/2 endpoint
- **Auth**: APNs certificate or token-based auth (managed via config/secrets)
- **Purpose**: Delivers push notifications to iOS devices
- **Failure mode**: Push delivery fails; error recorded; retry available
- **Circuit breaker**: No evidence found in inventory

### Kafka Cluster Detail

- **Protocol**: Kafka binary protocol (kafka-clients 2.5.1)
- **Base URL / SDK**: Kafka broker addresses (config-driven)
- **Auth**: Internal (SASL or plaintext, config-driven)
- **Purpose**: Consumes seven event topics (rm_daf, rm_preflight, rm_coupon, rm_user_queue_default, rm_rapi, rm_mds, rm_feynman) that drive event-triggered message delivery
- **Failure mode**: Consumer lag accumulates; messages remain in Kafka until processed; no data loss under normal Kafka retention policy
- **Circuit breaker**: Kafka client handles connection retries natively

### RabbitMQ Broker Detail

- **Protocol**: AMQP (rabbitmq-client 3.3.1)
- **Base URL / SDK**: RabbitMQ broker address (config-driven)
- **Auth**: RabbitMQ credentials (managed via config/secrets)
- **Purpose**: Publishes delivery status events to `status-exchange` for consumption by upstream campaign tracking and reporting services
- **Failure mode**: Status events not delivered to consumers; delivery status tracking degrades; messages may be lost if broker is unavailable before publish
- **Circuit breaker**: No evidence found in inventory

### InfluxDB Detail

- **Protocol**: InfluxDB line protocol over HTTP
- **Base URL / SDK**: InfluxDB endpoint (config-driven); metrics-core 3.1.0 used for instrumentation
- **Auth**: InfluxDB credentials (config-driven)
- **Purpose**: Stores operational metrics (throughput, latency, error rates) for dashboards and alerting
- **Failure mode**: Metrics not recorded; delivery operations continue unaffected
- **Circuit breaker**: Not applicable (non-critical path)

### HDFS Detail

- **Protocol**: Hadoop RPC (hadoop 2.5.0-cdh5.3.1)
- **Base URL / SDK**: HDFS namenode address (config-driven)
- **Auth**: Hadoop/Kerberos (config-driven)
- **Purpose**: Archives batch delivery logs for downstream analytics
- **Failure mode**: Log archival fails; delivery operations continue; logs may be retried or lost depending on write strategy
- **Circuit breaker**: Not applicable (non-critical path)

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| MBus Broker | MBus (mbus-client 1.2.9) | Publishes and consumes internal Continuum platform events | `continuumMbusBroker` |
| Redis Cluster | Redis (jedis 3.3.0) | Template cache, delivery queues, rate-limit counters | `externalRedisCluster_5b2e` |
| Transactional Database | JDBC (MyBatis 3.4.2 / PostgreSQL driver 42.2.18) | Message state, campaign data, error records | `externalTransactionalDatabase_3f1a` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. Based on the inventory, the following categories of upstream callers are known:

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Campaign orchestration services | REST HTTP | Submit campaign message sends via `/enqueue_user_message`, `/send/v1/sends`, `/schedule` |
| Transactional event systems | REST HTTP | Submit transactional messages via `/transactional/sendmessage` |
| Kafka topic publishers (rm_daf, rm_preflight, rm_coupon, rm_user_queue_default, rm_rapi, rm_mds, rm_feynman) | Kafka | Publish event-triggered message requests |

## Dependency Health

> No explicit health check, retry policy, or circuit breaker configuration was found in the inventory for external delivery integrations (SMTP, SMS Gateway, FCM, APNs). Kafka client handles reconnection natively. Failed deliveries are recorded in PostgreSQL and are manually retriggered via the `/errors/retry` API. Operational health of dependencies is surfaced through the `/dashboard/*` endpoints and InfluxDB metrics.
