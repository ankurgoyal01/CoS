---
service: "pricing-control-center-jtier"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumPricingControlCenterJtierService, continuumPricingControlCenterJtierPostgres, gcpDynamicPricingBucket]
---

# Architecture Context

## System Context

Pricing Control Center JTier is a backend service within the **Continuum** platform. It serves as the operational backbone of the Control Center UI, which is used by Groupon's revenue management team. The service sits between the internal user-facing web interface and the downstream Pricing Service, acting as an orchestration layer that validates, batches, and submits pricing programs. It also consumes ML model outputs from Hive and GCS to automate sale creation for data-driven channels (Custom ILS, Sellout, RPO).

External callers include sales representatives and inventory managers via the Control Center UI. The service calls `continuumPricingService` to register and remove pricing programs, `continuumVoucherInventoryService` for inventory constraints, and `continuumUsersService` for authentication and role validation.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Pricing Control Center JTier Service | `continuumPricingControlCenterJtierService` | Service | Java, JTier, Dropwizard | 1.0.x | Backend service for creating, validating, scheduling, unscheduling, and monitoring item-level sale programs |
| Pricing Control Center PostgreSQL | `continuumPricingControlCenterJtierPostgres` | Database | PostgreSQL | GDS-managed | Transactional datastore for sales, sale products, scheduling state, versions, and Quartz metadata |
| Dynamic Pricing GCS Bucket | `gcpDynamicPricingBucket` | Storage | Google Cloud Storage | | GCS bucket containing Retail Price Optimization extracts |

## Components by Container

### Pricing Control Center JTier Service (`continuumPricingControlCenterJtierService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Resources (`pccApiResources`) | REST endpoints for sales lifecycle, search, identity, user management, CSV uploads, CSV downloads, and health checks | JAX-RS Resources |
| Scheduling Engine (`pccSchedulingEngine`) | Quartz jobs and orchestrators that run ILS scheduling, unscheduling, analytics uploads, sellout program creation, RPO, and Custom ILS flows | Quartz, Job Orchestration |
| Data Access Layer (`pccDataAccess`) | JDBI DAOs and result-set mappers for sales, products, users, tasks, versions, and analytics tables | JDBI |
| External Client Layer (`pccExternalClients`) | Retrofit and SDK integrations for pricing service, voucher inventory, users service, Gdoop, Hive JDBC, and GCS | Retrofit, Hive JDBC, GCP SDK |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `salesRep` | `continuumPricingControlCenterJtierService` | Creates and manages sales, triggers schedule/unschedule workflows | HTTP/REST |
| `continuumPricingControlCenterJtierService` | `continuumPricingControlCenterJtierPostgres` | Reads and writes transactional sale and scheduling state | JDBC/PostgreSQL |
| `continuumPricingControlCenterJtierService` | `continuumPricingService` | Creates, updates, and deletes pricing programs | HTTP/REST (Retrofit) |
| `continuumPricingControlCenterJtierService` | `continuumVoucherInventoryService` | Retrieves voucher/min-per-pledge and inventory-related data | HTTP/REST (Retrofit) |
| `continuumPricingControlCenterJtierService` | `continuumUsersService` | Validates and resolves user and role information | HTTP/REST (Retrofit) |
| `continuumPricingControlCenterJtierService` | `hdfsStorage` | Reads sellout flux files and model outputs | HDFS (Gdoop) |
| `continuumPricingControlCenterJtierService` | `hiveWarehouse` | Queries flux model schedules, superset deal data, and Custom ILS model outputs | Hive JDBC |
| `continuumPricingControlCenterJtierService` | `gcpDynamicPricingBucket` | Downloads RPO extracts from cloud object storage | GCP SDK |
| `continuumPricingControlCenterJtierService` | `messagingSaaS` | Sends operational and failure notification emails via SMTP | SMTP |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumPricingControlCenterJtierService`
- Component: `components-pricing-control-center-jtier-service-components`
- Dynamic flow: `dynamic-ils-scheduling-flow`
