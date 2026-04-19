---
service: "bhuvan"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Geospatial / Place Discovery"
platform: "Continuum (geo-fabric)"
team: "Geo Services"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard / Jersey"
  framework_version: "JTier jtier-service-pom 5.14.0"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Bhuvan Overview

## Purpose

Bhuvan is Groupon's place discovery service for geospatial entities. It exposes search and read REST APIs for geo entities including divisions, localities, neighborhoods, postal codes, timezones, and points of interest (POIs). It also provides geocoding, reverse geocoding, autocomplete, address normalization, and taxonomy management capabilities used by internal Groupon services and external clients.

## Scope

### In scope
- Serving read/search APIs for divisions, localities, neighborhoods, postal codes, timezones, and places/POIs.
- Geocoding and reverse geocoding coordinates, IP addresses, and place names.
- Location-based autocomplete and address normalization via external provider APIs.
- Taxonomy management: CRUD operations for sources, place types, relationship types, indexes, and places.
- Geo spatial index management: building and rebuilding Redis-backed spatial indices.
- Relationship building between geo entities based on geometry overlap.
- IP geolocation (IP address to coordinates) via MaxMind GeoIP2 and the Bhoomi geocoding service.
- A/B experiment support for autocomplete and geo-related behavior via Optimize/Finch.

### Out of scope
- Deal or merchant geo-targeting (handled by commerce services).
- User address storage or user profile management.
- External-facing consumer location services (Bhuvan is an internal service consumed by other Groupon services).

## Domain Context

- **Business domain**: Geospatial / Place Discovery
- **Platform**: Continuum (geo-fabric team)
- **Upstream consumers**: Internal Groupon services requiring geo entity resolution, location detection, or autocomplete (e.g., deal services, frontend APIs); tracked in the central architecture model.
- **Downstream dependencies**: Bhoomi geocoding service, Google Maps / MapTiler / Avalara APIs, Optimize/Finch experimentation platform, Postgres/PostGIS DB, Redis Memorystore, ElasticSearch, MaxMind GeoIP2 database.

## Stakeholders

| Role | Description |
|------|-------------|
| Geo Services team | Primary owner and maintainer (geo-team@groupon.com, team owner: harekumar) |
| SRE / On-call | PagerDuty: geo-bhuvan@groupon.pagerduty.com, Slack: #geo-services |
| Internal API consumers | Services calling geo entity and geocoding endpoints |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` `project.build.targetJdk=11` |
| Framework | Dropwizard / Jersey (JTier) | jtier-service-pom 5.14.0 | `pom.xml` parent |
| Runtime | JVM | 11 | `.java-version`, `.sdkmanrc` |
| Build tool | Maven | - | `pom.xml` |
| Package manager | Maven | - | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `geolib-ipgeocode` | 0.1.36 | geo-client | IP geolocation support |
| `geolib-google` | 0.1.36 | geo-client | Google Maps geocoding and place APIs |
| `geolib-avs` | 0.1.36 | geo-client | Avalara address validation service client |
| `geolib-autocomplete` | 0.1.36 | geo-client | Autocomplete integration |
| `geolib-coordinate` | 0.1.36 | geo-client | Coordinate utilities |
| `geolib-placeid` | 0.1.36 | geo-client | Place ID resolution |
| `geolib-tz` | 0.1.36 | geo-client | Timezone resolution |
| `finch` (Optimize) | 4.0.33 | experimentation | A/B experimentation platform (Optimize/Expy) |
| `lettuce-core` | 6.3.2.RELEASE | db-client | Redis async client for caching and spatial index |
| `jtier-daas-postgres` | (managed) | db-client | JTier-managed Postgres connection pool |
| `jtier-jdbi3` | (managed) | orm | JDBI3 DAO layer for Postgres access |
| `elasticsearch-rest-client` | 8.12.1 | db-client | ElasticSearch REST client for autocomplete/search |
| `jts` / `jts-io` | 1.13 / 1.14.0 | geospatial | JTS geometry library for spatial computations |
| `geojson-jackson` | 1.5 | serialization | GeoJSON serialization/deserialization |
| `kryo` / `kryo-serializers` | 5.5.0 / 0.45 | serialization | Binary serialization for Redis cache entries |
| `jtier-retrofit` | (managed) | http-framework | JTier HTTP client (Retrofit) for upstream services |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for the full list.
