---
service: "gazebo"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Editorial / Content Management"
platform: "Continuum"
team: "gazebo@groupon.com"
status: active
tech_stack:
  language: "Ruby"
  language_version: "2.1.2"
  framework: "Rails"
  framework_version: "4.1"
  runtime: "Unicorn"
  runtime_version: "4.8.3"
  build_tool: "Bundler 1.16.6, Gulp 3.9.0, Rake"
  package_manager: "Bundler / npm"
---

# Gazebo (Writers' App) Overview

## Purpose

Gazebo is the internal editorial tooling application used by Groupon's editorial teams to create, review, and publish deal copy for the Groupon site. It serves as the central workspace for writers and editors, providing task management, quality checklists, CRM-synced deal data, and a publishing workflow that emits change events downstream. It bridges operational CRM data from Salesforce with Groupon's deal catalog, ensuring editorial content is accurate and consistent before it reaches consumers.

## Scope

### In scope

- Creating and editing deal copy and copy treatments
- Editorial task creation, assignment (claim/unclaim), and completion tracking
- Merchandising checklist management and validation as a publishing gate
- Integration with Salesforce CRM to sync deal and opportunity data
- Media asset management via Bynder integration
- Publishing events to Message Bus on content changes
- Consuming deal and task events from Message Bus to stay synchronized with upstream systems
- Feature flag management via Flipper for progressive rollouts
- Content recovery via a recycle bin for deleted or abandoned content
- Translation request tracking

### Out of scope

- Consumer-facing deal display or storefront rendering (handled by MBNXT / front-end services)
- Deal pricing and inventory management (handled by Deal Catalog and related services)
- Payment processing
- User authentication and identity management (delegated to `continuumUsersService`)

## Domain Context

- **Business domain**: Editorial / Content Management
- **Platform**: Continuum
- **Upstream consumers**: Internal editorial staff (web browser), upstream event producers via Message Bus (deal, task, image, CRM notifications)
- **Downstream dependencies**: `continuumUsersService`, `continuumDealCatalogService`, `salesForce`, `continuumBynderIntegrationService`, `dmapiSystem_44f3e5`, `gpapiSystem_547253`, `mbusSystem_18ea34`

## Stakeholders

| Role | Description |
|------|-------------|
| Editorial Team | Writers and editors who create and manage deal copy using the application |
| Engineering Team | gazebo@groupon.com — owns service development, deployment, and operations |
| Product/Merchandising | Stakeholders who define merchandising checklist requirements |
| Salesforce Admins | Maintain CRM data that feeds into Gazebo via sync jobs |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 2.1.2 | `.ruby-version` / `Gemfile` |
| Framework | Rails | 4.1 | `Gemfile` |
| Runtime | Unicorn | 4.8.3 | `Gemfile` |
| Build tool | Bundler / Gulp / Rake | 1.16.6 / 3.9.0 | `Gemfile` / `package.json` / `Rakefile` |
| Package manager | Bundler (Ruby), npm (JS) | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| rails | 4.1 | http-framework | MVC web application |
| unicorn | 4.8.3 | http-framework | Production HTTP server |
| mysql2 | 0.3.0 | db-client | MySQL adapter |
| redis | 3.3.0 | db-client | Redis client for caching and sessions |
| messagebus | 0.2.8 | message-client | Internal Message Bus event publishing and consumption |
| typhoeus | 0.6.5 | http-framework | External HTTP API requests |
| flipper | 0.7.0 | validation | Feature flag management for progressive rollouts |
| restforce | pinned | http-framework | Salesforce CRM API client |
| sonoma-logger | 2.1.0 | logging | Structured application logging |
| newrelic_rpm | 3.7.3.204 | metrics | APM and error tracking via New Relic |
| rspec | 3.1 | testing | Unit and integration tests |
| cucumber | 1.4.4 | testing | BDD acceptance tests |
| kaminari | 0.16.2 | validation | Rails pagination |
| gulp | 3.9.0 | scheduling | Frontend asset build pipeline |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
