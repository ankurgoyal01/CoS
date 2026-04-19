---
service: "channel-manager-integrator-travelclick"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Travel / Hotel Channel Management"
platform: "Continuum (Getaways)"
team: "Getaways Engineering"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "JTier jtier-service-pom 5.14.1"
  runtime: "JVM"
  runtime_version: "Java 11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Getaways Channel Manager Integrator for TravelClick Overview

## Purpose

The channel-manager-integrator-travelclick service bridges Groupon's Getaways platform and the TravelClick channel manager. It consumes hotel reservation and cancellation messages delivered via MBus, translates them into OTA-standard XML requests, and forwards them to TravelClick. It also receives availability, inventory, and rate (ARI) push notifications from TravelClick and exposes REST endpoints to ingest and forward those updates.

## Scope

### In scope

- Consuming reservation and cancellation messages from MBus topics (including DLQ)
- Translating Groupon reservation payloads into OTA XML and sending them to TravelClick
- Receiving and validating TravelClick ARI push messages (availability, inventory, rate) via REST endpoints
- Publishing ARI-related events to Kafka
- Persisting reservation request/response records and ARI data to MySQL
- Fetching hotel product and inventory hierarchy from the Getaways Inventory service

### Out of scope

- End-user booking flows (handled by upstream Getaways commerce services)
- Channel manager logic for non-TravelClick partners (separate integrator services)
- Inventory management and pricing decisions (owned by Getaways Inventory service)
- Direct customer-facing APIs

## Domain Context

- **Business domain**: Travel / Hotel Channel Management
- **Platform**: Continuum (Getaways)
- **Upstream consumers**: TravelClick channel manager (pushes ARI data to REST endpoints); MBus (delivers reservation/cancellation events)
- **Downstream dependencies**: TravelClick external platform (OTA XML over HTTPS), Getaways Inventory service (HTTP), MBus (response publishing), Kafka (ARI event publishing), MySQL via DaaS (persistence)

## Stakeholders

| Role | Description |
|------|-------------|
| Getaways Engineering | Owning team; responsible for development, deployment, and operations |
| SRE / On-call | Monitors PagerDuty service `PEAIXM8`; receives alerts via Slack channel `CF9BSJ5GX` |
| TravelClick | External channel manager partner; sends ARI push data and receives reservation/cancellation OTA XML |
| Getaways Connect Dev | Secondary notification contact (`getaways-connect-dev@groupon.com`) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 (target JDK) | `pom.xml` `project.build.targetJdk` |
| Framework | Dropwizard (via JTier) | JTier service-pom 5.14.1 | `pom.xml` parent `jtier-service-pom` |
| Runtime | JVM | Java 8 runtime image (legacy Dockerfile); CI uses Java 11 | `Dockerfile`, `.ci/Dockerfile` |
| Build tool | Maven | 3.3.9 | `mvnvm.properties` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-okhttp` | JTier BOM | http-framework | Outbound HTTP client for TravelClick and Inventory service calls |
| `kafka-clients` | 0.10.2.1 | message-client | Publishes ARI events to Kafka topics |
| `jtier-messagebus-client` | JTier BOM | message-client | Consumes reservation/cancellation messages from MBus |
| `jtier-jdbi` | JTier BOM | db-client | JDBI DAOs for MySQL persistence |
| `jtier-daas-mysql` | JTier BOM | db-client | DaaS-managed MySQL connectivity |
| `jtier-migrations` | JTier BOM | db-client | Schema migration management |
| `javax.xml.bind` / `jaxb-impl` | 2.3.1 / 2.3.4 | serialization | OTA XML marshalling/unmarshalling |
| `jersey-media-jaxb` | 2.33 | serialization | JAX-RS XML media type support |
| `oval` | 3.2.1 | validation | Request payload validation |
| `lombok` | 1.18.22 | code-generation | Boilerplate reduction for model classes |
| `joda-money` | 0.12 | serialization | Monetary amount handling |
| `commons-collections` | 3.2.2 | utility | Collection utilities |
| `channel-manager-async-schema` | 0.0.22 | message-client | Shared schema definitions for channel manager MBus messages |
| `jtier-swagger-annotations` | JTier BOM | api-docs | OpenAPI/Swagger annotation support |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
