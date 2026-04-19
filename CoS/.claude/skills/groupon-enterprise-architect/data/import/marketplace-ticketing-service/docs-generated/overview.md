---
service: "marketplace-ticketing-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Goods / Marketplace Supply"
platform: "Continuum"
team: "Goods Supply Tech"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "JTier jtier-service-pom 5.14.0"
  runtime: "JVM"
  runtime_version: "11 (prod-java11-jtier:2023-12-19)"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Marketplace Ticketing Service Overview

## Purpose

The Marketplace Ticketing Service is a RESTful microservice that manages support ticket workflows between Groupon's marketplace operations and Salesforce. It is the authoritative integration layer for creating, querying, and updating Salesforce tickets on behalf of merchants and internal Groupon teams. The service also maintains a local Postgres database as a fast-access mapping store and event log, while Salesforce remains the source of truth for ticket data.

## Scope

### In scope

- Creating and updating merchant-initiated support tickets in Salesforce
- Creating and updating internal (operations-team) tickets in Salesforce via the Gazebo internal tool
- Storing merchant-to-ticket ID mappings in a local Postgres database
- Consuming Salesforce case-event notifications from the MBus message bus and triggering ticket update workflows
- Publishing information-request update events to the MBus
- Retrieving deal, order, merchant, and fulfillment context from internal services to enrich tickets
- Managing feature flags stored in Postgres
- Managing Salesforce OAuth session tokens
- Sending transactional ticket notification emails via Rocketman
- Escalating tickets and managing ticket CC lists
- Generating merchant ticket reports

### Out of scope

- Hosting a customer-facing ticketing UI (handled by Deal Centre / merchant portal)
- Owning Salesforce itself or its data schema
- General customer support ticketing unrelated to marketplace merchants (handled by Customer Support Service)
- Order management and payment processing

## Domain Context

- **Business domain**: Goods / Marketplace Supply
- **Platform**: Continuum
- **Upstream consumers**: Gazebo (internal operations tool), merchant-facing portal, Deal Centre, internal tools calling the API directly
- **Downstream dependencies**: Salesforce (primary ticket store), Postgres (mapping/flag/token store), MBus (event bus), GPAPI (product/user/coordinator lookup), Goods Stores Service (merchant/store metadata), Order Service (order/voucher details), Goods Outbound Service (fulfillment line-item details), Deal Center Service (deal metadata), Rocketman Service (transactional email), Customer Support Service (CS ticket creation)

## Stakeholders

| Role | Description |
|------|-------------|
| Goods Supply Tech | Owning engineering team; on-call via PagerDuty (service: P9Y8DKM) |
| Goods Engineering | Broader team mailing list (goods-engineering@groupon.com) |
| Marketplace Merchants | Indirect users — submit and track support tickets via the merchant portal |
| Internal Operations (Gazebo) | Internal users creating and managing tickets via the Gazebo tool |
| SRE / PagerDuty | Alert routing via goods-cxx-alerts@groupon.pagerduty.com |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `src/main/docker/Dockerfile` — `prod-java11-jtier:2023-12-19-609aedb` |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.0 | `pom.xml` parent |
| Runtime | JVM | 11 | `Dockerfile`, `.java-version` |
| Build tool | Maven | (mvnvm-managed) | `pom.xml`, `mvnvm.properties` |
| Package manager | Maven | | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-retrofit` | (BOM-managed) | http-framework | HTTP client for downstream REST calls |
| `jtier-daas-postgres` | (BOM-managed) | db-client | DaaS-managed Postgres connection pool |
| `jtier-jdbi` | (BOM-managed) | orm | JDBI SQL object DAO layer |
| `jtier-messagebus-client` | (BOM-managed) | message-client | MBus publish/subscribe client |
| `jtier-messagebus-dropwizard` | 0.4.6 | message-client | Dropwizard MBus listener integration |
| `mbus-client` | 1.5.2 | message-client | Low-level MBus STOMP client |
| `token-bucket` | 1.7 | scheduling | Token-bucket rate limiter (Salesforce RPM cap) |
| `okhttp3/mockwebserver` | (BOM-managed) | testing | HTTP mock server for integration tests |
| `testcontainers` | (BOM-managed) | testing | Docker-based integration test containers |
| `commons-io` | 2.7 | serialization | I/O utilities for attachment handling |
| `antlr-complete` | 3.5.2 | validation | Grammar-based query/filter parsing |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
