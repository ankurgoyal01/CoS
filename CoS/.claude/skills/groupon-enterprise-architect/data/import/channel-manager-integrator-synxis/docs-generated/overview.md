---
service: "channel-manager-integrator-synxis"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Travel / Hotel Channel Management"
platform: "Continuum"
team: "Travel Engineering"
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

# Channel Manager Integrator SynXis Overview

## Purpose

Channel Manager Integrator SynXis (CMI SynXis) is a Dropwizard/JTier service that integrates Groupon's Continuum commerce platform with the SynXis Central Reservation System (CRS). It receives ARI (Availability, Rates, and Inventory) push updates from SynXis over SOAP, validates and enriches them, and publishes the events to Kafka for downstream consumption. It also manages the full hotel reservation and cancellation lifecycle by consuming request messages from MBus, coordinating with SynXis SOAP APIs, persisting state to MySQL, and publishing response messages back over MBus.

## Scope

### In scope

- Receiving SOAP ARI push requests (`pushAvailability`, `pushInventory`, `pushRate`, `ping`) from SynXis CRS
- Validating ARI payloads against hotel hierarchy data fetched from Inventory Service
- Publishing validated ARI events to Kafka (`continuumKafkaBroker`)
- Consuming RESERVE and CANCEL request messages from MBus
- Coordinating reservation and cancellation workflows against SynXis ChannelConnect SOAP APIs
- Persisting mapping data, reservation state, and request/response logs to MySQL
- Exposing REST endpoints for mapping management (`/mapping`) and reservation data retrieval (`/reservations`)
- Publishing reservation/cancellation response messages to MBus

### Out of scope

- End-user booking UI or customer-facing APIs
- Hotel content management (name, images, descriptions)
- Payment processing
- Inventory allocation logic (owned by Inventory Service)
- Other channel manager integrations (separate services per channel)

## Domain Context

- **Business domain**: Travel / Hotel Channel Management
- **Platform**: Continuum
- **Upstream consumers**: SynXis CRS (pushes ARI over SOAP), Inventory Service Worker (publishes RESERVE/CANCEL via MBus)
- **Downstream dependencies**: SynXis CRS (reservation/cancellation SOAP calls), Continuum Kafka Broker (ARI events), MBus (reservation responses), Continuum Travel Inventory Service (hotel hierarchy data), MySQL database

## Stakeholders

| Role | Description |
|------|-------------|
| Travel Engineering | Owns and maintains this service |
| Hotel Supply / Partnerships | Relies on correct ARI data reaching Kafka for pricing and availability |
| Platform Engineering | Maintains Continuum Kafka and MBus infrastructure |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | Service summary |
| Framework | Dropwizard / JTier | 5.14.1 | Service summary |
| SOAP Framework | Apache CXF | 3.1.6 | Service summary |
| Build tool | Maven | — | Service summary |
| Package manager | Maven | — | Service summary |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Apache CXF | 3.1.6 | http-framework | SOAP server (CMService) and SOAP client (SynXis CRS calls) |
| Dropwizard JaxWS | 1.0.1 | http-framework | JAX-WS / SOAP integration for Dropwizard |
| Kafka Client | 0.10.2.1 | message-client | Publishes ARI events to Kafka |
| jtier-messagebus-client | — | message-client | Consumes RESERVE/CANCEL from MBus; publishes reservation responses |
| JDBI3 | — | db-client | DAO layer for MySQL reads/writes |
| jtier-daas-mysql | — | db-client | JTier-managed MySQL datasource |
| OkHttp | — | http-framework | HTTP client for Inventory Service REST calls |
| Joda Money | 0.12 | serialization | Monetary value handling in reservation payloads |
| OVal | 1.31 | validation | Bean/payload validation |
