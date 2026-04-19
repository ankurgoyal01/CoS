---
service: "bookingtool"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Merchant Reservations / EMEA Bookings"
platform: "Continuum"
team: "Booking-tool (ssamantara)"
status: active
tech_stack:
  language: "PHP"
  language_version: "5.6"
  framework: "Apache + PHP-FPM"
  framework_version: ""
  runtime: "PHP-FPM"
  runtime_version: ""
  build_tool: "Capistrano"
  build_tool_version: "3.6.1"
  package_manager: "Composer"
---

# Booking Tool Overview

## Purpose

The Booking Tool is Groupon's EMEA-facing reservation management platform. It provides merchants with the ability to configure their availability windows and manage blocked-out time slots, while enabling customers to book, reschedule, and cancel appointments against purchased Groupon vouchers. The service acts as the authoritative system of record for all reservation state within the Continuum platform.

## Scope

### In scope

- Merchant availability schedule configuration (recurring and one-off slots)
- Blocked-time management for merchants (single and bulk)
- Customer appointment booking against valid vouchers
- Customer appointment cancellation and rescheduling
- Booking check-in recording
- Bank holiday calendar management per locale
- Consumer access request handling
- Admin authentication via Okta
- Export of booking data to spreadsheet (phpspreadsheet) and calendar (iCal)
- InfluxDB metrics emission for booking operations
- JWT-secured API interactions with internal services

### Out of scope

- Voucher issuance and payment processing (handled by Voucher Inventory / order services)
- Deal catalog authoring (handled by Deal Catalog service)
- Email delivery (delegated to Rocketman V2)
- Merchant identity management (delegated to Salesforce / MX Merchant API)
- Customer identity and authentication (delegated to API-INTL / RaaS)

## Domain Context

- **Business domain**: Merchant Reservations / EMEA Bookings
- **Platform**: Continuum
- **Upstream consumers**: Customer-facing booking UIs, Groupon consumer apps, internal admin portals
- **Downstream dependencies**: MySQL 5.6 (reservations store), Redis (sessions/cache), Salesforce, Zendesk, Voucher Inventory, Deal Catalog, MX Merchant API, Cyclops, Rocketman V2, Appointment Engine, RaaS, API-INTL

## Stakeholders

| Role | Description |
|------|-------------|
| Booking-tool team (ssamantara) | Service owner; responsible for development, operations, and on-call |
| EMEA Merchants | Configure availability and manage bookings via merchant portal |
| EMEA Customers | Book, cancel, and reschedule appointments via consumer-facing flows |
| Groupon Operations | Admin users managing bookings and merchant setups internally |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | PHP | 5.6 | Service inventory / Dockerfile |
| Runtime | Apache + PHP-FPM | — | Service inventory |
| Build tool | Capistrano | 3.6.1 | Service inventory / Capfile |
| Package manager | Composer | — | composer.json |
| Deployment scripting | Ruby | 2.2.2 | Capistrano requirement |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| guzzlehttp/guzzle | 6.5.5 | http-client | Outbound HTTP calls to all internal and external service integrations |
| doctrine/dbal | 2.5.13 | db-client | SQL query abstraction over MySQL 5.6 |
| pimple | 3.2.3 | di-container | Lightweight dependency injection container |
| monolog | 1.23.0 | logging | Structured application logging |
| influxdb-php | ^1.15 | metrics | Emits operational metrics to InfluxDB |
| lcobucci/jwt | 3.2.5 | auth | JWT generation and validation for service-to-service auth |
| aws/aws-sdk-php | 3.63.3 | cloud-sdk | AWS service interactions (S3, Secrets Manager, etc.) |
| phpspreadsheet | 1.4.0 | serialization | Export booking data to XLSX |
| eluceo/ical | 0.11.6 | serialization | Export booking data to iCal format |
| zendesk_api | 2.2.14 | integration | Zendesk ticket operations for merchant support |
| messagebus | 0.3.6 | message-client | Async event publishing to the Booking Tool message bus topic |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
