---
service: "clo-inventory-service"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Card Linked Offers (CLO)"
platform: "Continuum"
team: "CLO Engineering"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "JTIER/IS-Core"
  runtime: "Java"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# CLO Inventory Service Overview

## Purpose

CLO Inventory Service is the inventory lifecycle management backend for Groupon's Card-Linked Offers platform. It manages the full lifecycle of CLO inventory products -- from creation and pricing through unit allocation, reservation, and redemption -- while also handling merchant feature configuration, user reward tracking, and consent/card enrollment APIs. The service acts as the central inventory authority within the CLO domain, bridging deal catalog data, merchant metadata, and CLO core offer management into a unified inventory model.

## Scope

### In scope

- Creating and updating CLO inventory products with pricing and contract terms
- Managing inventory units, unit allocations, and unit redemptions
- Processing reservations and purchase controls for CLO inventory
- Tracking user rewards and user-level CLO inventory interactions
- Managing merchant CLO features and merchant inventory configuration
- Providing consent management APIs (consent records, consent history, billing records)
- Handling card enrollment flows and communicating enrollment state to CLO core
- Caching product data via Redis and in-memory caches for read performance
- Integrating with external services for deal metadata, merchant details, and place information

### Out of scope

- CLO offer lifecycle management and claim processing (handled by `continuumCloCoreService`)
- Card interaction tracking and network-level card data (handled by `continuumCloCardInteractionService`)
- Deal catalog and product catalog management (handled by `continuumDealCatalogService`)
- Merchant master data and merchant onboarding (handled by `continuumM3MerchantService`)
- Place/location master data (handled by `continuumM3PlacesService`)
- Payment processing and settlement (handled by payment services)

## Domain Context

- **Business domain**: Card Linked Offers (CLO)
- **Platform**: Continuum
- **Upstream consumers**: Internal CLO platform services, consumer-facing applications, and merchant tooling that query inventory products, units, reservations, user rewards, and consent records via REST APIs
- **Downstream dependencies**: `continuumCloInventoryDb` (PostgreSQL primary store), `continuumCloInventoryRedisCache` (Redis cache), `continuumCloCoreService` (CLO offer and claim management), `continuumCloCardInteractionService` (card network identifiers), `continuumDealCatalogService` (deal metadata), `continuumM3MerchantService` (merchant metadata), `continuumM3PlacesService` (place/location details)

## Stakeholders

| Role | Description |
|------|-------------|
| CLO Engineering | Service owner team; responsible for development, deployment, and operations |
| CLO Product | Defines CLO inventory product requirements and business rules |
| Merchant Operations | Configures merchant CLO features and manages merchant inventory settings |
| Consumer Experience | Consumes inventory and consent APIs to power CLO experiences on consumer applications |
| Compliance / Legal | Governs consent management policies and card enrollment data handling |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | Architecture DSL, JTIER conventions |
| Framework | Dropwizard (JTIER/IS-Core) | — | Architecture DSL: `Java 11, Dropwizard (JTIER/IS-Core), Jersey, JDBI` |
| Runtime | Java | 11 | Architecture DSL |
| Build tool | Maven | — | JTIER conventions |
| Package manager | Maven | | JTIER conventions |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jersey` | — | http-framework | JAX-RS resource routing and REST endpoint definition |
| `jdbi` | — | orm | Lightweight SQL mapping for PostgreSQL data access |
| `swagger` | — | validation | API documentation and contract generation |
| `retrofit` | — | http-framework | Type-safe HTTP client for external service integrations |
| `redis` (JTIER Cache) | — | db-client | Redis client for caching product and inventory data |
| `dropwizard-metrics` | — | metrics | Application metrics collection and reporting |
| `metrics-sma` | — | metrics | Simple Moving Average metrics for health and performance |

> Only the most important libraries are listed here -- the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
