---
service: "etorch"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Getaways / Extranet"
platform: "Continuum"
team: "Getaways Engineering (getaways-eng@groupon.com)"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "JAX-RS/Jersey"
  framework_version: "2.43"
  runtime: "Jetty"
  runtime_version: "9.4.51"
  build_tool: "Maven"
  package_manager: "Maven"
---

# eTorch Overview

## Purpose

eTorch (Extranet Travel ORCHestrator) is the merchant-facing REST API for the Groupon Getaways platform. It enables hotel operators and channel managers to manage their inventory, deals, accounting statements, and contact information through a dedicated extranet interface. The service acts as an orchestration layer, coordinating data across inventory, content, merchant, and accounting backends to present a unified API to Getaways partners.

## Scope

### In scope

- Exposing hotel accounting statements and payment records to merchants via REST
- Managing hotel contacts and contact role assignments
- Providing reference data for cities, countries, and channel managers
- Receiving and processing deal update batch job requests
- Surfacing recent auto-updates for hotel inventory
- Scheduling and running background jobs for inventory sync, low inventory reporting, and maintenance tasks

### Out of scope

- Consumer-facing hotel booking and checkout (handled by Getaways consumer services)
- Deal creation and lifecycle management (handled by `continuumDealManagementApi`)
- Raw payment processing (handled by `continuumAccountingService` and MX Merchant API)
- Hotel content authoring (handled by Getaways Content service)
- Channel manager protocol translation (handled by Channel Manager Integrator / Synxis)

## Domain Context

- **Business domain**: Getaways / Extranet (merchant-facing hotel operations)
- **Platform**: Continuum
- **Upstream consumers**: Hotel operators and channel manager integrations using the Getaways Extranet portal
- **Downstream dependencies**: Getaways Inventory, Getaways Content, LARC, Channel Manager Integrator (Synxis), Notification Service, MX Merchant API, Rocketman, Deal Management API, Accounting Service

## Stakeholders

| Role | Description |
|------|-------------|
| Getaways Engineering | Owning team responsible for development and operations (getaways-eng@groupon.com) |
| Hotel / Property Operators | Merchants who access the extranet to manage their hotel listings and review accounting |
| Channel Managers | Third-party channel management systems (e.g., Synxis) that integrate via the extranet API |
| Finance / Accounting | Internal users who rely on generated accounting reports produced by the worker jobs |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | Service summary |
| Framework | JAX-RS/Jersey | 2.43 | Service summary |
| Secondary framework | RESTEasy | 3.0.3 | Service summary |
| Runtime | Jetty | 9.4.51 | Service summary |
| Build tool | Maven | — | Service summary |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Jackson | 2.17.0 | serialization | JSON serialization and deserialization for REST payloads |
| SLF4J + Log4j2 | — | logging | Structured application logging |
| Apache HttpComponents | 4.3.1 | http-framework | HTTP client for downstream service calls |
| MapStruct | 1.3.0 | validation | Type-safe bean mapping between API and domain models |
| Swagger | — | api-docs | OpenAPI specification generation for extranet endpoints |
| AppConfig | 1.8.0 | config | Application configuration management |
| Joda Money | 0.10.0 | domain | Currency and monetary value handling for accounting |
| Quartz | — | scheduling | Job scheduling for background worker tasks |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
