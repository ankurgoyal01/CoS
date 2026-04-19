---
service: "marketing"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Content, Editorial & SEO / CRM, Notifications & Messaging"
platform: "Continuum"
team: "Marketing Platform"
status: active
tech_stack:
  language: "Java / Ruby on Rails"
  language_version: ""
  framework: "Microservice suite (Mailman, Rocketman)"
  framework_version: ""
  runtime: "JVM / Ruby"
  runtime_version: ""
  build_tool: "Maven / Bundler"
  package_manager: "Maven / Bundler"
---

# Marketing & Delivery Platform Overview

## Purpose

The Marketing & Delivery Platform is Groupon's centralized campaign management and delivery system within the Continuum Platform. It orchestrates the creation, scheduling, and delivery of marketing campaigns and consumer notifications across email, push, and inbox channels. The platform includes Mailman and Rocketman subsystems and manages user messaging inboxes, campaign lifecycle workflows, topic-based subscriptions, and event logging via Kafka.

## Scope

### In scope
- Campaign creation, orchestration, and lifecycle management
- User messaging inbox management
- Topic and user subscription management (opt-in/opt-out)
- Marketing notification delivery (order confirmations, campaign pushes)
- Event logging for campaign and delivery metrics via Kafka
- Publishing campaign and subscription events to the shared Message Bus

### Out of scope
- Deal creation and catalog management (handled by Deal Catalog Service / `continuumDealCatalogService` and Deal Management API / `continuumDealManagementApi`)
- Marketing deal enrichment and placement (handled by Marketing Deal Service / `continuumMarketingDealService`)
- Audience segmentation and computation (handled by Audience Management Service / `continuumAudienceManagementService`)
- Ad inventory and sponsored placements (handled by Ad Inventory Service / `continuumAdInventoryService`)
- Email rendering and delivery infrastructure (handled by Email Service / `continuumEmailService`)
- Order processing (handled by Orders Service / `continuumOrdersService`)

## Domain Context

- **Business domain**: Content, Editorial & SEO / CRM, Notifications & Messaging
- **Platform**: Continuum (Groupon's core commerce engine)
- **Upstream consumers**: Orders Service (`continuumOrdersService`), Marketing Deal Service (`continuumMarketingDealService`), Administrator (internal operations staff)
- **Downstream dependencies**: Marketing Platform Database (`continuumMarketingPlatformDb`), Message Bus (`messageBus`)

## Stakeholders

| Role | Description |
|------|-------------|
| Marketing Platform team | Owns and operates the platform, maintains campaign orchestration and delivery |
| Marketing operations (Administrator) | Creates and manages marketing campaigns via the platform's administrative interface |
| Consumer product teams | Depend on inbox and notification delivery for consumer experience |
| Orders team | Triggers confirmation notifications via the platform after checkout |
| Data/analytics teams | Consume campaign event logs for reporting and optimization |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java / Ruby on Rails | - | Container definition: "Java / Ruby on Rails" |
| Framework | Microservice suite (Mailman, Rocketman) | - | Container description |
| Runtime | JVM / Ruby | - | Inferred from Java/Rails |
| Build tool | Maven / Bundler | - | Inferred from Java and Rails conventions |
| Package manager | Maven / Bundler | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Kafka Client | - | message-client | Event logging and publishing campaign events to Kafka topics |
| MBus Client | - | message-client | Publishing campaign and subscription events to Groupon's Message Bus |
| JDBC (MySQL) | - | db-client | Database connectivity to Marketing Platform DB (DaaS) |

> Only the most important libraries are listed here -- the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
