---
service: "garvis"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Change Management / DevEx"
platform: "Continuum"
team: "deployment@groupon.com"
status: active
tech_stack:
  language: "Python"
  language_version: "3.13"
  framework: "Django / Flask"
  framework_version: "6.0 / 3.1.2"
  runtime: "Gunicorn"
  runtime_version: ""
  build_tool: "pip"
  package_manager: "pip"
---

# Garvis (Jarvis) Overview

## Purpose

Garvis (internally named Jarvis) is a Google Chat bot that automates Change Management, Operations, and Developer Experience workflows at Groupon. It listens for commands and events via Google Cloud Pub/Sub, dispatches work to background RQ workers, and integrates with JIRA, PagerDuty, GitHub, Google Drive, Google Calendar, and ProdCAT to orchestrate change approvals, incident response, on-call lookups, and scheduled notifications. The service replaces manual coordination across multiple tools with a single conversational interface inside Google Chat.

## Scope

### In scope

- Receiving and routing Google Chat messages via Pub/Sub subscription
- Change approval workflow automation (creating, tracking, and closing change tickets)
- Incident response orchestration (JIRA incident creation, PagerDuty escalation, status updates)
- On-call engineer lookup and notification through PagerDuty and Google Chat
- Background job scheduling and execution via RQ workers and RQ Scheduler
- Administrative UI and monitoring via Django admin and django-rq dashboard
- Service health and ORR (Operational Readiness Review) status surfacing via ProdCAT integration

### Out of scope

- Consumer-facing or merchant-facing commerce flows (handled by Continuum platform services)
- Direct CI/CD pipeline execution (GitHub integration is read/query only)
- Authoring or storing source documentation (Google Drive/Docs integration is read/coordinate only)
- PagerDuty policy management (Garvis reads schedules and triggers alerts; policy admin is done in PagerDuty directly)

## Domain Context

- **Business domain**: Change Management / DevEx
- **Platform**: Continuum
- **Upstream consumers**: Google Chat users (engineers, on-call responders, release managers) via Google Chat spaces and direct messages
- **Downstream dependencies**: Google Cloud Pub/Sub, Google Chat API, JIRA, PagerDuty, GitHub, Google Drive/Docs/Calendar, ProdCAT, Service Health/ORR, PostgreSQL, Redis

## Stakeholders

| Role | Description |
|------|-------------|
| Change Management team | Service owners; manage deployment approval workflows and bot configuration (deployment@groupon.com) |
| On-call engineers | Primary end users; interact with Jarvis in Google Chat for incident and on-call tasks |
| Release managers | Use change approval workflow to track and approve deployment changes |
| Platform/DevEx team | Consumers of background job scheduling and service health features |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 3.13 | Inventory |
| Framework (web) | Django | 6.0 | Inventory |
| Framework (API) | Flask | 3.1.2 | Inventory |
| HTTP server | Gunicorn | — | Inventory |
| Build tool | pip | — | Inventory |
| Package manager | pip | — | Inventory |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| google-cloud-pubsub | 2.34.0 | message-client | Subscribes to Google Chat events from Pub/Sub topics |
| redis | 7.1.0 | db-client | Redis client for cache access and RQ job queue backend |
| rq | 2.6.1 | scheduling | Background job queue; dispatches async work to workers |
| psycopg2-binary | 2.9.11 | db-client | PostgreSQL adapter for Django ORM |
| PyGithub | — | http-framework | GitHub API client for repository and PR queries |
| pdpyras | — | http-framework | PagerDuty REST API client for on-call and incident operations |
| jira | — | http-framework | JIRA REST API client for ticket creation and updates |
| google-api-python-client | — | http-framework | Google Workspace SDK for Drive, Docs, Calendar, and Chat APIs |
| requests | 2.32.5 | http-framework | General-purpose HTTP client for outbound REST calls |
| Tailwind CSS | 3.4.1 | ui-framework | Utility-first CSS framework for the admin/operator UI |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
