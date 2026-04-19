---
service: "email_campaign_management"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Email Campaign Management"
platform: "Continuum"
team: "Campaign Management / PMP"
status: active
tech_stack:
  language: "CoffeeScript / JavaScript"
  language_version: "ES5/CS2"
  framework: "Express"
  framework_version: "3.17"
  runtime: "Node.js"
  runtime_version: "16.13.0"
  build_tool: "npm"
  package_manager: "npm"
---

# CampaignManagement Overview

## Purpose

CampaignManagement (repo: `email_campaign_management`) is a Node.js/CoffeeScript REST API service that manages the full lifecycle of email and push notification campaigns at Groupon, supporting send volumes of 70M+ messages. It owns campaign creation, audience targeting via deal queries, program-based send routing, and orchestration of pre-send validation (preflight) before handing off to downstream delivery services. The service acts as the authoritative source of truth for campaign metadata, send records, and business group configurations within the Continuum platform.

## Scope

### In scope

- Campaign CRUD: creation, configuration, update, rollout of treatment variants, and archival
- Deal query management: defining and resolving audience targeting rules (geo, deal type, division)
- Campaign send record management: tracking individual send attempts and statuses
- Business group and program lifecycle management
- Event type catalog management for campaign taxonomy
- Calendar endpoint for send scheduling metadata
- Preflight validation: dry-run campaign send checks against Rocketman before commit
- Experimentation integration via Expy for A/B treatment rollouts
- Deal assignment file ingestion from Google Cloud Storage / HDFS

### Out of scope

- Actual email/push message delivery (handled by Rocketman)
- Audience membership evaluation (handled by RTAMS)
- User device token resolution (handled by Token Service)
- Geographic metadata storage (handled by GeoPlaces)
- Runtime feature flag evaluation beyond GConfig lookups
- Front-end campaign management UI

## Domain Context

- **Business domain**: Email Campaign Management
- **Platform**: Continuum
- **Upstream consumers**: Internal campaign orchestrators and campaign API clients (not modeled in federated workspace; tracked in central architecture model)
- **Downstream dependencies**: Rocketman (delivery), RTAMS (audience), GeoPlaces (geo metadata), Token Service (device tokens), GConfig (runtime config), Expy (experimentation), Google Cloud Storage (deal files), HDFS (deal file archive), PostgreSQL (primary store), Redis (deal query cache)

## Stakeholders

| Role | Description |
|------|-------------|
| Campaign Management / PMP Team | Owns service development, deployment, and operations |
| Email Marketing | Business stakeholder that configures and launches campaigns |
| Platform Engineering | Maintains integrations with Rocketman, RTAMS, and Expy |
| Data Engineering | Consumes HDFS deal assignment files produced by upstream pipelines |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | CoffeeScript / JavaScript | CS2 / ES5 | Source inventory |
| Framework | Express | 3.17 | package.json |
| Runtime | Node.js | 16.13.0 | package.json engines |
| Build tool | npm | — | package.json |
| Package manager | npm | — | package-lock.json |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| express | 3.17 | http-framework | HTTP server and routing |
| pg | 8.7.1 | db-client | PostgreSQL access |
| redis | 2.4.2 | db-client | Redis cache client |
| async | 2.3.0 | scheduling | Async control flow utilities |
| winston | 3.3.3 | logging | Structured application logging |
| influxdb-nodejs | 3.0.0 | metrics | InfluxDB metrics emission |
| @grpn/expy.js | 1.1.2 | http-framework | Expy experimentation SDK |
| webhdfs | 1.1.1 | http-framework | HDFS WebHDFS REST client |
| nodemailer | 2.1.x | http-framework | SMTP/email preflight utility |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
