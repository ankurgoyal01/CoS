---
service: "incentive-service"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "CRM — Incentives Platform"
platform: "Continuum"
team: "CRM / Incentives Platform"
status: active
tech_stack:
  language: "Scala"
  language_version: "2.12.18"
  framework: "Play Framework"
  framework_version: "2.8.20"
  runtime: "Java"
  runtime_version: "11"
  build_tool: "sbt 1.x"
  package_manager: "sbt"
---

# Incentive Service Overview

## Purpose

The Incentive Service is Groupon's central platform for managing promotional incentives throughout the commerce lifecycle. It validates and redeems promo codes at checkout, qualifies users for campaign audiences, and processes event-driven incentive state changes via Kafka and MBus. The service operates in five distinct deployment modes — batch, messaging, checkout, bulk, and admin — allowing independent scaling of each operational concern.

## Scope

### In scope

- Promo code validation against user, deal, and pricing context
- Promo code redemption and quota enforcement
- Audience qualification sweeps for CRM campaigns
- Bulk export of redemption and qualification datasets as CSV
- Administrative UI for campaign creation, management, and multi-step approval workflows
- Event-driven processing of order confirmations and user population updates
- Campaign state lifecycle management (pending → active → expired)
- Pub/sub coordination via Redis for distributed state

### Out of scope

- Email delivery and campaign execution (handled by `continuumMessagingService`)
- Realtime audience qualification (handled by Realtime Audience Service — stub only)
- Deal catalog content management (handled by `continuumDealCatalogService`)
- Pricing rule definition (handled by `continuumPricingService`)
- Taxonomy hierarchy management (handled by `continuumTaxonomyService`)

## Domain Context

- **Business domain**: CRM — Incentives Platform (promo codes, discounts, audience qualification)
- **Platform**: Continuum
- **Upstream consumers**: Checkout systems calling `/incentives/validate` and `/incentives/redeem`; admin users accessing the campaign management UI; batch orchestrators triggering audience qualification and bulk export
- **Downstream dependencies**: `continuumPricingService`, `continuumDealCatalogService`, `continuumTaxonomyService`, `continuumAudienceManagementService`, `continuumMarketingDealService`, `continuumMessagingService`, `continuumKafkaBroker`, `messageBus`

## Stakeholders

| Role | Description |
|------|-------------|
| CRM / Incentives Platform Team | Service owners; responsible for development, operations, and on-call |
| Campaign Managers | Admin UI users who create, configure, and approve incentive campaigns |
| Checkout Systems | Primary API consumers for promo code validation and redemption at point of sale |
| Data / Analytics Teams | Consumers of bulk export datasets for reporting and analysis |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Scala | 2.12.18 | `build.sbt` / `project/build.properties` |
| Framework | Play Framework | 2.8.20 | `build.sbt` |
| Runtime | Java (Eclipse Temurin JDK) | 11 | Dockerfile base image |
| Build tool | sbt | 1.x | `project/build.properties` |
| Package manager | sbt | — | `build.sbt` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| play-framework | 2.8.20 | http-framework | HTTP API and server-side rendering |
| akka-actors | 2.6.x | scheduling | Background job scheduling and actor-based async processing |
| play-slick | 5.x | orm | PostgreSQL ORM via Slick |
| phantom-dsl | 2.x | db-client | Cassandra DSL client |
| alpakka-kafka | 3.x | message-client | Kafka consumer/producer streams |
| redis.clients jedis | 3.x | db-client | Redis client for caching and pub/sub |
| google-cloud-bigtable | 2.x | db-client | Bigtable client for high-throughput audience reads |
| play-json | 2.9.x | serialization | JSON parsing and rendering |
| logback | 1.2.x | logging | Structured logging |
| sbt-native-packager | 1.x | build | Docker image packaging |
| scala-guice | 5.x | validation | Dependency injection |
| specs2 | 4.x | testing | Unit and integration testing |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
