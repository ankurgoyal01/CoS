---
service: "partner-service"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "3PIP Partner Management"
platform: "Continuum"
team: "SOX Inscope / 3PIP"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Dropwizard"
  framework_version: "2.x"
  runtime: "JVM"
  runtime_version: "17"
  build_tool: "Maven"
  build_tool_version: "3"
  package_manager: "Maven"
---

# Partner Service Overview

## Purpose

Partner Service is the central platform component responsible for managing third-party integration partner (3PIP) onboarding, configuration, and operational metrics within the Continuum commerce engine. It acts as the authoritative record for partner mappings, deal divisions, and product-place associations, orchestrating multi-step workflows that span Salesforce, Deal Catalog, ePOS, and several Continuum internal services. The service is SOX in-scope, reflecting its role in controlling partner access to commerce inventory and financial-grade data flows.

## Scope

### In scope

- Partner entity management: create, read, update partner records and their configuration
- Partner onboarding workflow orchestration across internal and external systems
- Deal-to-division mapping and reconciliation against Deal Catalog and Deal Management API
- Product-to-place mapping via Geo Places integration
- Audit log recording for partner-affecting operations
- Partner uptime tracking and metrics reporting
- Simulator module for safe integration testing without live data side-effects
- Publishing partner workflow events to MBus

### Out of scope

- Deal creation and lifecycle management (owned by `continuumDealManagementApi`)
- Geographic data ownership (owned by `continuumGeoPlacesService`)
- User and contact identity management (owned by `continuumUsersService`)
- Merchant access authorization (external system, not yet federated)
- Jira and PagerDuty incident management integration (external, not yet federated)

## Domain Context

- **Business domain**: 3PIP Partner Management
- **Platform**: Continuum
- **Upstream consumers**: Internal Continuum services and operator tooling calling partner endpoints
- **Downstream dependencies**: `continuumPartnerServicePostgres`, `messageBus`, `continuumDealCatalogService`, `continuumDealManagementApi`, `continuumEpodsService`, `continuumGeoPlacesService`, `continuumUsersService`, Salesforce, AWS S3, Google Sheets

## Stakeholders

| Role | Description |
|------|-------------|
| SOX Inscope / 3PIP Team | Service owners responsible for development and operations |
| Partner Operations | Business team that onboards and manages 3PIP partners |
| Finance / Compliance | SOX audit consumers relying on audit log integrity |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | inventory summary |
| Framework | Dropwizard | 2.x | inventory summary |
| JTier integration layer | JTier | 5.14.0 | inventory summary |
| Build tool | Maven | 3 | inventory summary |
| Package manager | Maven | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-service-pom | 5.14.0 | http-framework | JTier parent POM providing Dropwizard base configuration |
| hk2-di-core | — | http-framework | HK2 dependency injection integration for Dropwizard |
| jtier-daas-postgres | — | db-client | JTier-managed PostgreSQL datasource provisioning |
| jtier-jdbi3 | — | orm | JDBI 3 integration for SQL mapping and DAO access |
| Flyway | — | db-client | Database schema migration management |
| jtier-retrofit | — | http-framework | JTier-managed Retrofit HTTP client for outbound calls |
| jtier-messagebus-client | — | message-client | JTier MBus client for JMS/STOMP publish and consume |
| jtier-hk2-quartz | — | scheduling | Quartz scheduler integration via HK2 for batch jobs |
| AWS SDK | 1.12.259 | db-client | S3 client for partner document and artifact uploads |
| Gson | 2.8.6 | serialization | JSON serialization and deserialization |
| Swagger | — | validation | OpenAPI/Swagger endpoint documentation |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
