---
service: "booster"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Search & Relevance"
platform: "Continuum"
team: "relevance-engineering@groupon.com"
status: active
tech_stack:
  language: "N/A"
  language_version: "N/A"
  framework: "N/A"
  framework_version: "N/A"
  runtime: "N/A"
  runtime_version: "N/A"
  build_tool: "N/A"
  package_manager: "N/A"
---

# Booster Overview

## Purpose

Booster is an external SaaS relevance engine operated by the company Data Breakers. It provides primary search and deal-ranking capabilities used across Groupon's consumer discovery experience. Groupon's Continuum platform calls Booster APIs over HTTPS to obtain ranked deal recommendations that are served to consumers browsing deals on the platform.

## Scope

### In scope
- Providing ranked and personalized deal recommendations via HTTPS API
- Processing relevance signals to order deal results for consumer discovery
- Serving as the primary ranking backend for Groupon's search and discovery flows

### Out of scope
- Deal catalog management (owned by `continuumDealCatalogService`)
- Marketing deal enrichment (owned by `continuumMarketingDealService`)
- Internal Lazlo-based search enrichment (owned by `continuumApiLazloService`)
- Consumer-facing API routing (handled by `apiProxy` and `continuumRelevanceApi`)
- Integration boundary health monitoring (managed by `continuumBoosterService`)

## Domain Context

- **Business domain**: Search & Relevance
- **Platform**: Continuum (Booster is an external SaaS dependency)
- **Upstream consumers**: `continuumRelevanceApi` calls Booster on the critical consumer request path; `continuumSystem` and `encoreSystem` both declare a system-level dependency on Booster
- **Downstream dependencies**: None — Booster is a leaf external SaaS with no further Groupon-owned downstream services

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | ibeliaev |
| Engineering Team | relevance-engineering@groupon.com |
| Vendor | Data Breakers (external company providing and operating the Booster product) |
| On-call / SRE | PagerDuty service PPPC7X8; Slack channel C04779SKR8T; GChat space AAAA6Qw3NOM |

## Tech Stack

### Core

> Not applicable — Booster is an external SaaS operated entirely by Data Breakers. Groupon does not own or deploy the Booster service. The Groupon-owned integration boundary is represented in the Continuum architecture model as `continuumBoosterService`.

### Key Libraries

> Not applicable — no Groupon-owned source code for Booster exists in this repository. The integration contract, health monitoring, and support runbook are modeled as components within `continuumBoosterService`.
