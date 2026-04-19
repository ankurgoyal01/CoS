---
service: "goods-shipment-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Inventory / Goods Logistics"
platform: "Continuum"
team: "inventory"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "JTier jtier-service-pom 5.14.0"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Goods Shipment Service Overview

## Purpose

The Goods Shipment Service manages the full lifecycle of physical goods shipments for Groupon orders. It receives shipment records from upstream fulfilment systems, polls multiple carrier APIs (UPS, FedEx, DHL, USPS, AIT, UPSMI, FedEx SmartPost) for tracking status updates, and processes webhook events from Aftership. It is the authoritative source for shipment status and triggers email and mobile push notifications to consumers as shipments progress.

## Scope

### In scope

- Creating and updating shipment records linked to order line items
- Polling carrier APIs (UPS, FedEx, DHL, USPS, AIT, UPSMI, FedEx SmartPost) for real-time tracking data
- Receiving and validating inbound Aftership webhooks for status updates
- Creating and managing Aftership tracking registrations for shipments
- Routing carrier-specific OAuth2 token acquisition and refreshing
- Sending shipment status email notifications via Rocketman
- Sending mobile push notifications via Event Delivery Service
- Publishing shipment status events to the message bus (`goodsShipmentNotification` destination)
- Publishing order fulfilment notifications to the message bus (`orderFulfillmentNotification` destination)
- Scheduled jobs for carrier refresh, untracked shipment update, shipment rejection, email notification dispatch, mobile notification dispatch, and auth-token refresh

### Out of scope

- Order creation and payment processing (handled by upstream commerce systems)
- Inventory management and voucher issuance
- Consumer-facing shipment tracking UI (consumed by other services)
- Carrier label generation

## Domain Context

- **Business domain**: Inventory / Goods Logistics
- **Platform**: Continuum
- **Upstream consumers**: Commerce systems that POST shipment records; Aftership platform delivering webhooks; admin tooling using admin endpoints
- **Downstream dependencies**: Commerce Interface (`commerceInterfaceService`), Aftership API (`aftershipApi`), Rocketman email service (`rocketmanService`), Event Delivery Service (`eventDeliveryService`), Token Service (`tokenService`), UPS API (`upsApi`), FedEx API (`fedexApi`), DHL API (`dhlApi`), USPS API (`uspsApi`), AIT API (`aitApi`), UPSMI API (`upsmiApi`), FedEx SmartPost API (`fedexspApi`), Message Bus (`mbusGoodsShipmentNotificationTopic`)

## Stakeholders

| Role | Description |
|------|-------------|
| Service owner | Inventory team — goods-eng-seattle@groupon.com |
| SRE / On-call | PagerDuty service goods-shipment-service@groupon.pagerduty.com |
| Slack channel | goods-eng-seattle |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` `project.build.targetJdk` = 11; Dockerfile `prod-java11-jtier` |
| Framework | Dropwizard (via JTier) | jtier-service-pom 5.14.0 | `pom.xml` parent |
| Runtime | JVM | 11 | `Dockerfile` `prod-java11-jtier:2023-12-19-609aedb` |
| Build tool | Maven | — | `pom.xml`, `.mvn/maven.config` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-daas-mysql | (managed) | db-client | JTier MySQL DaaS integration |
| jtier-jdbi3 | (managed) | orm | JDBI3 SQL object DAO layer |
| jtier-migrations | (managed) | db-client | Flyway-based DB migrations |
| jtier-retrofit | (managed) | http-framework | Retrofit2 HTTP client for carrier APIs |
| jtier-okhttp | (managed) | http-framework | OkHttp client for direct HTTP calls |
| jtier-messagebus-client | (managed) | message-client | Message bus (Mbus) publisher |
| jtier-messagebus-dropwizard | (managed) | message-client | Dropwizard lifecycle integration for Mbus |
| jtier-quartz-bundle | 1.1.0 | scheduling | Quartz scheduler for recurring jobs |
| jtier-quartz-mysql-migrations | 0.1.4 | scheduling | Quartz MySQL persistence store migrations |
| Lombok | 1.18.22 | validation | Boilerplate reduction (Data, Builder, etc.) |
| fedex-api | 1.1.2 | http-framework | Groupon internal FedEx API wrapper |
| jackson-databind-nullable | 0.2.1 | serialization | OpenAPI nullable model support |
| gson-fire | 1.8.5 | serialization | Gson extension for generated API models |
| commons-lang3 | 3.12.0 | validation | String/collection utilities |
| log4j-core | 2.18.0 | logging | Required by FedEx library for trace logging |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
