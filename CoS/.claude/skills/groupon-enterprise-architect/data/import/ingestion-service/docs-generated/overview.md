---
service: "ingestion-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Customer Support / GSO Engineering"
platform: "Continuum"
team: "GSO Engineering"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard (JTier)"
  framework_version: "jtier-service-pom 5.14.0"
  runtime: "JVM"
  runtime_version: "prod-java11-jtier:2023-12-19"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Operations Data Ingestion Service Overview

## Purpose

The ingestion-service (also known as ODIS — Operations Data Ingestion Service) is a JTier/Dropwizard-based Java service that acts as a central integration hub for Groupon's Customer Support operations. It exposes REST API endpoints enabling external systems (such as Zingtree chatbot) to create and manage Salesforce customer support cases, process refunds, retrieve memo and deal data, and issue JWT tokens. It also runs Quartz background jobs to retry failed Salesforce ticket creations and to process merchant-approved refund orders sourced from Salesforce.

## Scope

### In scope
- Exposing authenticated REST APIs for creating and escalating Salesforce email cases/tickets
- Providing memo lookup endpoints (by deal UUID or merchant UUID) backed by the CAAP API
- Executing customer order refunds (to Groupon Bucks or original payment) via the CAAP API
- Retrieving Salesforce account, opportunity, and messaging session data
- Issuing and validating JWT tokens for customer-facing authentication flows
- Fetching deal details from the Lazlo API and user details from the Users Service
- Scheduled background job: retrying failed Salesforce ticket creation requests
- Scheduled background job: processing merchant-approved refund orders from Salesforce
- Proxying CAAP API requests through `/proxy/{path}` endpoints
- Checking Signifyd fraud status for orders

### Out of scope
- Storing customer PII beyond transient job state in MySQL
- Direct Zendesk ticket management (historical; current focus is Salesforce)
- Customer-facing UI or front-end rendering
- Deal creation or merchant onboarding workflows
- Order creation or payment processing (refund execution delegated to CAAP)

## Domain Context

- **Business domain**: Customer Support (GSO — Global Service Operations)
- **Platform**: Continuum
- **Upstream consumers**: Zingtree chatbot (webhook caller), other GSO tooling calling via `X-API-KEY` + `client_id` auth
- **Downstream dependencies**: Salesforce (case/opportunity/messaging/survey management), CAAP API (memos, refunds, order data, user data, incentives), Lazlo API (deal/merchant data), Orders RO Service (order information), Users Service (customer attributes), Zingtree API (session transcripts)

## Stakeholders

| Role | Description |
|------|-------------|
| GSO Engineering | Service owner and primary developers (gso-india-engineering@groupon.com) |
| Customer Support Agents | Indirect users — benefit from cases auto-created via Zingtree |
| GSO Platform / SRE | PagerDuty notifications (ticket-ingestion-service@groupon.pagerduty.com) |
| Criticality Tier 4 | Business-critical tier as documented in GEARS |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `src/main/docker/Dockerfile` (prod-java11-jtier), `.java-version` (1.8 local; 11 in Docker) |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.0 | `pom.xml` parent |
| Runtime | JVM / prod-java11-jtier | 2023-12-19-609aedb | `src/main/docker/Dockerfile` |
| Build tool | Maven | 3.5.2 | `mvnvm.properties` |
| Package manager | Maven | 3.5.2 | `mvnvm.properties` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-okhttp | (parent-managed) | http-framework | HTTP client transport layer |
| jtier-retrofit | (parent-managed) | http-framework | Retrofit HTTP client wrapper for downstream service calls |
| jtier-auth-bundle | (parent-managed) | auth | Client ID + secret authentication enforcement |
| jtier-quartz-bundle | (parent-managed) | scheduling | Quartz scheduler integration for background jobs |
| jtier-quartz-mysql-migrations | (parent-managed) | scheduling | MySQL-backed Quartz job persistence and migrations |
| jtier-daas-mysql | (parent-managed) | db-client | DaaS MySQL connection management |
| jtier-jdbi | (parent-managed) | orm | JDBI DAO layer for MySQL access |
| jtier-migrations | (parent-managed) | db-client | Database schema migration runner |
| jtier-messagebus-client | (parent-managed) | message-client | Message bus client (declared but events not observed in active use) |
| oauth2-oidc-sdk (Nimbus) | 9.37.2 | auth | JWT and JWK key generation and validation |
| jsoup | 1.17.2 | serialization | HTML parsing (used in email body construction) |
| stringtemplate | 3.2 | serialization | Template rendering for Salesforce email body content |
| json-smart | 2.4.8 | serialization | JSON parsing utility |
| wiremock | 2.3.1 | testing | HTTP mock server for integration tests |
| awaitility | 4.0.1 | testing | Async assertion utility for tests |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for the full list.
