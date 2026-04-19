---
service: "service-portal"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Engineering Governance"
platform: "Continuum"
team: "Service Portal Team (service-portal-team@groupon.com)"
status: active
tech_stack:
  language: "Ruby"
  language_version: "3.4.5"
  framework: "Rails"
  framework_version: "8.0.2.1"
  runtime: "Puma"
  runtime_version: ""
  build_tool: "Bundler"
  package_manager: "Bundler / RubyGems"
---

# Service Portal Overview

## Purpose

Service Portal is Groupon's internal platform for service catalog management, engineering governance, and Operational Readiness Review (ORR) automation. It provides a single source of truth for all registered engineering services, tracks their metadata, dependencies, costs, and operational health checks. The platform enforces governance standards by running automated checks against each registered service and providing structured ORR workflows to ensure services meet production readiness criteria.

## Scope

### In scope

- Service registration and catalog management (CRUD on service records)
- Service metadata management (ownership, tier, technology, links)
- Dependency graph tracking between services
- Automated operational readiness checks (scheduled and on-demand)
- Operational Readiness Review (ORR) workflow management
- Cost tracking and alerting per service
- GitHub repository validation and sync via webhooks
- Service inactivity detection and reporting
- Service attribute management (legacy v1 API)
- `service.yml` validation endpoint for CI use

### Out of scope

- Source code hosting or repository management (delegated to GitHub Enterprise)
- Deployment orchestration (handled by Jenkins / Kubernetes)
- Centralized logging or metrics aggregation (handled by Elasticsearch / Sonoma)
- Identity and access management beyond Google Directory group lookups

## Domain Context

- **Business domain**: Engineering Governance
- **Platform**: Continuum
- **Upstream consumers**: Engineering teams registering services, CI pipelines validating `service.yml`, internal tooling querying the service catalog
- **Downstream dependencies**: GitHub Enterprise (webhook events and REST API), Google Chat (notifications), Google Directory (team/ownership lookups), Jira Cloud (ORR issue tracking, stub), Elasticsearch (search/reporting, stub), MySQL (primary data store), Redis (job queuing and caching)

## Stakeholders

| Role | Description |
|------|-------------|
| Service Portal Team | Owners and maintainers of the platform (service-portal-team@groupon.com) |
| Engineering teams | Consumers who register and maintain service records |
| Engineering leadership | Consumers of ORR status and cost reports |
| Platform / SRE teams | Consumers of health check results and dependency graphs |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 3.4.5 | `.ruby-version` / `Gemfile` |
| Framework | Rails | 8.0.2.1 | `Gemfile.lock` |
| Runtime | Puma | latest compatible | `Gemfile` |
| Build tool | Bundler | system | `Gemfile` |
| Package manager | RubyGems / Bundler | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| rails | 8.0.2 | http-framework | Full-stack web framework (routing, ORM, mailers) |
| puma | latest | http-framework | Multi-threaded HTTP server |
| sidekiq | < 7.2 | scheduling | Background job processing |
| sidekiq-cron | latest | scheduling | Cron-style scheduling of recurring Sidekiq jobs |
| redis | 5.0.0 | db-client | Redis client for job queuing and caching |
| mysql2 | latest | db-client | MySQL adapter for ActiveRecord |
| faraday | 2.0.1 | http-framework | HTTP client for outbound REST calls (GitHub, Jira, etc.) |
| google-apis-admin_directory_v1 | latest | auth | Google Directory API client for team/ownership lookups |
| google-apis-chat_v1 | latest | message-client | Google Chat API client for notifications |
| elastic-apm | latest | metrics | Elastic APM agent for distributed tracing |
| sonoma-metrics | 0.10.0 | metrics | Groupon-internal metrics emission library |
| sonoma-logger | 3.1.0 | logging | Groupon-internal structured logging library |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
