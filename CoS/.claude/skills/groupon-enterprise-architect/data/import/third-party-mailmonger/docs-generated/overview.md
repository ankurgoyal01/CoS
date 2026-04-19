---
service: "third-party-mailmonger"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Third-Party Integration / Partner Email"
platform: "Continuum"
team: "Mailmonger"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard / JTier"
  framework_version: "5.14.0"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Third Party Mailmonger Overview

## Purpose

Third Party Mailmonger (also known as 3PM or Mailmonger) is an intermediary email relay service that intercepts all email communications between Groupon consumers and third-party partners. It masks the true email addresses of both parties, applies content and rate-limit filters, logs every email, and relays approved messages through SparkPost or a direct MTA. The service exists to prevent unauthorized data exchange and protect user privacy in partner-facilitated transactions.

## Scope

### In scope

- Generating and storing masked email addresses unique to each consumer/partner pair
- Receiving inbound emails from SparkPost relay webhooks
- Applying a configurable filter pipeline (spam, URL whitelist, daily rate limit, Base64, partner authorization)
- Transforming email headers and addresses before relay
- Sending filtered emails through SparkPost or MTA
- Logging all email content and tracking delivery status (Delivered, Pending, Bounced, Failed, NonRetriable, SparkpostFailure, FilterFailure, MtaFailure)
- Providing customer-support read endpoints for email inspection
- Retrying failed email deliveries via Quartz scheduler and MessageBus
- Registering and managing partner email domains

### Out of scope

- Raw SMTP reception (handled by SparkPost relay)
- User authentication and identity management (handled by users-service)
- Email template rendering
- Marketing or transactional promotional emails (handled by other Groupon services)

## Domain Context

- **Business domain**: Third-Party Integration / Partner Email
- **Platform**: Continuum
- **Upstream consumers**: TPIS (Third-Party Inventory Service / Spaceman) calls `/v1/masked/consumer/{consumerId}/{partnerId}` during deal reservation; SparkPost relay webhooks call `/mailmonger/v1/sparkpost-callback` for every inbound email; partner systems send email via SMTP to SparkPost
- **Downstream dependencies**: SparkPost (email relay and sending), MTA (SMTP delivery fallback), users-service (user/partner metadata lookup), PostgreSQL via DaaS (persistent storage), MessageBus/ActiveMQ Artemis (async email processing queue)

## Stakeholders

| Role | Description |
|------|-------------|
| Team Owner | Mailmonger team (khsingh, owner) — 3PIP-MailMonger@groupon.com |
| On-Call / Alerts | PagerDuty service mailmonger-alert@groupon.pagerduty.com |
| Slack Channel | #mailmonger-bangalore (CF8A80ABC) |
| Customer Support | Uses `/v1/emails` endpoints to inspect email history for consumers |
| TPIS / Spaceman | Primary API caller — fetches masked emails during reservation |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `.java-version`, Dockerfile (`prod-java11-jtier`) |
| Framework | Dropwizard / JTier | 5.14.0 (parent POM) | `pom.xml` — `jtier-service-pom:5.14.0` |
| Runtime | JVM 11 (Eclipse Temurin) | 11 | `src/main/docker/Dockerfile` |
| Build tool | Maven | (mvnvm.properties) | `pom.xml`, `.mvn/maven.config` |
| Package manager | Maven | | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-daas-postgres | (BOM managed) | db-client | PostgreSQL connection pool and JDBC via DaaS |
| jtier-jdbi3 | (BOM managed) | orm | JDBI3 data access layer for all DAOs |
| jtier-messagebus-client | (BOM managed) | message-client | MessageBus consumer (ActiveMQ Artemis) |
| jtier-messagebus-dropwizard | (BOM managed) | message-client | Dropwizard integration for MessageBus |
| jtier-retrofit | (BOM managed) | http-framework | Retrofit HTTP client for users-service calls |
| jtier-quartz-bundle | (BOM managed) | scheduling | Quartz scheduler integration for email retry jobs |
| jtier-quartz-postgres-migrations | (BOM managed) | scheduling | Quartz job state persistence in PostgreSQL |
| sparkpost-lib | 0.21 | http-framework | SparkPost API SDK for sending emails |
| jsoup | 1.13.1 | validation | HTML parsing and URL extraction for whitelist filter |
| autolink | 0.8.0 | validation | URL detection in plain-text email bodies |
| gson | 2.8.6 | serialization | JSON serialization (SparkPost payloads) |
| jakarta.mail-api | 2.1.2 | message-client | SMTP client (MTA delivery via Jakarta Mail) |
| jakarta.activation-api | 2.1.2 | message-client | MIME message activation for MTA client |
| immutables | (BOM managed) | serialization | Immutable value objects (config, message payloads) |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for the full dependency list.
