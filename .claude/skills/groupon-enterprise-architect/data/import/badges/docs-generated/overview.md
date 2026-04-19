---
service: "badges-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Deal Merchandising / Badges"
platform: "Continuum"
team: "deal-catalog-dev@groupon.com"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard (JTier)"
  framework_version: "jtier-service-pom 5.14.0"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Badges Service Overview

## Purpose

The Badges Service determines which promotional badges (e.g., Top Seller, Trending, Selling Fast, Recently Viewed) should appear on deals across Groupon web, email, and mobile channels. It collects deal statistics and contextual signals, ranks badge candidates, applies taxonomy and localization decorators, and returns structured badge payloads to consumers. It also produces urgency messages — countdown timers and inventory signals — for individual deal pages.

## Scope

### In scope
- Evaluating and returning badge assignments for lists of deals (`BadgesResources`)
- Computing and returning urgency messages for individual deals (`MessageController`)
- Caching badge state in Redis (per-item and per-user-item badges)
- Scheduled refresh of merchandising-tagged deal sets from the Deal Catalog (`MerchandisingBadgeJob`)
- Scheduled refresh of localized string data from the Localization service (`LocalizationJob`)
- Serving badge lists by type, channel, country, and division

### Out of scope
- Computing raw deal statistics (owned by Janus)
- Storing deal catalog data (owned by Deal Catalog Service / DCS)
- User authentication and session management
- Taxonomy management (owned by the Taxonomy service)
- Trending/Top-Seller score computation (owned by the Badges Trending Calculator Spark job — a separate sub-service)

## Domain Context

- **Business domain**: Deal Merchandising / Badges
- **Platform**: Continuum (deal-platform)
- **Upstream consumers**: RAPI (web, mobile, email rendering pipelines)
- **Downstream dependencies**: Janus (deal stats), Deal Catalog Service (DCS), Localization API, Taxonomy API v2, Watson KV (recently viewed), Redis (STaaS)

## Stakeholders

| Role | Description |
|------|-------------|
| Service owner | cvemuri (deal-platform team) |
| Engineering team | amakumar, prart, gkk, pshahi, sudpandey |
| Team email | deal-catalog-dev@groupon.com |
| On-call / PagerDuty | badges-service@groupon.pagerduty.com (PDONLHN) |
| Slack channel | #deal-platform (CFPDDNHNW) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` `project.build.targetJdk` |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.0 | `pom.xml` parent POM |
| Runtime | JVM (OpenJDK 11) | 11 | `src/main/docker/Dockerfile` base image `prod-java11-jtier:3` |
| Build tool | Maven | — | `pom.xml`, `mvnvm.properties` |
| Scheduler | Quartz (jtier-quartz-bundle) | JTier managed | `pom.xml`, `BadgesConfiguration.java` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-quartz-bundle` | JTier managed | scheduling | Background job scheduling (LocalizationJob, MerchandisingBadgeJob) |
| `jtier-okhttp` | JTier managed | http-framework | Outbound HTTP client for internal service calls |
| `lettuce-core` | 6.1.3.RELEASE | db-client | Async Redis cluster client (badge cache reads/writes) |
| `jedis` | 2.6.0 | db-client | Synchronous Redis client (fallback/legacy usage) |
| `async-http-client` | 2.11.0 | http-framework | Async HTTP calls to Janus deal-stats endpoints |
| `fluent-hc` / `httpclient` | 4.5.13 | http-framework | Synchronous HTTP calls to Watson KV (recently viewed) |
| `gson` | 2.8.6 | serialization | JSON deserialization for recently-viewed RV tuples |
| `lombok` | 1.18.20 | validation | Boilerplate reduction (builders, getters, setters) |
| `commons-collections4` | 4.4 | validation | Collection utilities for badge ranking logic |
| `commons-validator` | 1.7 | validation | Input validation utilities |
| `guice` | 4.2.3 | http-framework | Dependency injection |
| `finch` | 3.2 (groupon-optimize) | state-management | A/B experimentation / feature flag evaluation |
| `spock-core` | 2.0-M2-groovy-3.0 | testing | BDD-style unit and integration tests |
| `powermock-api-mockito2` | 2.0.0-beta.5 | testing | Mocking for unit tests |
