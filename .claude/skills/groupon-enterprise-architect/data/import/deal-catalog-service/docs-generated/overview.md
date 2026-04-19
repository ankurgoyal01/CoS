---
service: "deal-catalog-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Deal Merchandising / Catalog"
platform: "Continuum"
team: "Deal Catalog"
status: active
tech_stack:
  language: "Java"
  language_version: "8+"
  framework: "Dropwizard (JTier)"
  framework_version: ""
  runtime: "JVM"
  runtime_version: ""
  build_tool: "Maven"
  package_manager: "Maven"
---

# Deal Catalog Service Overview

## Purpose

The Deal Catalog Service is the authoritative source of merchandising information for deals within the Continuum Platform. It stores and serves deal metadata including titles, categories, availability windows, and merchandising attributes. The service exposes REST APIs consumed by multiple upstream services and executes merchandising business rules that govern how deals are presented to consumers across Groupon's consumer-facing applications.

## Scope

### In scope
- Storing and managing deal metadata (titles, descriptions, categories, availability)
- Applying merchandising business rules to deal data
- Exposing deal catalog APIs for internal consumers (Lazlo, inventory services, booking, affiliates)
- Publishing deal lifecycle events to the Message Bus (MBus)
- Indexing deal data for the search platform
- Fetching and refreshing remote node payloads on a scheduled basis (Quartz)
- PWA work queueing and de-duplication via Redis

### Out of scope
- Deal pricing (handled by Pricing Service / `continuumPricingService`)
- Deal creation and configuration (handled by Deal Management API / `continuumDealManagementApi` and Salesforce)
- Inventory management (handled by Goods Inventory, Voucher Inventory, CLO Inventory, and Coupons Inventory services)
- Marketing placement and campaigns (handled by Marketing Deal Service / `continuumMarketingDealService`)
- Consumer-facing search ranking and personalization (handled by Relevance API / `continuumRelevanceApi`)
- Order processing and payments (handled by Orders and Payments services)

## Domain Context

- **Business domain**: Deal Merchandising / Catalog
- **Platform**: Continuum (Groupon's core commerce engine)
- **Upstream consumers**: API Lazlo (`continuumApiLazloService`), API Lazlo SOX (`continuumApiLazloSoxService`), CLO Inventory (`continuumCloInventoryService`), Voucher Inventory API (`continuumVoucherInventoryApi`), Goods Inventory (`continuumGoodsInventoryService`), Coupons Inventory (`continuumCouponsInventoryService`), Online Booking API (`continuumOnlineBookingApi`), Deal Alerts Workflows (`continuumDealAlertsWorkflows`), Coffee-to-Go Workflows (`coffeeWorkflows`), S2S Service (`continuumS2sService`), Travel Affiliates API (`continuumTravelAffiliatesApi`), Travel Affiliates Cron (`continuumTravelAffiliatesCron`), Deal Management API (`continuumDealManagementApi`)
- **Downstream dependencies**: Coupons Inventory Service (`continuumCouponsInventoryService`), Message Bus (`messageBus`), Marketing Deal Service (`continuumMarketingDealService`), Deal Catalog DB (`continuumDealCatalogDb`), Deal Catalog Redis (`continuumDealCatalogRedis`)

## Stakeholders

| Role | Description |
|------|-------------|
| Deal Catalog team | Owns and operates the service, maintains APIs and merchandising rules |
| Merchant operations | Depend on accurate deal metadata for catalog quality |
| Consumer product teams | Consume deal catalog data for browsing, search, and personalization |
| Inventory teams | Call Deal Catalog to resolve deal attributes for inventory operations |
| Marketing teams | Receive deal lifecycle events to coordinate campaign placement |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 8+ | `architecture/models/components/continuum-deal-catalog-service-components.dsl` |
| Framework | Dropwizard (JTier) | - | Container definition: "Java, Dropwizard (JTier)" |
| Runtime | JVM | - | Inferred from Java/Dropwizard |
| Build tool | Maven | - | Inferred from JTier convention |
| Package manager | Maven | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Dropwizard | - | http-framework | HTTP server and REST endpoint framework |
| JPA (Hibernate) | - | orm | Object-relational mapping for deal entity persistence |
| Quartz | - | scheduling | Scheduled job execution for Node Payload Fetcher |
| MBus Client | - | message-client | Publishing deal lifecycle events to Groupon's Message Bus |
| JDBC (MySQL) | - | db-client | Database connectivity to Deal Catalog DB (DaaS) |
| Jedis/Lettuce | - | db-client | Redis client for PWA queueing and coordination state |

> Only the most important libraries are listed here -- the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
