---
service: "identity-service"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumIdentity"
  containers: [continuumIdentityServiceApp, continuumIdentityServiceMbusConsumer, continuumIdentityServicePrimaryPostgres, continuumIdentityServiceRedis]
---

# Architecture Context

## System Context

identity-service is a core Continuum platform service. It sits between upstream application consumers (web, mobile, partner services) and the authoritative identity data store (PostgreSQL). It also participates in the Groupon Message Bus ecosystem, publishing identity lifecycle events consumed by downstream systems and consuming GDPR erasure and audit events. The service bridges identity data across the Continuum (PostgreSQL) and PWA (MySQL) platforms, making it a key integration point in the Groupon account management landscape.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Identity HTTP API | `continuumIdentityServiceApp` | Application | Ruby / Sinatra 3.x / Puma | 3.0.2 | Synchronous REST API for identity CRUD operations; authenticates via Bearer JWT |
| Mbus Consumer Worker | `continuumIdentityServiceMbusConsumer` | Application | Ruby / Resque / g-bus | 3.0.2 | Async worker processing GDPR erasure events and dog-food audit events from the Message Bus |
| Primary PostgreSQL | `continuumIdentityServicePrimaryPostgres` | Database | PostgreSQL | — | Authoritative store for identity records, API keys, and message bus message log |
| Redis | `continuumIdentityServiceRedis` | Cache | Redis | 4.7.1 | Identity data cache and Resque job queue backing store |

## Components by Container

### Identity HTTP API (`continuumIdentityServiceApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Identity Router | Routes `/v1/identities` requests to handlers | Sinatra |
| Identity Handler | Creates, reads, and updates identity records | ActiveRecord / pg |
| Erasure Handler | Initiates GDPR erasure via `POST /v1/identities/erasure` | ActiveRecord / messagebus |
| JWT Auth Middleware | Validates Bearer JWT on protected endpoints | jwt 2.5.0 |
| Rate Limiter | Throttles and blocks abusive request patterns | rack-attack |
| Event Publisher | Publishes identity lifecycle events to Message Bus | messagebus 0.3.6 |
| Health Endpoints | Responds to `/heartbeat` and `/status` | Sinatra |

### Mbus Consumer Worker (`continuumIdentityServiceMbusConsumer`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| GDPR Erasure Consumer | Consumes erasure request events; orchestrates identity data removal | g-bus 0.0.1 / Resque |
| Audit Event Consumer | Consumes dog-food audit events for internal audit trail | g-bus 0.0.1 |
| Erasure Completion Publisher | Publishes `gdpr.account.v1.erased.complete` after erasure | messagebus 0.3.6 |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumIdentityServiceApp` | `continuumIdentityServicePrimaryPostgres` | Reads and writes identity records, API keys, message log | ActiveRecord / SQL |
| `continuumIdentityServiceApp` | `continuumIdentityServiceRedis` | Caches identity data | Redis protocol |
| `continuumIdentityServiceApp` | Message Bus | Publishes identity lifecycle events | Thrift / g-bus |
| `continuumIdentityServiceMbusConsumer` | Message Bus | Consumes GDPR erasure and audit events | Thrift / g-bus |
| `continuumIdentityServiceMbusConsumer` | `continuumIdentityServicePrimaryPostgres` | Reads and removes identity data during erasure | ActiveRecord / SQL |
| `continuumIdentityServiceMbusConsumer` | `continuumIdentityServiceRedis` | Resque job queue | Redis protocol |
| `continuumIdentityServiceMbusConsumer` | Message Bus | Publishes `gdpr.account.v1.erased.complete` | Thrift / g-bus |
| Upstream consumers | `continuumIdentityServiceApp` | Identity CRUD API calls | REST / HTTPS / Bearer JWT |

## Architecture Diagram References

- System context: `contexts-continuumIdentity`
- Container: `containers-continuumIdentity`
- Component: `components-continuumIdentityServiceApp`
- Dynamic view — account erasure: `dynamic-account-erasure-flow`
- Dynamic view — API identity creation: `dynamic-api-create-identity`
- Dynamic view — users sync cycle: `dynamic-users-sync-cycle`
