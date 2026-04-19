---
service: "getaways-payment-reconciliation"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Getaways / Travel Finance"
platform: "Continuum"
team: "travel-fork-sox-repo"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "JTier jtier-service-pom 5.14.1"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Getaways Payment Reconciliation Overview

## Purpose

Getaways Payment Reconciliation reconciles invoices received from EAN (Expedia Affiliate Network) against Groupon Getaways Market Rate product reservations. The service automates invoice ingestion from Gmail, loads invoice line items into MySQL, matches them against reservation data sourced from the Maris inventory service, and creates vendor invoices in the Accounting Service. It also provides a web UI and REST API for finance operations staff to review, validate, and pay invoices.

## Scope

### In scope

- Ingesting EAN invoice CSV/Excel attachments from a Gmail inbox via IMAP/OAuth2
- Bulk-loading invoice line items into the `travel_ean_invoice` MySQL table
- Consuming inventory-units-updated MBus events and persisting reservation records
- Fetching inventory unit details from the Maris service via HTTP
- Validating and reconciling invoice totals against reservation data
- Creating vendor invoices in the Accounting Service via HTTP
- Sending reconciliation status notifications via SMTP
- Exposing a REST API and web UI for invoice listing and payment submission
- Tracking invoice import status in the `invoice_importer_status` table

### Out of scope

- Customer-facing checkout or payment flows (handled by other Getaways services)
- EAN API integration for live inventory pricing (Maris owns inventory retrieval)
- Accounting ledger management (owned by the Accounting Service)
- Refund or dispute resolution workflows

## Domain Context

- **Business domain**: Getaways / Travel Finance
- **Platform**: Continuum
- **Upstream consumers**: Finance operations staff (web UI), internal tooling calling the REST API
- **Downstream dependencies**: Maris inventory service (HTTP), Accounting Service (HTTP), Gmail (IMAP/SMTP via OAuth2), Groupon SMTP server (notifications), MBus inventory updates topic (JMS consumer)

## Stakeholders

| Role | Description |
|------|-------------|
| Service owner | Getaways Engineering — getaways-eng@groupon.com |
| Operations / On-call | PagerDuty: getaways-payment-reconciliation@groupon.pagerduty.com |
| Finance users | Internal users reconciling EAN invoices via the web UI |
| SOX compliance | Hosted in `sox-inscope` GitHub org; subject to SOX audit controls |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` — `project.build.targetJdk=11` |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.1 | `pom.xml` parent |
| Runtime | JVM | 11 | `src/main/docker/Dockerfile` — `prod-java11-jtier:3` |
| Build tool | Maven | 3.x (mvnvm.properties) | `.mvn/maven.config`, `mvnvm.properties` |
| Package manager | Maven | | `pom.xml` |
| Scripting | Python | 3.x | `src/main/docker/Dockerfile` — `python3-venv` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-jdbi` | managed by parent | db-client | JDBI-based DAO layer for MySQL |
| `jtier-daas-mysql` | managed by parent | db-client | JTier DaaS MySQL connection management |
| `jtier-migrations` | managed by parent | db-client | Schema migration support |
| `jtier-messagebus-client` | managed by parent | message-client | JMS/MBus consumer for inventory events |
| `dropwizard-views-freemarker` | managed by parent | ui-framework | Server-side HTML view rendering |
| `dropwizard-assets` | managed by parent | ui-framework | Static asset serving for web UI |
| `resteasy-jaxrs` | 3.0.3.Final | http-framework | JAX-RS REST endpoint provider |
| `resteasy-jackson-provider` | 3.0.3.Final | serialization | JSON serialization for REST responses |
| `org.projectlombok:lombok` | 1.18.22 | validation | Boilerplate reduction (getters, constructors) |
| `javalite-common` | 1.4.9 | http-framework | Lightweight HTTP client (javalite `Http`) |
| `javax.mail` | 1.4.7 | message-client | JavaMail API (referenced, IMAP/SMTP done via Python) |
| `com.google.guava` | managed by parent | validation | Collections utilities (Iterables, ImmutableMap) |
| `mockito-core` / `mockito-inline` | 3.12.4 | testing | Unit and inline mocking |
| `mysqlclient` (Python) | 2.1.0 | db-client | Python MySQL bulk-load for invoice import script |
| `openpyxl` (Python) | 3.1.5 | serialization | Excel invoice file parsing |
