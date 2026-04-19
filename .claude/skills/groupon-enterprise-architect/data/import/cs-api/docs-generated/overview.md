---
service: "cs-api"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Customer Support"
platform: "Continuum"
team: "GSO Engineering (nsanjeevi)"
status: active
tech_stack:
  language: "Java"
  language_version: "8/11"
  framework: "Dropwizard / JTier"
  framework_version: ""
  runtime: "JVM"
  runtime_version: ""
  build_tool: "Maven"
  package_manager: "Maven"
---

# CS API (CaaP) Overview

## Purpose

CS API (Customer as a Platform, CaaP) is the back-end API service for Groupon's Cyclops customer support platform. It provides a unified interface for customer support agents to access customer data, manage cases and memos, look up orders and deals, and perform support actions such as converting refunds to Groupon Bucks. It aggregates data from more than a dozen internal and external services into coherent agent-facing responses.

## Scope

### In scope

- Serving REST endpoints consumed by agent-facing CS tooling (Cyclops)
- Authenticating agent sessions via JWT and CS Token Service
- Aggregating customer profile data from Users Service, Consumer Data Service, and Audience Management
- Querying order history and deal catalog across multiple inventory services
- Managing case memos, snippets, and agent notes in MySQL
- Exposing agent ability and role management (CRUD)
- Proxying Zendesk ticket creation and retrieval
- Proxying Salesforce CRM queries
- Executing convert-to-cash (Groupon Bucks) refund actions via Incentives Service
- Reading and writing session data to Redis

### Out of scope

- Consumer-facing (buyer) APIs — handled by other Continuum services
- Merchant-facing self-service — handled by Merchant Center
- Order fulfillment and payment processing — handled by Orders Service and Incentives Service
- Direct BoldChat live-chat orchestration (integration exists but managed externally)
- Legal consent management — handled by Legal Consents Service

## Domain Context

- **Business domain**: Customer Support
- **Platform**: Continuum
- **Upstream consumers**: Cyclops CS agent web application (customerSupportAgent)
- **Downstream dependencies**: Users Service, Orders Service, Deal Catalog, Goods Inventory, Goods Central, Audience Management, Consumer Data Service, Incentives Service, CS Token Service, Lazlo API, Zendesk, Salesforce, BoldChat, MySQL (read/write), Redis (session and cache)

## Stakeholders

| Role | Description |
|------|-------------|
| GSO Engineering (nsanjeevi) | Service owner; responsible for development and operations |
| CS Agents | End users of the Cyclops platform powered by this API |
| CS Platform Team | Consumers of the API contract for Cyclops front-end integration |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 8/11 | Summary inventory |
| Framework | Dropwizard / JTier | — | Summary inventory |
| HTTP layer | Jersey (JAX-RS) | — | Summary inventory |
| Build tool | Maven | — | Summary inventory |
| Package manager | Maven | — | Summary inventory |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-daas-mysql | — | db-client | JTier-managed MySQL data access |
| jtier-jdbi | — | orm | JDBI-based SQL mapping layer |
| jtier-retrofit | — | http-framework | HTTP client abstraction for downstream service calls |
| jtier-auth-bundle | — | auth | Dropwizard auth bundle for JTier platform |
| Dropwizard Redis | 1.2.0 | db-client | Redis integration for session and cache |
| JJWT | 0.11.2 | auth | JWT creation and validation |
| Lombok | 1.18.4 | serialization | Boilerplate reduction for model classes |
| String Template | 3.2 | serialization | Template-based response rendering |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
