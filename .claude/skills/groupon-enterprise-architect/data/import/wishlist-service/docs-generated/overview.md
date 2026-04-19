---
service: "wishlist-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "User Generated Content"
platform: "Continuum"
team: "UGC"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard (JTier)"
  framework_version: "jtier-service-pom 5.14.1"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Wishlist Service Overview

## Purpose

The Wishlist Service (also known as List Management Service, LMS, or Mobile List Service) backs wishlist functionality across Groupon's mobile and web platforms. It manages user wishlist lists and items — supporting creation, retrieval, update, and deletion — and runs background jobs to process item expiry, send email and push notifications, and handle price-drop detection. The service is designed to sustain up to 20k RPS at a 99th-percentile latency target of under 40ms for real-time wishlist decoration of deal and search pages.

## Scope

### In scope

- Creating and managing named user wishlist lists (public/private, locale-specific)
- Adding wishlist items by deal ID and option ID, associated to a list by name or list ID
- Querying wishlists by user (`consumerId`), list ID, list name, deal ID (`containsDeal`), or option ID (`containsOption`)
- Deleting one or more items from a list
- Background processing: user bucket enqueue (`UserEnqueueJob`) and dequeue (`UserDequeueJob`) pipelines via Quartz scheduler
- Item expiry tracking and email notification dispatch via MBus (`WishlistMailman` destination)
- Push notification dispatch for expiring items via Rocketman Commercial
- Price-drop detection via MBus `DynamicPricing` topic and caching in Redis (`priceDrops:<dealId>` key)
- Consuming MBus `ItemPurchases` (order transaction) events to mark wishlist items as purchased or gifted
- Channel and expiry metadata refresh for wishlist items via background tasks

### Out of scope

- Deal catalog content management (handled by `continuumDealCatalogService`)
- Order placement and payment processing (handled by `continuumOrdersService`)
- Push token registration (handled by the push-token service)
- Email template rendering and dispatch (handled by Mailman / Localize)
- Inventory management (handled by `continuumVoucherInventoryService`)

## Domain Context

- **Business domain**: User Generated Content
- **Platform**: Continuum
- **Upstream consumers**: GAPI (via wishlist iTier front-end app), deal page, layout service, iOS app, Android app, Marketing Service batch jobs
- **Downstream dependencies**: Deal Catalog Service, Orders Service, Pricing Service, Taxonomy Service, Voucher Inventory Service, Mailman (email), Localize (templates), Push Token Service, Rocketman Commercial (push), MBus, PostgreSQL (DaaS), Redis (RaaS)

## Stakeholders

| Role | Description |
|------|-------------|
| Engineering team | UGC team — ugc-dev@groupon.com |
| Service owner | schoudhary |
| SRE alerts | ugc-alerts@groupon.com |
| On-call | PagerDuty service P00HKZX; OpsGenie service 3a95281a-ad9b-48ae-8c2e-77539b1f0c91 |
| Slack channel | ugc |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `src/main/docker/Dockerfile` (FROM jtier/prod-java11-jtier:3) |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.1 | `pom.xml` parent |
| Runtime | JVM | 11 | `src/main/docker/Dockerfile` |
| Build tool | Maven | — | `pom.xml`, `.mvn/maven.config` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-service-pom` | 5.14.1 | http-framework | JTier Dropwizard-based service parent POM providing framework defaults |
| `jtier-daas-postgres` | (managed) | db-client | DaaS PostgreSQL connection and connection pooling |
| `jtier-jdbi3` | (managed) | orm | JDBI3 data access layer for PostgreSQL DAO operations |
| `jtier-migrations` | (managed) | db-client | Database schema migration support |
| `dropwizard-redis` | (managed) | db-client | Redis (Jedis) integration bundle for Dropwizard |
| `jtier-messagebus-client` | 0.4.6 | message-client | MBus consumer and publisher integration |
| `jtier-quartz-bundle` | (managed) | scheduling | Quartz scheduler bundle for background job orchestration |
| `jtier-retrofit` | (managed) | http-framework | Retrofit HTTP client for outbound service calls |
| `push-token-client` | 0.0.34 | http-framework | Client for push token / global-subscription lookup |
| `goodyear-client` | 1.4 | http-framework | Client for Goodyear push notification service (Rocketman Commercial) |
| `kirdapes` | 1.12 | http-framework | Internal mobile push notifications client |
| `lombok` | 1.18.6 | serialization | Boilerplate reduction — getters, builders, immutable objects |
| `jmustache` | 1.9 | serialization | Mustache template rendering for notification payloads |
| `hadoop-common` / `hadoop-hdfs` | 3.3.0 | db-client | HDFS bcookie recorder used in push notification rollout tracking |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
