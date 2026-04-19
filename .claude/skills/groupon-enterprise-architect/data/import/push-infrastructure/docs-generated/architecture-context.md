---
service: "push-infrastructure"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumPushInfrastructureService]
---

# Architecture Context

## System Context

Push Infrastructure (`continuumPushInfrastructureService`) is a container within the `continuumSystem` (Continuum Platform) — Groupon's core commerce engine. It occupies the messaging delivery layer: upstream services submit message requests via REST API or publish events to Kafka topics; Push Infrastructure renders, queues, and dispatches those messages through SMTP, SMS Gateway, FCM, and APNs. Delivery status is published back to the platform via RabbitMQ. It also reads from and writes to Redis (caching and rate limiting), PostgreSQL/MySQL (transactional data), and HDFS (batch logs).

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Push Infrastructure Service | `continuumPushInfrastructureService` | Service | Java, Play Framework | Play 2.2.1 / Java 8 | Play Framework service for push/email/sms ingestion, rendering, scheduling, and queue processing |
| Kafka Cluster | `externalKafkaCluster_2f8c` | External | Apache Kafka | — | Kafka broker cluster; source of event-triggered message topics |
| Redis Cluster | `externalRedisCluster_5b2e` | External | Redis | 6.2.10 | Template cache, delivery queues, and rate-limit counters |
| Transactional Database | `externalTransactionalDatabase_3f1a` | External | PostgreSQL / MySQL | — | Persistent storage for message state, campaign data, and error records |
| HDFS | `externalHdfs_7c9d` | External | Hadoop HDFS | 2.5.0-cdh5.3.1 | Batch delivery log archive |
| MBus Broker | `continuumMbusBroker` | External (Continuum) | MBus | — | Continuum internal message bus |
| RabbitMQ Broker | `externalRabbitMqBroker_4a6b` | External | RabbitMQ | — | Delivery status event publisher (`status-exchange`) |
| InfluxDB | `externalInfluxDb_9e3c` | External | InfluxDB | — | Time-series metrics store for delivery instrumentation |
| SMTP Service | `externalSmtpService_2a7d` | External | SMTP | — | Outbound email relay |

## Components by Container

### Push Infrastructure Service (`continuumPushInfrastructureService`)

> No component definitions yet — component-level decomposition is pending in the architecture model.

The service logically groups the following functional areas (derived from API surface and flow inventory):

| Component (logical) | Responsibility | Technology |
|---------------------|---------------|-----------|
| Message Ingestion API | Receives `/enqueue_user_message`, `/send/v1/sends`, `/transactional/sendmessage` requests | Play Framework / REST |
| Event-Triggered Consumer | Consumes Kafka topics (rm_daf, rm_preflight, rm_coupon, rm_user_queue_default, rm_rapi, rm_mds, rm_feynman) | kafka-clients 2.5.1 |
| Template Renderer | Renders FreeMarker templates against user/campaign data | FreeMarker 2.3.20 |
| Queue Processor | Dequeues and dispatches messages to SMTP, SMS Gateway, FCM/APNs | Akka actors 2.2.4, jedis 3.3.0 |
| Scheduler | Manages time-delayed and cron-scheduled campaign sends | Quartz 2.2.1 |
| Status Publisher | Publishes delivery status events to RabbitMQ `status-exchange` | rabbitmq-client 3.3.1 |
| Rate Limiter | Enforces per-user/channel send-rate limits via Redis counters | jedis 3.3.0 |
| Error Manager | Tracks failed deliveries; exposes retry and clear operations | MyBatis 3.4.2 / PostgreSQL |
| Stats Aggregator | Computes and exposes campaign delivery statistics | Play Framework / PostgreSQL |
| Cache Manager | Handles template cache invalidation in Redis | jedis 3.3.0 |
| Dashboard API | Operational visibility endpoints under `/dashboard/*` | Play Framework / REST |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumPushInfrastructureService` | `externalKafkaCluster_2f8c` | Consumes event-triggered message topics | Kafka (kafka-clients) |
| `continuumPushInfrastructureService` | `externalRedisCluster_5b2e` | Reads template cache; writes queues and rate-limit counters | Redis (jedis) |
| `continuumPushInfrastructureService` | `externalTransactionalDatabase_3f1a` | Reads/writes message state, campaign records, error log | JDBC (MyBatis / PostgreSQL) |
| `continuumPushInfrastructureService` | `externalHdfs_7c9d` | Writes batch delivery logs | HDFS (Hadoop client) |
| `continuumPushInfrastructureService` | `continuumMbusBroker` | Publishes and consumes internal platform events | MBus (mbus-client) |
| `continuumPushInfrastructureService` | `externalRabbitMqBroker_4a6b` | Publishes delivery status events to `status-exchange` | AMQP (rabbitmq-client) |
| `continuumPushInfrastructureService` | `externalInfluxDb_9e3c` | Writes operational metrics | InfluxDB line protocol |
| `continuumPushInfrastructureService` | `externalSmtpService_2a7d` | Sends outbound email messages | SMTP |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-continuumPushInfrastructureService`

> No dynamic views have been defined yet in `views/dynamics.dsl`. See [Flows](flows/index.md) for documented flow sequences.
