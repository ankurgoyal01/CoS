---
service: "grouponlive-inventory-service-jtier"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Live ticketing / inventory management"
platform: "Continuum"
team: "Groupon Live"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard / JTier"
  framework_version: "5.14.1"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Groupon Live Inventory Service JTier Overview

## Purpose

The Groupon Live Inventory Service JTier (glive-inventory-jtier) is the central Java microservice for Groupon Live's ticketing operations. It manages the full lifecycle of live event inventory — from browsing available events and holding seats via reservations to executing purchases through external ticketing partners. The service acts as an integration hub between Groupon's internal commerce systems and third-party ticketing vendors (Provenue, Telecharge, AXS, Ticketmaster), providing a normalized REST API consumed by upstream Groupon services.

## Scope

### In scope
- Serving live event inventory and availability data to consumers via REST endpoints
- Creating and tracking seat reservations against third-party ticketing partners
- Executing and recording ticket purchases through partner APIs
- Managing venue credentials (usernames, passwords, API keys) for each ticketing partner
- Exposing product, event, and inventory-unit data from the owned MySQL database
- Running background Quartz jobs for async reservation and purchase processing
- Synchronizing Provenue vendor API versions via a scheduled sync job
- Reporting payment breakdowns by merchant

### Out of scope
- Groupon order payment processing (handled by the Groupon commerce platform)
- End-user authentication (managed upstream)
- Marketing or deal creation for Groupon Live products
- Email or notification delivery to customers after purchase

## Domain Context

- **Business domain**: Live ticketing / inventory management
- **Platform**: Continuum (Groupon Live)
- **Upstream consumers**: Internal Groupon services including glive-inventory-rails (the Rails-based predecessor); Groupon checkout and order services that call the reservation and purchase endpoints
- **Downstream dependencies**: Provenue API (seat reservations and purchases), Telecharge API (Broadway ticketing), AXS API (venue ticketing), Ticketmaster API (event ticketing), glive-inventory-rails service (customer and event update callbacks), MySQL database, Redis cache

## Stakeholders

| Role | Description |
|------|-------------|
| Groupon Live Engineering | Service owners responsible for development and operations |
| Account Managers | Manage merchant and vendor relationships tracked in the service |
| Groupon Live Operations | Monitor reservation and purchase success rates |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` (`project.build.targetJdk`) |
| Framework | JTier (Dropwizard-based) | 5.14.1 | `pom.xml` (`jtier-service-pom` parent) |
| Runtime | JVM | 11 | `src/main/docker/Dockerfile` (`prod-java11-jtier`) |
| Build tool | Maven | mvnvm managed | `mvnvm.properties`, `pom.xml` |
| Package manager | Maven | | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-service-pom` | 5.14.1 | http-framework | Parent POM providing JTier/Dropwizard base framework |
| `jtier-ext-bom` | 5.14.1.0 | http-framework | JTier extension bill-of-materials |
| `retrofit2` (via `jtier-retrofit`) | managed | http-client | Type-safe HTTP client for all partner API calls |
| `hk2-di-core` | managed | dependency injection | HK2 dependency injection container |
| `jtier-jdbi3` / `hk2-di-jdbi3` | managed | orm | JDBI3 SQL object DAO layer for MySQL access |
| `mysql-connector-java` | 5.1.49 | db-client | JDBC driver for MySQL connectivity |
| `jtier-jedis-bundle` | managed | db-client | Jedis Redis client bundle for token caching |
| `jtier-quartz-bundle` / `hk2-di-quartz` | managed | scheduling | Quartz job scheduler for async reservation and purchase jobs |
| `flyway-maven-plugin` | 5.2.4 | db-client | Database schema migration management |
| `libphonenumber` | 8.12.15 | validation | Phone number parsing and validation for patron contacts |
| `arpnetworking/steno` | managed | logging | Structured (Steno) logging framework |
| `jackson` (via JTier) | managed | serialization | JSON serialization/deserialization |
| `wiremock-standalone` | managed | testing | HTTP mock server for integration tests |
| `rest-assured` | managed | testing | REST API integration test assertions |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
