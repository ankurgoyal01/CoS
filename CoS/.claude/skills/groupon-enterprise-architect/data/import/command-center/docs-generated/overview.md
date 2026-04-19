---
service: "command-center"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Internal Operations / Bulk Support Tooling"
platform: "Continuum"
team: "Continuum Platform"
status: active
tech_stack:
  language: "Ruby"
  language_version: ""
  framework: "Ruby on Rails"
  framework_version: ""
  runtime: "Ruby"
  runtime_version: ""
  build_tool: "Bundler"
  package_manager: "Bundler / RubyGems"
---

# Command Center Overview

## Purpose

Command Center is Groupon's internal bulk support tooling and operational workflows platform. It provides operations and support teams with structured, auditable tools for performing large-scale mutations to deals, orders, vouchers, merchant places, and related commerce data. The service separates synchronous request validation and scheduling from asynchronous batch execution, ensuring high-volume operations do not degrade user-facing systems.

## Scope

### In scope

- Hosting and executing internal operational tools for deal, order, voucher, and place management
- Scheduling and managing asynchronous background jobs via Delayed Job
- Storing job metadata, execution logs, audit records, and report artifacts in MySQL
- Delivering workflow status and result notifications via email
- Integrating synchronously with downstream platform APIs to read current state before mutations
- Publishing and consuming workflow events via the message bus
- Storing and retrieving CSV job artifacts in object storage (S3)

### Out of scope

- Consumer-facing deal browsing or purchase flows (handled by commerce services)
- Merchant self-service portal (handled by Merchant Center)
- Deal creation workflows (handled by Deal Management API and Deal Catalog Service)
- Order payment processing (handled by Payments/Orders services)
- Direct database mutations outside of sanctioned tool workflows

## Domain Context

- **Business domain**: Internal Operations / Bulk Support Tooling
- **Platform**: Continuum
- **Upstream consumers**: Internal operations and support staff accessing the web UI
- **Downstream dependencies**: Deal Catalog Service, Deal Management API, Voucher Inventory Service, Orders Service, M3 Places Service, Salesforce, Message Bus, Cloud Platform (S3)

## Stakeholders

| Role | Description |
|------|-------------|
| Operations / Support Staff | Primary users of tooling workflows via the web UI |
| Continuum Platform Team | Service owners responsible for tooling correctness and reliability |
| Merchant Operations | Consumers of place and deal mutation tools |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | — | architecture/models/components/command-center-web-components.dsl |
| Framework | Ruby on Rails | — | Container description: "Ruby on Rails" |
| Background Jobs | Delayed Job | — | architecture/models/components/command-center-worker-components.dsl |
| Build tool | Bundler | — | Standard Ruby on Rails convention |
| Package manager | RubyGems / Bundler | — | Standard Ruby on Rails convention |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| ActionController | — | http-framework | Handles HTTP requests for internal tooling endpoints and dashboards |
| ActionRecord (ActiveRecord) | — | orm | ORM for tool, user, job, and queue state persistence |
| delayed_job | — | scheduling | Background job queue and worker runtime |
| HTTParty / Typhoeus | — | http-client | HTTP clients for downstream platform API calls |
| ActionMailer | — | messaging | Composes and sends workflow status and failure notifications |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
