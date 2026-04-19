---
service: "billing-record-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: ["continuumBillingRecordService", "continuumBillingRecordPostgres", "continuumBillingRecordRedis"]
---

# Architecture Context

## System Context

Billing Record Service is a backend Java service in the Continuum platform. It sits at the intersection of the checkout flow and the payments infrastructure: upstream services call it to create and retrieve payment instrument records, while it calls downstream payment gateways (PCI-API, Braintree, Adyen) to manage token lifecycles. It also participates in the Groupon Message Bus to receive GDPR erasure commands from the Regulatory Consent Log Service and to publish erasure completion events.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Billing Record Service | `continuumBillingRecordService` | Backend API | Java, Spring MVC (Tomcat) | 1.8 / 4.3.7 | Primary service: exposes REST API for billing record CRUD and lifecycle operations |
| Billing Record PostgreSQL | `continuumBillingRecordPostgres` | Database | PostgreSQL | 42.7.3 driver | Transactional store for billing records, purchaser state, and payment metadata |
| Billing Record Redis Cache | `continuumBillingRecordRedis` | Cache | Redis (Jedis 2.9.0) | — | Cache for billing-record retrieval with selective invalidation |

## Components by Container

### Billing Record Service (`continuumBillingRecordService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Layer (`brs_apiLayer`) | Handles incoming REST requests on v2, v3, and internal endpoints; validates request contracts and routes to the service layer | Spring MVC Controller |
| Billing Record Service Layer (`brs_coreService`) | Business logic for billing record creation, update, validation, migration, and GDPR handling | Spring Service |
| Persistence Layer (`brs_persistence`) | JPA repositories for BillingRecord, Purchaser, and Orders-linked entities; executes reads and writes via JDBC | Spring Data JPA |
| External Integration Adapters (`brs_integrationAdapters`) | HTTP clients for PCI-API, Braintree SDK calls, Message Bus consumers/producers, and Orders data dependencies | HTTP / JMS / JDBC Adapters |
| Cache Adapter (`brs_cacheAdapter`) | Redis-backed cache service; writes and evicts billing-record query results | Redis Client Adapter |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCheckoutReloadedService` | `continuumBillingRecordService` | Creates, updates, and retrieves billing records | HTTP/JSON |
| `continuumOrdersService` | `continuumBillingRecordService` | Requests billing record lookups by legacy order references | HTTP/JSON |
| `continuumBillingRecordService` | `continuumBillingRecordPostgres` | Reads and writes billing records, payment data, and purchaser state | JDBC |
| `continuumBillingRecordService` | `continuumBillingRecordRedis` | Reads and writes cache entries for billing records | Redis protocol |
| `continuumBillingRecordService` | `paymentGateways` | Manages payment token operations and profile references (PCI-API, Braintree, Adyen) | HTTPS API |
| `continuumBillingRecordService` | `messageBus` | Consumes GDPR/token-erasure events and publishes completion events | STOMP/JMS |
| `brs_apiLayer` | `brs_coreService` | Validates request contracts and delegates billing record operations | in-process |
| `brs_coreService` | `brs_persistence` | Reads and writes billing records and purchaser entities | in-process |
| `brs_coreService` | `brs_integrationAdapters` | Invokes PCI, Braintree, Message Bus, and Orders integrations | in-process |
| `brs_coreService` | `brs_cacheAdapter` | Caches and invalidates billing record query results | in-process |

## Architecture Diagram References

- Container: `containers-billing-record-service`
- Component: `components-billing-record-service`
- Dynamic view: `dynamic-billing-record-create`
