---
service: "subscription-programs-app"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Loyalty / Subscription Programs"
platform: "Continuum"
team: "AFL/Loyalty"
status: active
tech_stack:
  language: "Java"
  language_version: "1.8"
  framework: "Dropwizard / JTier"
  framework_version: "5.14.1"
  runtime: "JVM"
  runtime_version: "1.8"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Subscription Programs App Overview

## Purpose

Subscription Programs App is the backend service that manages Groupon Select membership lifecycle — creation, modification, cancellation, and reactivation. It integrates with KillBill for billing, the Incentive Service for benefit enrollment, and Rocketman for member communications. The service serves as the authoritative source for consumer subscription state within the Continuum platform.

## Scope

### In scope

- Groupon Select membership creation, retrieval, update, and cancellation
- Subscription plan catalog exposure
- Consumer eligibility checks for Select membership
- Payment history retrieval per consumer
- V2 membership lifecycle (enhanced reactivation and status flows)
- Membership event publishing to downstream consumers via MBus
- Background jobs for membership maintenance (Quartz scheduler)
- KillBill webhook event ingestion and processing
- Incentive enrollment and benefit management for active members
- Support flows: email routing, message dispatch to consumers

### Out of scope

- Billing charge execution (delegated to KillBill)
- Email template authoring (delegated to Rocketman)
- Order fulfillment (delegated to Orders Service)
- Consumer identity and authentication (delegated to platform auth layer)
- Frontend rendering (MBNXT owns UI)

## Domain Context

- **Business domain**: Loyalty / Subscription Programs
- **Platform**: Continuum
- **Upstream consumers**: Consumer-facing APIs (MBNXT, internal tooling, support agents)
- **Downstream dependencies**: KillBill (billing), Incentive Service (benefits), Rocketman (email), Orders Service, TPIS (optional), MBus (event publishing)

## Stakeholders

| Role | Description |
|------|-------------|
| AFL/Loyalty team | Service owner — development, on-call, roadmap |
| Support agents | Use support endpoints (`/support/{consumerId}/email`) to manage member communications |
| Loyalty product managers | Define membership plans, eligibility rules, and incentive configurations |
| Billing/payments team | Coordinates KillBill integration and payment failure handling |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 1.8 | Inventory |
| Framework | Dropwizard / JTier | 5.14.1 | Inventory |
| Runtime | JVM | 1.8 | Inventory |
| Build tool | Maven | — | Inventory |
| Package manager | Maven | — | Inventory |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-messagebus-client | — | message-client | Publishes membership events to MBus topics |
| jtier-daas-mysql | — | db-client | MySQL access for `mm_programs` database |
| jtier-quartz-bundle | — | scheduling | Background membership maintenance jobs (Worker container) |
| jtier-retrofit | — | http-framework | HTTP client for internal service calls (Incentive Service, Orders Service, TPIS) |
| killbill-client-java | 1.0.6 | http-framework | KillBill billing API client |
| cache2k | 1.0.2 | db-client | In-memory caching (plan catalog, eligibility) |
| guava-retrying | 2.0.0 | http-framework | Retry logic for external service calls |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
