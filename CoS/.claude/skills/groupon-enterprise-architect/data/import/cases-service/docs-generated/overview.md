---
service: "cases-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Merchant Experience"
platform: "Continuum"
team: "Merchant Experience"
status: active
tech_stack:
  language: "Java"
  language_version: "21"
  framework: "Dropwizard / JTier"
  framework_version: "5.14.0"
  runtime: "JVM"
  runtime_version: "21"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Merchant Cases Service (MCS) Overview

## Purpose

The Merchant Cases Service (MCS) is a JTier application that manages merchant support case workflows by orchestrating interactions with Salesforce CRM. It serves as the primary backend for Groupon's Merchant Center support inbox, enabling merchants to create, view, reply to, and manage cases across multiple case types (support, refund, deal-approval, callback, DAC7/RRDP). It also exposes a knowledge management layer (powered by Inbenta) so merchants can self-serve before escalating to a support agent.

## Scope

### In scope

- Creating and retrieving merchant support cases in Salesforce (standard, refund, deal-edit, callback, DAC7/RRDP types)
- Replying to and updating case status in Salesforce
- Tracking unread case and refund-case counts per merchant, backed by Redis
- Serving knowledge management content (topics, articles, search, popular/suggested articles) via Inbenta
- Processing asynchronous Salesforce events from the message bus (case create/update, case-event, opportunity, notifications, account updates)
- Sending transactional email notifications via Rocketman
- Serving issue category and subcategory lists for case-creation forms
- Surfacing merchant support contact details
- Deal approval case management for deal edit workflows
- Banking/payment information status lookup

### Out of scope

- Salesforce CRM administration and record ownership (owned by Salesforce)
- Merchant authentication and access control (delegated to `mxMerchantAccessService`)
- User identity management (delegated to `continuumUsersService`)
- Merchant account data management (delegated to `continuumM3MerchantService`)
- Notification delivery platform (delegated to `mxNotificationService`)
- Deal catalog data (delegated to `continuumDealCatalogService`)

## Domain Context

- **Business domain**: Merchant Experience — support case management
- **Platform**: Continuum
- **Upstream consumers**: Merchant Center frontend (merchantSupportClient), internal tooling via API key (`X-Api-Key` header)
- **Downstream dependencies**: Salesforce CRM, Inbenta knowledge API, Rocketman transactional email, Users Service, M3 Merchant Service, Deal Catalog Service, MX Notification Service, MX Merchant Access Service, MX Merchant Preparation Service, Salesforce Cache Service (Reading Rainbow), message bus (JMS)

## Stakeholders

| Role | Description |
|------|-------------|
| Team owner | Merchant Experience team (`echo-dev@groupon.com`) |
| Team lead | abhishekkumar |
| SRE alerts | echo-dev+alerts@groupon.com |
| PagerDuty | https://groupon.pagerduty.com/services/PLT77QZ |
| Slack | echo-support channel |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 21 | `pom.xml` `project.build.targetJdk=21`, `.java-version` |
| Framework | JTier (Dropwizard-based) | 5.14.0 | `pom.xml` parent `jtier-service-pom:5.14.0` |
| Runtime | JVM (Eclipse Temurin) | 21 | `src/main/docker/Dockerfile` base image `prod-java21-jtier` |
| Build tool | Maven | 3.5.2+ | `README.md`, `.mvn/maven.config` |
| Container base | docker.groupondev.com/jtier/prod-java21-jtier | 2024-12-11-v2 | `src/main/docker/Dockerfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `mx-jtier-commons` | 2.0.49 | http-framework | Shared HTTP clients for M3, DealCatalog, Users, Nots, MAS, MPRES |
| `mbus-client` | 1.4.1 | message-client | JMS-based message bus consumer for Salesforce topics |
| `dropwizard-redis` | 2.0.2-0 | db-client | Redis connection management via Jedis for case count caching |
| `jtier-retrofit` | (BOM-managed) | http-framework | Retrofit HTTP client integration for JTier |
| `jtier-rxjava3-retrofit` | (BOM-managed) | http-framework | RxJava3-wrapped Retrofit for async HTTP calls |
| `jtier-auth-bundle` | (BOM-managed) | auth | Client ID / API-key authentication |
| `jtier-opslog` | 0.9.0 | logging | Operational structured logging (Steno) |
| `jtier-jsonholder-bundle` | (BOM-managed) | serialization | JSON holder/wrapper utilities |
| `swagger-codegen-maven-plugin` | 3.0.8 | serialization | Generates server and client Java stubs from OpenAPI specs |
| `commons-collections4` | 4.4 | validation | Apache Commons Collections utilities |
| `reflections` | 0.10.2 | scheduling | Classpath scanning for runtime reflection |
| `opentelemetry-javaagent` | bundled | metrics | OpenTelemetry Java agent for distributed tracing |
| `rest-assured` | 4.2.0 | testing | Integration test HTTP assertions |
| `wiremock-standalone` | 2.26.3 | testing | HTTP service stubbing for integration tests |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
