---
service: "sem-ui"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Search Engine Marketing"
platform: "continuum"
team: "SEM / Search Engineering"
status: active
tech_stack:
  language: "Node.js"
  language_version: "16.20.2"
  framework: "I-Tier"
  framework_version: "7.9.2"
  runtime: "Node.js"
  runtime_version: "16.20.2"
  build_tool: "webpack"
  package_manager: "npm"
---

# SEM Admin UI Overview

## Purpose

SEM Admin UI is an internal I-Tier dashboard that gives Search Engine Marketing operators a single interface for managing SEM data across Groupon's commerce platform. It provides keyword lifecycle management, denylist (blacklist) administration, and attribution-lens analysis for order attribution. The service acts as a stateless proxy UI, delegating all data persistence to downstream SEM microservices.

## Scope

### In scope

- Rendering and navigation for the SEM administration dashboard
- Proxying keyword read and write operations to SEM Keywords Service via `/proxy/keyword/deals/{permalink}/keywords`
- Proxying denylist entry management to SEM Blacklist Service via `/proxy/denylist`
- Proxying attribution order data from GPN Data API via `/proxy/attribution/orders`
- Page routing for `/`, `/attribution-lens`, `/denylisting`, and `/keyword-manager`
- User authentication via I-Tier user auth middleware

### Out of scope

- Persistent storage of keyword or denylist data (owned by SEM Keywords Service and SEM Blacklist Service)
- Attribution data ingestion or aggregation (owned by GPN Data API)
- SEM bid management or campaign orchestration
- Search indexing or ranking

## Domain Context

- **Business domain**: Search Engine Marketing
- **Platform**: Continuum
- **Upstream consumers**: SEM operators and admins accessing the dashboard in a browser
- **Downstream dependencies**: SEM Keywords Service, SEM Blacklist Service (`continuumSemBlacklistService`), GPN Data API

## Stakeholders

| Role | Description |
|------|-------------|
| SEM Operator | Primary user; manages keywords and denylists via the dashboard UI |
| SEM Admin | Configures denylist entries and reviews attribution data |
| Search Engineering | Owns and maintains the service |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Node.js | 16.20.2 | inventory |
| Framework | I-Tier | 7.9.2 | inventory |
| Runtime | Node.js | 16.20.2 | inventory |
| Build tool | webpack | 5.74.0 | inventory |
| Package manager | npm | | inventory |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| itier-server | 7.9.2 | http-framework | I-Tier server runtime and routing |
| preact | 10.10.2 | ui-framework | Lightweight React-compatible UI rendering |
| @grpn/graphql | 4.0.0 | http-framework | Groupon GraphQL client utilities |
| keldor | 7.3.8 | http-framework | I-Tier proxy and middleware utilities |
| itier-user-auth | 8.1.0 | auth | User authentication middleware for I-Tier |
| itier-instrumentation | 9.11.2 | metrics | Observability and metrics instrumentation |
| gofer | 5.2.4 | http-framework | HTTP client for downstream service calls |
| mocha | 9.2.2 | testing | Unit and integration test runner |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
