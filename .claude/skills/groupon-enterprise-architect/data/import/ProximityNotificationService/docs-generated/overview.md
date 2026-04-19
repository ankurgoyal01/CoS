---
service: "proximity-notification-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Mobile Notifications / Location-Based Commerce"
platform: "Continuum"
team: "Emerging Channels"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "inherited from jtier-service-pom 5.14.1"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Proximity Notification Service Overview

## Purpose

The Proximity Notification Service receives real-time geographic location updates from mobile clients, evaluates whether users are within configured Hotzone boundaries, and dispatches targeted push notifications and email messages when eligible deals are nearby. It also manages the lifecycle of Hotzone deal configurations (creation, expiry, batch generation) and supplies the mobile apps with geofence coordinates to monitor.

## Scope

### In scope

- Accepting geofence location events from iOS and Android mobile clients
- Returning geofence polygon sets to mobile clients for local monitoring
- Evaluating per-user rate limits and suppression rules before sending notifications
- Sending push notifications and email via the Rocketman push service
- Managing Hotzone deal records: CRUD, expiry deletion, and batch generation via Quartz scheduler
- Managing Hotzone category campaigns and their configuration
- Checking audience membership, voucher inventory, CLO redemption readiness, and purchased deal annotations before deciding to send
- Persisting send logs to prevent duplicate notifications
- Caching recent user location and travel state in Redis

### Out of scope

- Generating Hotzone deal data from raw catalog/inventory (handled by the `HotzoneGenerator` batch service)
- Managing the Hotzone UI (handled by the `proximity-ui` subservice)
- Delivering push notifications at the carrier/device level (handled by Rocketman service)
- User authentication and session management (delegated to API proxy / birdcage)

## Domain Context

- **Business domain**: Mobile Notifications / Location-Based Commerce
- **Platform**: Continuum (Emerging Channels team)
- **Upstream consumers**: Groupon iOS and Android mobile apps (via API proxy)
- **Downstream dependencies**: Rocketman (push delivery), Targeted Deal Message service, Coupon/Inventory service, CLO Inventory service, Voucher Inventory service, Realtime Audience Management service, Watson KV, PostgreSQL (primary store), Redis (cache)

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | Emerging Channels team (balsingh) |
| SRE contact | ec-proximity-alert@groupon.com |
| On-call | https://groupon.pagerduty.com/services/PGV083B |
| Mailing list | emerging-channels@groupon.com |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `.java-version`, `src/main/docker/Dockerfile` (prod-java11-alpine-jtier) |
| Framework | Dropwizard | (via jtier-service-pom 5.14.1) | `pom.xml` parent |
| Runtime | JVM 11 | 11 | `.java-version` |
| Build tool | Maven | (via jtier-service-pom) | `pom.xml`, `.mvn/maven.config` |
| Package manager | Maven | | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-daas-postgres` | (jtier BOM) | db-client | JTier-managed PostgreSQL connection pool via HikariCP |
| `jtier-jdbi` | (jtier BOM) | orm | JDBI-based DAO layer over PostgreSQL |
| `jtier-migrations` | (jtier BOM) | db-client | Schema migration runner for PostgreSQL |
| `jedis` | 2.9.0 | db-client | Redis client for user location/travel state cache |
| `jtier-quartz-bundle` | (jtier BOM) | scheduling | Quartz job scheduler for hotzone generation and cleanup |
| `retrofit` | (jtier BOM) | http-framework | Type-safe HTTP client for outbound service calls |
| `jtier-okhttp` | (jtier BOM) | http-framework | OkHttp HTTP client base for Retrofit adapters |
| `HotzoneGenerator` | 1.25 | scheduling | Groupon utility for generating hotzone geospatial data |
| `kirdapes` | 1.12 | http-framework | Groupon mobile common library |
| `immutables` | (jtier BOM) | serialization | Immutable value types for configuration and domain objects |
| `auto-value` | 1.6.2 | serialization | AutoValue annotation processor for value types |
| `commons-lang3` | (jtier BOM) | validation | Apache Commons Lang3 string and utility helpers |
| `mustache.java` | (jtier BOM) | serialization | Mustache template engine for notification text rendering |
| `finch` | 3.6 | metrics | Groupon A/B experimentation and metrics tracking |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
