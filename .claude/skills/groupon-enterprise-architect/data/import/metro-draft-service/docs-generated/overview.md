---
service: "metro-draft-service"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Merchant Deal Drafting"
platform: "Continuum"
team: "Metro Team (metro-dev-blr@groupon.com)"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "JTier 5.14.0"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Metro Draft Service Overview

## Purpose

Metro Draft Service (draft-service) is the Continuum platform backend responsible for the full lifecycle of merchant deal drafting — from initial creation through validation, merchandising change management, and final publishing. It serves as the authoritative orchestration hub for deal data, integrating with 30+ downstream services to validate, enrich, and publish deals to Groupon's commerce systems. The service enables Groupon's Metro (merchant operations) teams and merchant self-service flows to create and manage deal content before it reaches consumers.

## Scope

### In scope

- Draft deal creation, update, cloning, and deletion via REST API
- Deal status management and workflow state transitions
- Publishing orchestration: syncing deals to DMAPI, MDS, and Deal Catalog
- Merchandising change management (MCM) — audit logs, change sets, and approvals
- Dynamic pricing structure (PDS) defaults and fine print generation
- Deal scoring calculation and sync to Salesforce
- Redemption configuration including voucher inventory and code pool allocation
- File and document upload management
- Vetting flow management and eligibility checking
- Merchant onboarding, validation, and permission enforcement via RBAC
- Place enrichment and geo metadata resolution
- Recommendation and structure suggestion generation
- Survey and questionnaire persistence
- Scheduled background jobs (reminders, retries, banners, notifications)
- Signed deal event consumption and publishing

### Out of scope

- Consumer-facing deal display and purchase (handled by MBNXT / Deal Catalog)
- Voucher fulfillment and redemption execution (handled by VIS / Redemption services)
- Merchant account management (handled by M3 / MAS)
- Contract authoring (handled by Contract Service)
- Taxonomy and geo data mastering (handled by Taxonomy / GeoPlaces services)

## Domain Context

- **Business domain**: Merchant Deal Drafting
- **Platform**: Continuum
- **Upstream consumers**: Metro internal tooling, merchant self-service portals, and partner onboarding flows calling via HTTP
- **Downstream dependencies**: DMAPI, Marketing Deal Service (MDS), Deal Catalog, VIS, RBAC, M3, Users, Taxonomy, GeoPlaces, GeoDetails, InferPDS, Rainbow, GenAI, Partner Service, ePODS, GIMS, NOTS, MAS, UMAPI, Image Service, Video Service, BIS Images, CFS, Merchant Self Service, Merchant Case Service, Dealbook, Contract Service, AIDG, ElasticSearch, Slack, Salesforce

## Stakeholders

| Role | Description |
|------|-------------|
| Metro Team (BLR) | Owning engineering team (metro-dev-blr@groupon.com) |
| Lead: abhishekkumar | Primary technical contact |
| Merchant Operations | Internal users managing deals through Metro tooling |
| Merchants | Use self-service portals backed by this service |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | architecture DSL: "Java 11, Dropwizard, HK2, RxJava3" |
| Framework | Dropwizard / JTier | 5.14.0 | inventory summary |
| Runtime | JVM | 11 | inventory summary |
| Build tool | Maven | — | inventory summary |
| Package manager | Maven | — | inventory summary |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-daas-postgres | — | db-client | JTier managed PostgreSQL data access |
| jtier-jdbi | — | orm | JDBI-based DAO layer for SQL queries |
| jtier-migrations | — | db-client | Database schema migration management |
| jtier-rxjava3 | 0.16.3 | http-framework | Reactive async execution with RxJava3 integration |
| jtier-messagebus-dropwizard | — | message-client | MBus publish/subscribe integration |
| jtier-retrofit | — | http-framework | Retrofit HTTP client wiring for downstream services |
| HK2 | 2.2.1 | http-framework | Dependency injection container |
| Freemarker | 2.3.33 | serialization | Template rendering for fine print and content generation |
| Quartz | — | scheduling | Scheduled background job execution |
| Salesforce SOAP client | — | http-framework | Salesforce API integration for scores and contracts |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
