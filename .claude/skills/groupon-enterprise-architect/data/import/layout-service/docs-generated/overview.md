---
service: "layout-service"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Frontend Platform"
platform: "Continuum"
team: "Frontend Platform"
status: active
tech_stack:
  language: "JavaScript"
  language_version: ""
  framework: "itier-server / Express"
  framework_version: ""
  runtime: "Node.js"
  runtime_version: ""
  build_tool: "npm"
  package_manager: "npm"
---

# Layout Service Overview

## Purpose

Layout Service is a Node.js i-tier web service that serves the page chrome — header, footer, and navigation — consumed by all Groupon i-tier frontend applications. It composes locale, market, and user context into Mustache/Hogan templates and returns rendered layout fragments. It also resolves CDN-backed static assets and brand-specific resources, ensuring consistent visual chrome across every consumer page.

## Scope

### In scope

- Serving `/layout/*` endpoints for page chrome composition
- Composing locale, market, and user/session context per request
- Rendering Mustache/Hogan templates for header and footer fragments
- Resolving and returning CDN-backed static asset URLs and metadata
- Reading and writing compiled templates and fragments to a Redis cache

### Out of scope

- Page-level content or deal/offer data (owned by content and commerce services)
- User authentication and session management (owned by identity services)
- CDN edge configuration and cache purging (owned by infrastructure teams)
- Full-page server-side rendering (owned by individual i-tier app services)

## Domain Context

- **Business domain**: Frontend Platform
- **Platform**: Continuum
- **Upstream consumers**: All Groupon i-tier frontend applications requesting page chrome via `/layout/*` endpoints
- **Downstream dependencies**: `continuumLayoutTemplateCache` (Redis) for template and fragment caching; CDN for static asset resolution

## Stakeholders

| Role | Description |
|------|-------------|
| Frontend Platform Team | Owns and operates the service; responsible for layout correctness and performance |
| I-tier App Teams | Primary consumers; depend on layout-service for header/footer chrome on every page load |
| Infrastructure / SRE | Responsible for Kubernetes deployment, Redis provisioning, and CDN configuration |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript | — | `continuum-layout-service-components.dsl` |
| Framework | itier-server / Express | — | `continuum-layout-service-components.dsl` |
| Runtime | Node.js | — | `continuum-layout-service-components.dsl` |
| Build tool | npm | — | Standard Node.js toolchain |
| Package manager | npm | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| itier-server | — | http-framework | I-tier Node.js server bootstrap and middleware |
| Express | — | http-framework | HTTP routing and middleware pipeline |
| Mustache / Hogan | — | ui-framework | Mustache template compilation and rendering |
| Redis client | — | db-client | Template and fragment cache read/write via Redis protocol |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
