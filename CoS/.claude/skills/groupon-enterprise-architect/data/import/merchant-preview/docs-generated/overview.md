---
service: "merchant-preview"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Deal Management / Merchant Experience"
platform: "continuum"
team: "Continuum Platform"
status: active
tech_stack:
  language: "Ruby"
  language_version: ""
  framework: "Ruby on Rails"
  framework_version: ""
  runtime: "Ruby"
  runtime_version: ""
  build_tool: "Rake"
  package_manager: "Bundler"
---

# Merchant Preview Overview

## Purpose

Merchant Preview is a Ruby on Rails web service that enables merchants and Groupon account managers (sales reps) to view deal creative content before it is published. It provides a structured comment and approval workflow so that feedback can be tracked, resolved, and synced to Salesforce, ensuring deal creatives meet merchant expectations prior to going live.

## Scope

### In scope

- Serving merchant and account manager deal preview pages
- Creating, updating, and resolving comments on deal creative
- Merchant approval and rejection of deal creative
- Sending transactional email notifications via SMTP for preview activity
- Synchronizing comment and approval state with Salesforce Opportunity and Task records
- Scheduled background sync of unresolved comments and workflow records to Salesforce

### Out of scope

- Authoring or editing deal creative content (owned by Deal Catalog Service)
- Deal publication and go-live workflow (owned by downstream publishing services)
- Salesforce CRM user provisioning and account management

## Domain Context

- **Business domain**: Deal Management / Merchant Experience
- **Platform**: Continuum
- **Upstream consumers**: Merchants (via Akamai CDN public URL), Sales reps / account managers (via internal gateway)
- **Downstream dependencies**: `continuumDealCatalogService`, `salesForce`, `smtpRelay`, `loggingStack`, `metricsStack`, `tracingStack`

## Stakeholders

| Role | Description |
|------|-------------|
| Merchant | External business partner reviewing and approving deal creative |
| Sales Representative / Account Manager | Internal Groupon user coordinating deal review with merchant |
| Deal Operations | Team responsible for deal quality and publication readiness |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | — | `architecture/models/components/continuumMerchantPreviewService.dsl` |
| Framework | Ruby on Rails | — | `architecture/models/components/continuumMerchantPreviewService.dsl` |
| Runtime | Ruby | — | `architecture/models/containers.dsl` |
| Build tool | Rake | — | `architecture/models/containers.dsl` (cron worker: "Ruby (Rake/Cron)") |
| Package manager | Bundler | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| ActionMailer | — | messaging | Preview email delivery and template rendering |
| databasedotcom | — | http-framework | Salesforce REST API client used by Salesforce API Client component |
| Rake | — | scheduling | Background cron task execution for Salesforce sync worker |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
