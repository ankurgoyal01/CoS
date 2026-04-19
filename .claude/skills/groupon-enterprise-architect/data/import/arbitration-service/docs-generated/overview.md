---
service: "arbitration-service"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Marketing Delivery — Push Campaign Arbitration"
platform: "Continuum"
team: "Messaging / Marketing Delivery Platform"
status: active
tech_stack:
  language: "Go"
  language_version: "1.19"
  framework: "Martini"
  framework_version: "latest"
  runtime: "Go"
  runtime_version: "1.19"
  build_tool: "Go modules"
  package_manager: "Go modules (go.mod)"
---

# Arbitration Service (ABS) Overview

## Purpose

The Arbitration Service (ABS) is the central decisioning engine for Groupon's Marketing Delivery platform. It receives campaign delivery requests from marketing delivery clients and applies best-for selection, quota enforcement, and frequency capping to determine the single winning push campaign (email or push notification) to deliver to a given user. It also manages delivery rule lifecycle and revoke workflows for previously committed sends.

## Scope

### In scope

- Best-for campaign selection: filtering eligible campaigns per user based on eligibility rules, send history, and frequency caps
- Arbitration decisioning: applying quota enforcement, winner selection, and de-duplication across candidate campaigns
- Frequency cap enforcement: tracking and enforcing per-user send limits using Cassandra history and Redis counters
- Delivery rule management: CRUD operations for delivery rules and associated approval workflow integration
- Campaign revoke: marking previously committed sends as revoked and adjusting counters
- Experiment configuration management: fetching, caching, and refreshing Optimizely experiment definitions
- Startup cache preloading: reducing cold-start latency by loading rules and config at service start

### Out of scope

- Actual campaign content rendering or message assembly
- Email or push notification dispatch (handled by downstream delivery systems)
- User profile management or audience segmentation
- Campaign creation or creative management

## Domain Context

- **Business domain**: Marketing Delivery — Push Campaign Arbitration
- **Platform**: Continuum
- **Upstream consumers**: `marketingDeliveryClients` — marketing delivery systems that invoke best-for, arbitrate, and revoke APIs
- **Downstream dependencies**: `absPostgres` (campaign metadata, delivery rules), `absCassandra` (send history, frequency caps), `absRedis` (decisioning counters), `optimizelyService` (experiment definitions), `continuumJiraService` (approval workflow tickets), `notificationEmailService` (operational notifications), `telegrafMetrics` (metrics)

## Stakeholders

| Role | Description |
|------|-------------|
| Messaging / Marketing Delivery Platform | Owning team responsible for service development and operations |
| Marketing campaign operators | Configure delivery rules and manage campaign approval workflows |
| Downstream delivery systems | Consume arbitration decisions to dispatch campaigns |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Go | 1.19 | go.mod |
| Framework | Martini | latest | go.mod — github.com/go-martini/martini |
| Runtime | Go | 1.19 | go.mod |
| Build tool | Go modules | — | go.mod |
| Package manager | Go modules | — | go.mod |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| github.com/go-martini/martini | latest | http-framework | HTTP routing and middleware |
| gocql | latest | db-client | Cassandra client |
| database/sql + lib/pq | stdlib + latest | db-client | PostgreSQL client |
| github.com/go-redis/redis | v8 | db-client | Redis client |
| go.uber.org/zap | v1.x | logging | Structured logging |
| github.com/optimizely/go-sdk | latest | feature-flags | Experimentation integration |
| gopkg.in/yaml.v3 | latest | config | YAML config parsing |
| encoding/json | stdlib | serialization | JSON request/response |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
