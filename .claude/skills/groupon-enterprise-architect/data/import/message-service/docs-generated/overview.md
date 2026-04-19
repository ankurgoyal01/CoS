---
service: "message-service"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "CRM / Messaging"
platform: "Continuum"
team: "crm-eng (is-ms-engg@groupon.com)"
status: active
tech_stack:
  language: "Java"
  language_version: ""
  framework: "Play Framework"
  framework_version: "2.2.2"
  runtime: "JVM"
  runtime_version: ""
  build_tool: "SBT"
  package_manager: "npm (UI)"
---

# CRM Message Service Overview

## Purpose

The CRM Message Service (message-service) is the Continuum platform's central engine for delivering promotional and operational message banners, in-app notifications, and campaign content to users across web, mobile, and email channels. It manages the full lifecycle of a messaging campaign — from creation and audience targeting through delivery and analytics — and processes batch audience assignments to ensure the right message reaches the right user at the right time.

## Scope

### In scope

- Creating, configuring, and approving messaging campaigns via REST API and admin UI
- Evaluating targeting constraints and selecting eligible messages for a given user request
- Delivering message data via `/api/getmessages` (web/mobile) and `/api/getemailmessages` (email channel)
- Recording user interaction events via `/api/messageevent`
- Managing campaign audience assignments through batch Akka actor jobs
- Consuming scheduled audience refresh events from Kafka and triggering assignment rebuilds
- Publishing campaign metadata to MBus for downstream consumption
- Scaling Bigtable read/write capacity via the `/api/bigtable/scale` control endpoint
- Serving the React/Ant Design campaign management UI at `/campaign/*`

### Out of scope

- Rendering email content or dispatching email messages (handled by Email Campaign Management service)
- User authentication and identity resolution (handled by upstream callers)
- Audience segmentation and cohort definition (handled by AMS / Real-time Audience service)
- Incentive computation (handled by Incentive service)
- Experiment assignment and feature-flag evaluation (handled by Finch/Optimizely/Birdcage)

## Domain Context

- **Business domain**: CRM / Messaging
- **Platform**: Continuum
- **Upstream consumers**: Mobile apps, web frontends, email pipeline, internal campaign managers
- **Downstream dependencies**: AMS (audience validation), Taxonomy service (targeting), Geo service (geo metadata), Email Campaign Management (email metadata), GIMS (image assets), MBus (event bus), EDW (analytics), GCP Storage / HDFS (audience export files)

## Stakeholders

| Role | Description |
|------|-------------|
| crm-eng team | Service owners and developers (is-ms-engg@groupon.com) |
| Campaign managers | Internal users who create and approve campaigns via the UI |
| Mobile/Web teams | Consumers of `/api/getmessages` for rendering banners and notifications |
| Email pipeline | Consumer of `/api/getemailmessages` for populating email templates |
| Data/Analytics | Consumers of campaign metadata published to MBus and EDW |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | — | models/components/messaging-service-components.dsl |
| Framework | Play Framework | 2.2.2 | Summary (SBT project) |
| Batch/Actor system | Akka Actors | (bundled with Play 2.2.x) | messagingAudienceImportJobs component |
| Build tool | SBT | — | Summary |
| UI Language | Node.js | 14 | Summary |
| UI Framework | React | 16.14 | Summary |
| UI Component library | Ant Design | 4.19.5 | Summary |
| UI Build | Webpack | — | Summary |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Play Framework | 2.2.2 | http-framework | REST endpoint handling, routing, DI |
| Akka Actors | (Play 2.2.x bundled) | scheduling | Batch audience import jobs |
| Kafka Client | — | message-client | Consuming ScheduledAudienceRefreshed events |
| MBus Client | — | message-client | Publishing CampaignMetaData events |
| React | 16.14 | ui-framework | Campaign management UI |
| Ant Design | 4.19.5 | ui-framework | UI component library for campaign admin |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
