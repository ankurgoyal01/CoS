---
service: "raas_c1"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Infrastructure / Redis Operations"
platform: "Continuum"
team: "raas-team (raas-team@groupon.com)"
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

# RAAS C1 (Redis as a Service — C1) Overview

## Purpose

RAAS C1 is a Service Portal registration entry — not a deployable application — created specifically to satisfy a limitation in Groupon's OCT tooling, which cannot associate two BASTIC tickets with a single service entry. The broader RaaS platform required two Service Portal records to correctly represent its C1 and C2 colocation deployments; `raas_c1` covers C1 Redis nodes (snc1, sac1, dub1 colos). The actual Redis cluster management logic lives in the parent `raas` platform and the `redislabs_config` service.

## Scope

### In scope

- Providing a Service Portal identity for the C1 colo Redis nodes (snc1, sac1, dub1)
- Enabling internal tooling (BASTIC/OCT) to route requests and manage tickets for the C1 Redis deployment
- Registering internal base URLs for C1 production environments
- Declaring the `raas_dns` dependency for internal service discovery

### Out of scope

- Actual Redis cluster management (owned by the `raas` platform)
- Redis configuration management (owned by `redislabs_config`)
- Application-level Redis client configuration (owned by consuming services)
- Any deployable application code — this entry carries no runtime process

## Domain Context

- **Business domain**: Infrastructure / Redis Operations
- **Platform**: Continuum
- **Upstream consumers**: Internal OCT tooling, BASTIC ticketing system — consumers interacting with the C1 Service Portal entry for routing and operational management
- **Downstream dependencies**: `raas_dns` (internal DNS service discovery)

## Stakeholders

| Role | Description |
|------|-------------|
| Team | raas-team — owner: pablo; members: pablo, ksatyamurthy, kbandaru; raas-team@groupon.com |
| SRE / On-call | raas-pager@groupon.com; PagerDuty: https://groupon.pagerduty.com/services/PTK0O0E |
| Operators | Engineers managing C1 Redis infrastructure using the Service Portal entry for ticketing and tooling |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Service Portal | Service Portal registration | 4 (schema version) | `.service.yml` |

> This entry is a Service Portal metadata record, not a deployed application. No language, framework, runtime, or build tool applies. All Redis management logic is implemented in the `raas` platform.

### Key Libraries

> Not applicable — this is a Service Portal registration entry with no application code.
