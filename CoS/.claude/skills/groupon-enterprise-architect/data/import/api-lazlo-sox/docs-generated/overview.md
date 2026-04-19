---
service: "api-lazlo-sox"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Infrastructure & Platform (API Gateway)"
platform: "Continuum"
team: "API Platform / Mobile API"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Vert.x, Lazlo"
  framework_version: "Lazlo internal"
  runtime: "JVM"
  runtime_version: "Eclipse Temurin 11"
  build_tool: "Gradle"
  package_manager: "Gradle"
---

# API Lazlo / API Lazlo SOX Overview

## Purpose

API Lazlo is Groupon's core mobile API gateway, serving as the primary aggregation layer between first-party mobile and web clients and the backend domain microservices (deals, users, orders, geo, taxonomy, UGC, and more). It exposes a unified REST/JSON API under `/api/mobile/{countryCode}` that composes responses from dozens of downstream services into mobile-optimized payloads.

API Lazlo SOX is a separately deployed variant of the same gateway, scoped to SOX-regulated flows covering partner bookings and regulated user/account operations. It shares the core business logic modules but is configured and deployed independently to meet compliance requirements.

## Scope

### In scope

- Mobile REST/JSON API gateway for all consumer-facing mobile and web experiences
- Aggregation and orchestration of downstream domain services (users, deals, orders, cart, geo, taxonomy, UGC, payments, vouchers)
- SOX-regulated partner and user flows via the separately deployed SOX service
- Redis-based caching for taxonomy, localization, feature flags, and transient state
- Request filtering, locale handling, header processing, and common view rendering
- Health checks, readiness probes, and warmup endpoints for orchestration

### Out of scope

- Domain business logic (owned by downstream services such as users-service, orders-service, deal-service)
- Database ownership (API Lazlo is stateless aside from Redis cache; persistent data is owned by domain services)
- Merchant-facing APIs (handled by other gateways or BFF layers)
- Batch processing and async event pipelines (API Lazlo is a synchronous request/response gateway)
- Authentication token issuance (handled by upstream identity providers; API Lazlo validates and forwards tokens)

## Domain Context

- **Business domain**: Infrastructure & Platform (API Gateway)
- **Platform**: Continuum
- **Upstream consumers**: Groupon mobile apps (iOS, Android), Groupon web clients, MBNXT PWA
- **Downstream dependencies**: Users Service, Orders Service, Deal/Catalog Service, Inventory Service, Geo Service, Taxonomy Service, Content Service, Relevance Service, Payment Service, Cart Service, Bucks Service, Voucher Service, Messaging Service, Consumer Service, Program Enrollment, Subscriptions Service

## Stakeholders

| Role | Description |
|------|-------------|
| API Platform / Mobile API Team | Owns the API Lazlo codebase, deployment, and on-call |
| Mobile Engineering | Primary consumers of the API Lazlo endpoints |
| Domain Service Teams | Own the downstream services that API Lazlo aggregates |
| Compliance / SOX Audit | Stakeholders for the SOX-scoped deployment and its regulated flows |
| SRE / Platform Engineering | Infrastructure, scaling, and reliability of the gateway |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | Container definitions in architecture DSL |
| Framework | Vert.x + Lazlo | Internal | Lazlo controller-core, BLS modules |
| Runtime | JVM | Eclipse Temurin 11 | Deployment configuration |
| Build tool | Gradle | - | Project build system |
| Package manager | Gradle | - | Dependency management |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Vert.x Core | - | http-framework | Async, non-blocking HTTP server and event loop |
| Lazlo controller-core | Internal | http-framework | Controller routing, endpoint annotations, request/response lifecycle |
| Lazlo BLS | Internal | orm | Business Logic Service module framework for domain orchestration |
| Lazlo client-core | Internal | http-framework | Typed HTTP clients for downstream service communication |
| Lazlo Redis | Internal | db-client | Redis client integration for caching and transient state |
| metrics-vertx | Internal | metrics | HTTP and JVM metrics collection and export |
| SLF4J / Logback | - | logging | Structured logging framework |
| Jolokia | - | metrics | JMX-over-HTTP for JVM monitoring and management |

> Only the most important libraries are listed here -- the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
