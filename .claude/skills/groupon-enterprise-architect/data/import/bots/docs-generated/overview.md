---
service: "bots"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Merchant Booking & Availability"
platform: "Continuum"
team: "BOTS (ssamantara, rdownes, joeliu)"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard / JTier"
  framework_version: "5.14.0"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# BOTS (Booking Oriented Tools & Services) Overview

## Purpose

BOTS is Groupon's merchant-facing booking and availability management service. It provides the API and background processing infrastructure that merchants use to configure their booking calendars, manage appointments, process voucher redemptions, and receive onboarding support. BOTS sits within the Continuum platform and bridges merchant operations (CRM, calendar, vouchers) with Groupon's commerce infrastructure.

## Scope

### In scope

- Creating, searching, rescheduling, canceling, checking in, acknowledging, and deleting merchant bookings
- Managing merchant campaign and service configurations for bookable deals
- Computing and serving merchant availability windows
- Synchronizing merchant calendars via Google Calendar integration
- Processing voucher redemption workflows
- Consuming deal onboarding/offboarding events to initialize merchant booking setup
- Handling GDPR erasure requests for booking-related personal data
- Publishing booking lifecycle events (`booking.events.*`) to the message bus

### Out of scope

- Consumer-facing booking discovery or checkout (owned by frontend / commerce services)
- Deal creation and pricing (owned by Deal Management / Deal Catalog)
- Merchant identity and account management (owned by M3 Merchant Service)
- Voucher inventory management (owned by Voucher Inventory Service / VIS)
- Transactional notification delivery (owned by Rocketman Commercial)
- Analytics aggregation (owned by TSD Aggregator)

## Domain Context

- **Business domain**: Merchant Booking & Availability
- **Platform**: Continuum
- **Upstream consumers**: Merchant-facing clients, internal Groupon tooling calling `/merchants/{id}/bookings` and related endpoints
- **Downstream dependencies**: M3 Merchant Service, Deal Management, Deal Catalog, Calendar Service, Voucher Inventory Service (VIS), M3 Places, Cyclops, Salesforce, Google OAuth, Google Calendar, Message Bus, TSD Aggregator, Rocketman Commercial

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | ssamantara — primary contact for architecture and escalations |
| Engineering | rdownes, joeliu — development and on-call |
| Merchant Operations | Internal teams relying on booking data and availability APIs |
| Deal Management | Upstream producers of deal onboarding/offboarding events consumed by BOTS |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | Service summary |
| Framework | Dropwizard / JTier | 5.14.0 | Service summary |
| Runtime | JVM | 11 | Service summary |
| Build tool | Maven | — | Service summary |
| Package manager | Maven | — | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-daas-mysql | — | db-client | Managed MySQL data access via JTier DaaS layer |
| jtier-jdbi / jdbi3 | — | orm | JDBI DAO layer for transactional SQL operations |
| jtier-messagebus-client | — | message-client | Publish and consume events via Groupon Message Bus |
| jtier-quartz-bundle | — | scheduling | Quartz-based scheduled background jobs |
| jtier-retrofit | — | http-framework | Retrofit HTTP clients for internal/external service calls |
| jtier-auth-bundle | — | auth | JTier-integrated authentication and authorization |
| google-api-client | 1.25.0 | http-framework | Google API base client for OAuth and Calendar integration |
| google-apis-calendar | v3 | http-framework | Google Calendar v3 API integration |
| ical4j | 3.0.20 | serialization | iCalendar format parsing and generation for calendar sync |
| bcrypt | 0.9.0 | auth | Password/credential hashing for merchant authentication flows |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
