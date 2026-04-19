---
service: "mdi-dashboard-v2"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Marketing / Merchandising / Deal Intelligence"
platform: "Continuum"
team: "Marketing Engineering"
status: active
tech_stack:
  language: "JavaScript/CoffeeScript"
  language_version: "CoffeeScript 1.10 / ES5"
  framework: "Express"
  framework_version: "4.14"
  runtime: "Node.js"
  runtime_version: "6.12.2"
  build_tool: "Gulp"
  build_tool_version: "3.8.8"
  package_manager: "npm"
---

# Marketing Deal Intelligence Dashboard Overview

## Purpose

mdi-dashboard-v2 (Marketing Deal Intelligence Dashboard) is an internal web application that provides Marketing and Merchandising teams with deal search, clustering analytics, merchant performance insights, and feed management capabilities. It aggregates data from multiple Continuum platform services and presents a unified interface for deal lifecycle management and marketplace intelligence. It also manages API key provisioning and provides tools for building and generating deal feed exports.

## Scope

### In scope

- Deal search and browsing across the Groupon catalog via the `/browser` endpoint
- Deal cluster analytics and grouping via the `/clusters` endpoint
- Merchant performance and insights reporting via the `/merchantInsights` endpoint
- API key creation, management, and revocation via the `/keys` endpoint
- Feed builder CRUD operations and feed generation via the `/feeds` endpoint
- Taxonomy, city, and location search via the `/search/*` endpoints
- Relevance scoring integration via the `/rapi` endpoint
- Deal options lookup via the `/options/:id` endpoint
- JIRA ticket creation for deal-related issues
- Salesforce CRM data integration for merchant context

### Out of scope

- Deal catalog ownership and storage (owned by `continuumDealCatalogService`)
- Voucher inventory management (owned by `continuumVoucherInventoryService`)
- Taxonomy data ownership (owned by `continuumTaxonomyService`)
- Relevance scoring computation (owned by `continuumRelevanceApi`)
- Feed data ingestion and processing (owned by `continuumMdsFeedService`)
- Customer-facing deal browsing (handled by MBNXT / storefront services)

## Domain Context

- **Business domain**: Marketing / Merchandising / Deal Intelligence
- **Platform**: Continuum
- **Upstream consumers**: Internal Marketing and Merchandising team members (browser-based UI); API Proxy for programmatic access
- **Downstream dependencies**: Marketing Deal Service, Relevance API, Deal Catalog, Voucher Inventory, Taxonomy Service, Deals Cluster API, MDS Feed Service, Salesforce, JIRA, API Proxy

## Stakeholders

| Role | Description |
|------|-------------|
| Marketing Analyst | Uses deal search and cluster analytics to evaluate marketplace performance |
| Merchandising Manager | Uses merchant insights and feed management for campaign operations |
| Marketing Engineer | Develops and maintains the dashboard and its integrations |
| Platform / API Consumer | Uses API key management to obtain programmatic access to deal intelligence data |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript/CoffeeScript | CoffeeScript 1.10 | package.json |
| Framework | Express | 4.14 | package.json |
| Server Framework | itier-server | 5.4.1 | package.json |
| Runtime | Node.js | 6.12.2 | package.json / .nvmrc |
| Build tool | Gulp | 3.8.8 | package.json / Gulpfile |
| Package manager | npm | — | package.json |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| express | 4.14 | http-framework | HTTP server and routing |
| itier-server | 5.4.1 | http-framework | Groupon i-tier application server wrapper |
| itier-user-auth | 4.3.1 | auth | Groupon internal user authentication |
| coffee-script | 1.10 | language | CoffeeScript transpiler |
| sequelize | 2.0.5 | orm | PostgreSQL ORM for feed and key persistence |
| keldor | 7.0.1 | http-client | Groupon internal HTTP client framework |
| gofer | 2.1.0 | http-client | HTTP service client with metrics support |
| hogan.js | 3.0.2 | ui-framework | Mustache-compatible server-side templating |
| jira | 0.9.2 | http-client | JIRA REST API client |
| gulp | 3.8.8 | build | Task runner for asset compilation and build |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
