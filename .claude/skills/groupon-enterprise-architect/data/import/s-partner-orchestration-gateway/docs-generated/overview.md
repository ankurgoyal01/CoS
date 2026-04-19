---
service: "s-partner-orchestration-gateway"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Partner Integrations / Wallet"
platform: "Continuum"
team: "engage"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Dropwizard / JTier"
  framework_version: "5.14.0 (parent POM)"
  runtime: "JVM"
  runtime_version: "17"
  build_tool: "Maven"
  package_manager: "Maven"
---

# S Partner Orchestration Gateway Overview

## Purpose

The S Partner Orchestration Gateway (S-POG) is a coordination service for integrating Groupon inventory with significant partner wallet applications. Its primary integration is Google Pay (GPay), providing the Google Pay application with signed JWT wallet payloads containing Groupon offer data, and processing save-to-wallet callbacks from Google. The service also keeps Google Wallet offer objects current by listening to inventory unit update events from the Groupon message bus and propagating redemption state and barcode changes to the Google Wallet API.

## Scope

### In scope

- Building and signing JWT wallet payloads for Google Pay "Save to Wallet" flows
- Receiving and processing save-to-wallet callback notifications from Google Pay
- Consuming inventory unit update events (VIS and TPIS) from the message bus
- Fetching inventory unit details from Voucher Inventory Service (VIS), Third-Party Inventory Service (TPIS), Goods Inventory Service (GIS), Getaways, and GLive
- Fetching deal metadata from Deal Catalog and deal content from API Lazlo
- Updating Google Wallet offer objects (state transitions and barcode updates) via Google Wallet Objects API
- Persisting wallet unit mappings (Groupon inventory unit to Google Wallet object) in PostgreSQL
- Distributed resource locking via PostgreSQL advisory locks to prevent concurrent update races

### Out of scope

- Apple Wallet integration (endpoint exists but returns empty; future scope)
- Order placement and payment processing
- Inventory unit creation or direct modification of inventory records (reads and updates only)
- Customer identity management

## Domain Context

- **Business domain**: Partner Integrations / Wallet
- **Platform**: Continuum
- **Upstream consumers**: Google Pay application (HTTPS); Groupon MessageBus (MBus/JMS)
- **Downstream dependencies**: Voucher Inventory Service, Third-Party Inventory Service, Goods Inventory Service, Getaways Inventory Service, GLive Inventory Service, Deal Catalog Service, API Lazlo Service, Google Wallet API, PostgreSQL (DaaS), Groupon MessageBus

## Stakeholders

| Role | Description |
|------|-------------|
| Engineering owner | Team: engage — owner: glinganaidu |
| Engineering contact | 3pip-custom-integrations-eng@groupon.com |
| On-call | s-partner-orchestration-gateway@groupon.pagerduty.com |
| Slack channel | #gpay-app-integration |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | `pom.xml` `project.build.targetJdk` |
| Framework | Dropwizard / JTier | 5.14.0 | `pom.xml` parent `jtier-service-pom` |
| Runtime | JVM | 17 | `src/main/docker/Dockerfile` base image `prod-java17-jtier:3` |
| Build tool | Maven | (mvnvm) | `mvnvm.properties`, `.mvn/maven.config` |
| Container base | JTier prod-java17-jtier | 3 | `src/main/docker/Dockerfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-service-pom` | 5.14.0 | http-framework | JTier/Dropwizard service scaffold |
| `jtier-daas-postgres` | (managed) | db-client | PostgreSQL DaaS connection pool |
| `jtier-jdbi3` | (managed) | orm | JDBI3 SQL object DAO layer |
| `jtier-migrations` | (managed) | db-client | Flyway-based schema migrations |
| `jtier-messagebus-client` | (managed) | message-client | Groupon MessageBus consumer |
| `jtier-messagebus-dropwizard` | (managed) | message-client | MBus Dropwizard integration |
| `jtier-retrofit` | (managed) | http-client | Retrofit2 HTTP client for internal services |
| `jtier-quartz-bundle` | (managed) | scheduling | Quartz job scheduler integration |
| `jjwt-api` | 0.11.2 | auth | JWT token generation for Google Wallet payloads |
| `google-auth-library-oauth2-http` | 1.3.0 | auth | Google OAuth2 service account credentials |
| `aws-java-sdk-s3` | 1.12.261 | storage | AWS S3 SDK (v1) |
| `software.amazon.awssdk:s3` | 2.7.20 | storage | AWS S3 SDK (v2) |
| `jsoup` | 1.15.4 | serialization | HTML parsing for deal content |
| `ctx-support-logging` | 0.8.2 | logging | Contextual structured logging (Steno) |
