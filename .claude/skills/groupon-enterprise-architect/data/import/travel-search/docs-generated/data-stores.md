---
service: "travel-search"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumTravelSearchDb"
    type: "mysql"
    purpose: "Primary relational store for hotel entities, pricing, availability, and service configuration"
  - id: "continuumTravelSearchRedis"
    type: "redis"
    purpose: "Hotel and deal data cache; reduces latency and external API call volume"
---

# Data Stores

## Overview

The Getaways Search Service uses two data stores: a **MySQL** database as its primary persistent store for hotel entities, pricing, and configuration, and a **Redis** cache for high-throughput reads of hotel and deal data. Redis acts as the first read layer; on cache miss the service falls back to MySQL. Kafka-ingested EAN price updates and externally fetched hotel content are written to both stores.

## Stores

### Travel Search MySQL (`continuumTravelSearchDb`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumTravelSearchDb` |
| Purpose | Primary relational store for hotel entities, availability data, pricing, and service configuration |
| Ownership | owned |
| Migrations path | > No evidence found — verify against service source repository |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `hotels` | Core hotel records — content, location, metadata | hotel_id, name, destination_id, status |
| `hotel_availability` | Availability and rate data per hotel and date range | hotel_id, check_in, check_out, rate, currency |
| `hotel_content` | Rich content attributes fetched from external content service | hotel_id, description, amenities, images |
| `service_configuration` | Service-level configuration and feature settings | key, value, environment |

> Table names are inferred from component responsibilities. Verify exact schema against Ebean entity definitions in the service source repository.

#### Access Patterns

- **Read**: `travelSearch_persistenceLayer` (Ebean) reads hotel entities and configuration on cache miss; `searchManager` reads stored configuration for search behaviour; `hotelDetailsManager` reads and writes hotel detail records
- **Write**: `travelSearch_persistenceLayer` writes hotel detail updates and price persistence triggered by `travelSearch_kafkaConsumer`; `travelSearch_backgroundJobs` writes updated entities after periodic sync operations
- **Indexes**: > No evidence found — verify against migration scripts in source repository

### Travel Search Redis (`continuumTravelSearchRedis`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `continuumTravelSearchRedis` |
| Purpose | Hotel and deal data cache — reduces latency on hotel detail reads and deal lookups |
| Ownership | owned |
| Migrations path | Not applicable (cache store) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `hotel:{hotelId}` | Cached hotel data including content, availability, and rates | hotel_id |
| `deal:{dealId}` | Cached deal data for search result enrichment | deal_id |

> Cache key patterns are inferred from component responsibilities (`travelSearch_cacheLayer`). Verify exact key schemas in source code.

#### Access Patterns

- **Read**: `travelSearch_cacheLayer` reads cached hotel and deal data on every hotel detail request; cache hit avoids calls to external content/inventory services
- **Write**: `travelSearch_cacheLayer` writes hotel data after external fetches; `travelSearch_kafkaConsumer` updates cached hotel prices on EAN price update events
- **Indexes**: Not applicable (Redis key-value store)

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumTravelSearchRedis` | Redis | Hotel and deal data cache — first read layer before MySQL fallback | > No evidence found — verify in service configuration |

## Data Flows

1. **Search request path**: `travelSearch_cacheLayer` reads Redis; on miss, falls back to `travelSearch_persistenceLayer` (MySQL) and may trigger external fetches via `travelSearch_externalClients`.
2. **EAN price update path**: `travelSearch_kafkaConsumer` receives price events from Kafka, updates Redis via `travelSearch_cacheLayer`, and persists to MySQL via `travelSearch_persistenceLayer`.
3. **Background sync path**: `travelSearch_backgroundJobs` periodically calls `travelSearch_externalClients` for inventory and content, then writes updated entities to MySQL via `travelSearch_persistenceLayer`.
4. **Hotel detail write path**: `hotelDetailsManager` fetches content and inventory from external clients, merges data, writes to both Redis (cache) and MySQL (persistence), then triggers MDS publication via `travelSearch_mbusPublisher`.
