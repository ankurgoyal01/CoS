---
service: "travel-search"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Travel / Getaways"
platform: "Continuum"
team: "Getaways Engineering"
status: active
tech_stack:
  language: "Java"
  language_version: ""
  framework: "JAX-RS"
  framework_version: ""
  runtime: "Jetty WAR"
  runtime_version: ""
  build_tool: "Maven"
  package_manager: "Maven"
---

# Getaways Search Service Overview

## Purpose

The Getaways Search Service (`travel-search`) is the central travel search backend for Groupon's Getaways vertical. It handles hotel search, availability resolution, hotel detail aggregation, relevance-ranked deal recommendations, and outbound MDS (Merchant Data Service) hotel updates. The service aggregates data from multiple upstream providers — including Expedia EAN, internal inventory, geo, and content services — and presents a unified search and hotel-detail API to Getaways client applications.

## Scope

### In scope

- Hotel search queries: keyword, destination, date-range, and filter-based
- Hotel detail pages: content, availability, and pricing aggregation
- Deal and recommendation retrieval for the Getaways vertical
- Availability and rate fetching via the Expedia EAN API
- OTA (Online Travel Agency) inventory feed uploads to Google Hotels
- Kafka-driven EAN price update ingestion and persistence
- MBus-driven hotel update event publication (MDS updates)
- Currency conversion for multi-currency pricing
- Local caching of hotel data via Redis and fallback to MySQL

### Out of scope

- Booking and checkout flows (handled by order/commerce services)
- Payment processing
- User account management
- Non-travel deal search (handled by `continuumDealCatalogService` and related services)
- Frontend rendering (handled by the MBNXT PWA)

## Domain Context

- **Business domain**: Travel / Getaways
- **Platform**: Continuum
- **Upstream consumers**: Getaways client applications (`externalGetawaysClients_2f4a`), internal services routing hotel search requests
- **Downstream dependencies**: Content service, Geo service, Inventory service, Expedia EAN API, Google Hotels, RAPI (card deals), Backpack (getaways systems search), Deal Catalog (`continuumDealCatalogService`), Forex (`continuumForexService`), Relevance service, Gap-filtering service, Message Bus (MBus), Kafka cluster

## Stakeholders

| Role | Description |
|------|-------------|
| Getaways Engineering | Owns and maintains the service |
| Getaways Product | Defines search ranking, availability, and recommendation requirements |
| Platform / Architecture | Governs integration patterns and federation model |
| OTA Partners | Consume inventory feeds (Google Hotels) and provide rate/availability data (Expedia EAN) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | — | `architecture/models/components/travel-search-service.dsl` |
| Framework | JAX-RS | — | `architecture/models/components/travel-search-service.dsl` |
| Runtime | Jetty WAR | — | `architecture/models/components/travel-search-service.dsl` |
| Build tool | Maven | — | Standard Java WAR packaging |
| ORM / DB client | Ebean | — | `architecture/models/components/travel-search-service.dsl` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| JAX-RS | — | http-framework | REST resource definitions and request/response marshalling |
| Ebean | — | orm | MySQL entity persistence and query execution |
| Redis client | — | db-client | Hotel and deal data caching via `continuumTravelSearchRedis` |
| Kafka Streams | — | message-client | EAN price update consumption |
| JMS | — | message-client | MDS hotel update publication via MBus |
| HTTP clients | — | http-client | Outbound calls to content, geo, inventory, EAN, and forex services |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
