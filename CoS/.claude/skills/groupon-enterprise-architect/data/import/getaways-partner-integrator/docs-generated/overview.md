---
service: "getaways-partner-integrator"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Getaways / Travel"
platform: "Continuum"
team: "Travel team"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard + Apache CXF"
  framework_version: "3.1.6"
  runtime: "JTier Java 11"
  runtime_version: "5.14.1"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Getaways Partner Integrator Overview

## Purpose

Getaways Partner Integrator is a Dropwizard/Apache CXF service that acts as the integration bridge between Groupon's getaways inventory platform and external hotel channel managers (SiteMinder, TravelgateX, and APS). It translates between Groupon's internal inventory model and the SOAP-based ARI (Availability, Rates, and Inventory) protocols used by channel managers, and it manages the full reservation lifecycle from notification through confirmation.

## Scope

### In scope

- Exposing SOAP endpoints (`/GetawaysPartnerARI`, `/SiteConnectService`, `/TravelGateXARI`) to receive inbound ARI updates and reservation notifications from channel managers
- Exposing REST endpoints for hotel/room/rate mapping management (`/getaways/v2/channel_manager_integrator/mapping`) and reservation data retrieval (`/reservation/data`)
- Consuming partner inbound messages from Kafka topics
- Consuming and producing `InventoryWorkerMessage` events on the Groupon MBus (JMS)
- Persisting hotel/room/rate plan mappings, reservation records, and SOAP request/response logs to MySQL
- Coordinating reservation workflows via outbound SOAP calls to channel manager systems
- Fetching inventory hierarchy data from the Getaways Inventory Service

### Out of scope

- Consumer-facing booking UI (owned by MBNXT / frontend layer)
- Getaways inventory management and deal creation (owned by Getaways Inventory Service)
- Payment processing for reservations (owned by Continuum payments domain)
- Channel manager contract management and commercial agreements

## Domain Context

- **Business domain**: Getaways / Travel
- **Platform**: Continuum
- **Upstream consumers**: SiteMinder channel manager, TravelgateX channel manager, APS channel manager, internal callers via REST API
- **Downstream dependencies**: Getaways Inventory Service (REST), Groupon Kafka cluster, Groupon MBus (JMS), MySQL (`continuumGetawaysPartnerIntegratorDb`), SiteMinder SOAP API, TravelgateX SOAP API, APS SOAP API

## Stakeholders

| Role | Description |
|------|-------------|
| Travel team | Service owner; responsible for development, operations, and partner integrations |
| Channel manager partners | SiteMinder, TravelgateX, and APS — send ARI and reservation events to this service |
| Getaways operations | Internal team consuming reservation data via REST API |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | JTier base image, `jtier-ctx-java` 5.14.1 |
| Framework | Dropwizard | (JTier-managed) | `dropwizard-jaxws` 1.0.1 dependency |
| SOAP runtime | Apache CXF | 3.1.6 | `cxf-rt-ws-security` 3.1.6 |
| Runtime | JTier | 5.14.1 | `jtier-messagebus-client`, `jtier-jdbi3`, `jtier-daas-mysql` |
| Build tool | Maven | — | Standard Maven project layout |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `dropwizard-jaxws` | 1.0.1 | http-framework | Integrates JAX-WS / CXF SOAP endpoints into Dropwizard |
| `cxf-rt-ws-security` | 3.1.6 | auth | WS-Security authentication for inbound/outbound SOAP calls |
| `wss4j` | 2.1.6 | auth | WS-Security message signing and encryption (Apache WSS4J) |
| `kafka-clients` | 0.10.2.1 | message-client | Kafka consumer for partner inbound topics |
| `jtier-messagebus-client` | (JTier) | message-client | JMS/MBus client for InventoryWorkerMessage events |
| `jtier-jdbi3` | (JTier) | db-client | JDBI3-based DAO layer over MySQL |
| `jtier-daas-mysql` | (JTier) | db-client | JTier-managed MySQL connection pool and DaaS integration |
| `jackson-dataformat-xml` | (Jackson) | serialization | XML serialization/deserialization for SOAP payloads |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
