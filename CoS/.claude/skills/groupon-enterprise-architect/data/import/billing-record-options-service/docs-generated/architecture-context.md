---
service: "billing-record-options-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumBillingRecordOptionsService, daasPostgresPrimary, raasRedis]
---

# Architecture Context

## System Context

BROS is a container within the `continuumSystem` (Continuum Platform). It sits at the boundary of the payments domain, serving as a read-only configuration oracle for payment method availability. Checkout frontends and payment orchestration services call BROS over HTTP to determine which payment methods to present to a user. BROS itself issues no calls to upstream HTTP services; all its data dependencies are infrastructure stores — a DaaS-managed PostgreSQL database and a RAAS Redis cache.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Billing Record Options Service | `continuumBillingRecordOptionsService` | Backend API | Java, Dropwizard | 1.0.x | Exposes payment method options and billing record configuration APIs for Groupon payment flows |
| DaaS PostgreSQL (stub) | `daasPostgresPrimary` | Database | PostgreSQL | — | Primary relational store for payment method configuration data (owned by DaaS platform) |
| RAAS Redis (stub) | `raasRedis` | Cache | Redis | — | Low-latency cache layer for payment method data (owned by RAAS platform) |

## Components by Container

### Billing Record Options Service (`continuumBillingRecordOptionsService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Payment Methods Resource (`brosPaymentMethodsResource`) | Receives HTTP requests on `/paymentmethods` and delegates to the service layer | JAX-RS Resource |
| Payment Methods Service (`brosPaymentMethodsService`) | Orchestrates request processing: resolves client type, applies country rules, filters and ranks providers, and composes response payload | Service |
| Client Type Service (`brosClientTypeService`) | Maps user-agent strings and role headers to application client type context (e.g., `touch` for mobile) | Service |
| Country Service (`brosCountryService`) | Loads and serves country-level payment method constraints and metadata from the `countries` table | Service |
| Payment Provider Service (`brosPaymentProviderService`) | Loads payment providers, applies include/exclude filter logic, and ranks by provider importance for the resolved client type | Service |
| Payment Type Service (`brosPaymentTypeService`) | Loads and serves payment type definitions (billing record type, variant, flow type) | Service |
| Data Accessor Factory (`brosDataAccessorFactory`) | Constructs JDBI-backed data accessors from the configured DaaS datasource | Factory |
| JDBI Data Accessor (`brosJdbiDataAccessor`) | Aggregates DAOs for applications, countries, providers, client types, and payment types; executes SQL queries against PostgreSQL | JDBI |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `brosPaymentMethodsResource` | `brosPaymentMethodsService` | Invokes payment method orchestration | Direct (in-process) |
| `brosPaymentMethodsService` | `brosClientTypeService` | Resolves client type context | Direct |
| `brosPaymentMethodsService` | `brosCountryService` | Loads country rules | Direct |
| `brosPaymentMethodsService` | `brosPaymentProviderService` | Loads and ranks payment providers | Direct |
| `brosPaymentMethodsService` | `brosPaymentTypeService` | Loads payment type definitions | Direct |
| `brosClientTypeService` | `brosJdbiDataAccessor` | Reads client type mappings | JDBI |
| `brosCountryService` | `brosJdbiDataAccessor` | Reads country metadata | JDBI |
| `brosPaymentProviderService` | `brosJdbiDataAccessor` | Reads payment providers and importance data | JDBI |
| `brosPaymentTypeService` | `brosJdbiDataAccessor` | Reads payment type metadata | JDBI |
| `brosDataAccessorFactory` | `brosJdbiDataAccessor` | Constructs JDBI data accessor instance | Direct |
| `continuumBillingRecordOptionsService` | `daasPostgresPrimary` | Reads and persists payment method configuration | PostgreSQL |
| `continuumBillingRecordOptionsService` | `raasRedis` | Uses cache dependency for low-latency reads | Redis |

## Architecture Diagram References

- System context: `contexts-continuumBillingRecordOptionsService`
- Container: `containers-continuumBillingRecordOptionsService`
- Component: `components-continuumBillingRecordOptionsService`
