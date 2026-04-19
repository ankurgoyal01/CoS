---
service: "umapi"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Identity, Auth & User Data / Merchant Platform"
platform: "Continuum"
team: "Merchant Platform"
status: active
tech_stack:
  language: "Java"
  language_version: ""
  framework: "Vert.x"
  framework_version: ""
  runtime: "JVM"
  runtime_version: ""
  build_tool: "Gradle (inferred)"
  package_manager: ""
---

# Universal Merchant API (UMAPI) Overview

## Purpose

The Universal Merchant API (UMAPI) is the centralized API for merchant lifecycle operations within Groupon's Continuum Platform. It provides a single integration point for merchant onboarding, profile updates, search, reporting, and data aggregation. UMAPI serves as the authoritative source for merchant and place data consumed by Merchant Center, mobile merchant apps, and numerous internal platform services.

## Scope

### In scope
- Merchant onboarding and registration workflows
- Merchant profile management (updates, search, retrieval)
- Place/location data management and lookup (e.g., by slug)
- Merchant reporting and data aggregation
- OAuth-based authentication for merchant-facing applications
- Merchant contact and account data synchronization
- 3PIP (third-party integration partner) merchant mapping and onboarding state
- Booking-service data operations for merchant tools
- Campaign, billing, and performance operations proxied by downstream services

### Out of scope
- Consumer-facing deal browsing and purchase flows (handled by deal catalog, orders services)
- Payment processing (handled by payments services)
- Deal creation and pricing (handled by Marketing Deal Service, Pricing Service)
- Merchant communication/email delivery (handled by Mailman)
- Consumer mobile app experiences (handled by Android/iOS consumer apps)
- Next-gen Encore wrapper layer (handled by Encore UMAPI Wrapper in groupon-monorepo)

## Domain Context

- **Business domain**: Identity, Auth & User Data / Merchant Platform
- **Platform**: Continuum
- **Upstream consumers**: API Proxy (edge gateway), Merchant Center Web, Mobile Flutter Merchant App, AI Reporting Service, Bookability Dashboard, Marketing Deal Service, Mailman, Minos, Merchant Page Service, Merchant Booking Tool, Sponsored Campaign iTier, LS Voucher Archive iTier, 3PIP Merchant Onboarding iTier, Merchant Service (M3), Encore UMAPI Wrapper
- **Downstream dependencies**: Message Bus (ActiveMQ Artemis)

## Stakeholders

| Role | Description |
|------|-------------|
| Merchant Platform team | Owns and maintains UMAPI |
| Merchant Center team | Primary UI consumer for merchant operations |
| Mobile Merchant team | Consumes merchant APIs for Flutter merchant app |
| Platform Engineering | Manages edge routing and infrastructure |
| Data & Reporting teams | Consume merchant data for analytics and reporting |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | -- | `architecture/models/containers.dsl` |
| Framework | Vert.x | -- | `architecture/models/containers.dsl` |
| Runtime | JVM | -- | inferred from Java / Vert.x |
| Build tool | Gradle | -- | inferred (Continuum Java convention) |
| Package manager | -- | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Vert.x Web | -- | http-framework | Reactive HTTP server and routing |
| Vert.x EventBus | -- | message-client | Internal async communication |

> Only the most important libraries are listed here -- the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
