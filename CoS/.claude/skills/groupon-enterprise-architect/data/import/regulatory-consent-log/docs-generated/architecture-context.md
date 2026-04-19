---
service: "regulatory-consent-log"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumRegulatoryConsentLog"
  containers:
    - "continuumRegulatoryConsentLogApi"
    - "continuumRegulatoryConsentLogWorker"
    - "continuumRegulatoryConsentLogDb"
    - "continuumRegulatoryConsentRedis"
    - "continuumRegulatoryConsentMessageBus"
---

# Architecture Context

## System Context

The Regulatory Consent Log service is a Continuum-platform backend service sitting at the intersection of Groupon's consumer-facing flows (registration, checkout, subscription) and the privacy/erasure pipeline. Consumer-facing services POST consents through it; the Users Service and Transcend Privacy Platform drive erasure workflows through it. It owns the canonical store of user consent audit records and erased b-cookie mappings required for GDPR compliance.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| Regulatory Consent Log API | `continuumRegulatoryConsentLogApi` | Backend / API | Java 11, Dropwizard, Jersey | REST API exposing consent logging, cookie lookup, user erasure initiation, and Transcend webhook endpoints |
| Regulatory Consent Log Utility Worker | `continuumRegulatoryConsentLogWorker` | Backend / Worker | Java 11, Dropwizard, Quartz | Async runtime handling MBus listeners, Quartz jobs, Cronus publishing, and the cookie-erasure pipeline |
| Regulatory Consent Log Postgres | `continuumRegulatoryConsentLogDb` | Database | PostgreSQL (DaaS) | Primary relational store for consents, cookies, erasure records, Cronus message outbox rows, and user events |
| Regulatory Consent Redis (RaaS) | `continuumRegulatoryConsentRedis` | Cache / Queue | Redis (RaaS) | Redis queues and pub/sub channels for the user erasure async workflow |
| Regulatory Message Bus | `continuumRegulatoryConsentMessageBus` | Messaging | MBus / ActiveMQ Artemis | Topics for user erasure, erasure completion, consent log, and user reactivation events |

## Components by Container

### Regulatory Consent Log API (`continuumRegulatoryConsentLogApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Create Consent Endpoint | Receives `POST /v1/consents` requests; validates identifier/consumer rules; delegates to service | JAX-RS |
| Create Consent Service | Maps incoming consent payloads to core DB rows and Cronus outbox rows | Java |
| Create Consent Transaction Adapter | Persists consent records and Cronus message rows atomically in one JDBI transaction | JDBI |
| Get Consents Endpoint | Receives `GET /v1/consents` requests; routes to lookup service | JAX-RS |
| Get Consents Service | Executes consent lookups with optional `workflowType` filtering | Java |
| Get Consents DB Adapter | Reads consent data from Postgres using JDBI mappers | JDBI |
| Get Cookie Resource | Receives `GET /v1/cookie` requests; returns erased-user info for a given b-cookie | JAX-RS |
| Cookie Read Adapter | Loads erased cookie rows from Postgres | JDBI |
| User Erasure Endpoint | Receives `POST /v1/erasure` (initiate) and `GET /v1/users/{user_id}/erasureStatus` requests | JAX-RS |
| User Erasure API Service | Validates and records erasure requests; exposes erasure status | Java |
| Register User Event Endpoint | Webhook endpoint for Transcend access and erasure event callbacks | JAX-RS |
| Transcend Users Event Service | Verifies JWT signatures from Transcend; orchestrates erasure and access upload flows | Java, Retrofit |
| Register User Event DBI | Persists user event status and audit records | JDBI |

### Regulatory Consent Log Utility Worker (`continuumRegulatoryConsentLogWorker`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| User Erasure MBus Listener | Consumes user erasure events from MBus; enqueues user IDs into Redis work queue | MessageBus Consumer |
| User Erased Redis Pub/Sub Worker | Dequeues user IDs from Redis; orchestrates Janus lookup, cookie writes, and completion event publishing | Redis Pub/Sub |
| Janus Aggregator Client | HTTP client that retrieves erased-user b-cookie mappings from Janus Aggregator | HTTP Client (Retrofit) |
| Cookie Write Adapter | Persists erased cookie-to-user mappings into Postgres | JDBI |
| Cronus Publisher | Picks up outbox message rows from Postgres and publishes them to MBus topics | Cronus Bundle (Quartz) |
| Erasure Complete Message Reader | Consumes erasure-completion messages from MBus | MessageBus Consumer |
| Erasure Complete Processor | Updates erasure records to reflect completion status | Java |
| User Erasure Job | Quartz job that schedules and triggers account deletion after the configured retention period | Quartz |
| User Erasure Worker Service | Calls Users Service to erase accounts; marks records as processed | Java, Retrofit |
| Async User Event Executor | Quartz job that triggers async processing of pending Transcend access/erasure events | Quartz |
| Async User Event Handler Service | Processes pending access events and uploads data to Lazlo and Transcend APIs | Java, Retrofit |
| User Reactivation Consumer | MBus consumer for user reactivation events | MessageBus Consumer |
| User Reactivation Processor | Updates erasure state when a previously erased user reactivates | Java |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumRegulatoryConsentLogApi` | `continuumRegulatoryConsentLogDb` | Reads and writes consents, cookies, erasure and user event records | JDBI / SQL |
| `continuumRegulatoryConsentLogApi` | `continuumRegulatoryConsentMessageBus` | Stores Cronus message outbox rows published to MBus topics | JDBI (outbox) |
| `continuumRegulatoryConsentLogApi` | `transcendPrivacyPlatform` | Validates webhook JWT signatures; uploads erasure/access confirmations | HTTP/JSON |
| `continuumRegulatoryConsentLogApi` | `lazloApi` | Uploads access data for Groupon brand | HTTP/JSON |
| `continuumRegulatoryConsentLogApi` | `livingSocialTranscendApi` | LivingSocial-brand Transcend integrations | HTTP/JSON |
| `continuumRegulatoryConsentLogApi` | `livingSocialLazloApi` | Uploads access data for LivingSocial brand | HTTP/JSON |
| `continuumRegulatoryConsentLogWorker` | `continuumRegulatoryConsentLogDb` | Reads/writes cookies, erasure status, Cronus messages, and user events | JDBI / SQL |
| `continuumRegulatoryConsentLogWorker` | `continuumRegulatoryConsentRedis` | Stores user erasure queue entries; publishes Redis notifications | Redis Pub/Sub |
| `continuumRegulatoryConsentLogWorker` | `continuumRegulatoryConsentMessageBus` | Consumes/publishes erasure, completion, consent log, and reactivation events | MBus |
| `continuumRegulatoryConsentLogWorker` | `janusAggregatorService` | Retrieves erased-user b-cookie mappings | HTTP/JSON |
| `continuumRegulatoryConsentLogWorker` | `transcendPrivacyPlatform` | Uploads access data and erasure confirmations during async jobs | HTTP/JSON |
| `continuumRegulatoryConsentLogWorker` | `lazloApi` | Uploads access data via Lazlo during async jobs | HTTP/JSON |
| `continuumRegulatoryConsentLogWorker` | `livingSocialLazloApi` | Uploads access data for LivingSocial via Lazlo | HTTP/JSON |

## Architecture Diagram References

- Container: `containers-continuumRegulatoryConsentLog`
- Component (API): `components-continuumRegulatoryConsentLogApi`
- Component (Worker): `components-continuumRegulatoryConsentLogWorker`
