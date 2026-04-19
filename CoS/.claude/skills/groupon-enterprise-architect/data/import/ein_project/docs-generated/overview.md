---
service: "ein_project"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Production Change Management"
platform: "Continuum"
team: "Jarvis (deployment@groupon.com)"
status: active
tech_stack:
  language: "Python"
  language_version: "3.12"
  framework: "Django"
  framework_version: "5.2.6"
  runtime: "Gunicorn"
  runtime_version: "23.0.0"
  build_tool: "pip"
  package_manager: "pip"
---

# ProdCat (ein_project) Overview

## Purpose

ProdCat (Production Change Approval Tool) is Groupon's deployment compliance gateway. It enforces change-management policies by evaluating every deployment request against approval rules, region lock state, active incident conditions, and linked JIRA ticket status before authorizing a deployment to proceed. The service exists to reduce unplanned outages caused by deployments during freeze windows, active incidents, or unapproved change windows.

## Scope

### In scope

- Accepting and persisting change requests submitted by deployment tooling
- Evaluating change requests against approval policies and change windows
- Enforcing region locks triggered by active PagerDuty/JSM incidents
- Integrating with JIRA Cloud to validate and update deployment tickets
- Detecting and logging DeployBot override attempts
- Providing a read API for change log audit trail
- Scheduling and executing background jobs: logbook closure, incident monitoring, queue maintenance
- Sending deployment notifications to Google Chat
- Serving health and heartbeat checks for liveness probes

### Out of scope

- Executing or triggering deployments (performed by external deployment tooling)
- Incident creation or resolution (owned by PagerDuty/JSM)
- JIRA project administration
- Service configuration management (validated via Service Portal but not owned here)

## Domain Context

- **Business domain**: Production Change Management
- **Platform**: Continuum
- **Upstream consumers**: Deployment tooling (DeployBot / CI pipelines), engineers submitting change requests via the web UI
- **Downstream dependencies**: JIRA Cloud, Jira Service Management (JSM), Google Chat, Wavefront, Service Portal, GitHub, PagerDuty, PostgreSQL (Cloud SQL), Redis (Memorystore)

## Stakeholders

| Role | Description |
|------|-------------|
| Production Change Management team | Service owner; defines approval policies and change window rules |
| Jarvis team (deployment@groupon.com) | Engineering team responsible for development and operations |
| Release engineers | Primary users submitting and approving change requests |
| On-call engineers | Consumers of region lock and incident monitor outputs |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 3.12 | Summary inventory |
| Framework | Django | 5.2.6 | Summary inventory |
| Runtime | Gunicorn | 23.0.0 | Summary inventory |
| Build tool | pip | — | Summary inventory |
| Package manager | pip | — | Summary inventory |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| djangorestframework | 3.16.1 | http-framework | REST API serialization, viewsets, and routing |
| psycopg2-binary | 2.9.10 | db-client | PostgreSQL database driver |
| redis | 6.4.0 | db-client | Redis client for caching, sessions, and RQ queue |
| rq | 2.6.0 | scheduling | Redis-backed background job queue |
| rq-scheduler | 0.14.0 | scheduling | Cron-style scheduling of RQ jobs |
| jira | 3.10.5 | http-framework | JIRA Cloud REST API v3 client |
| pdpyras | 5.4.1 | http-framework | PagerDuty REST API client |
| requests | 2.32.5 | http-framework | Generic HTTP client for Service Portal and other REST calls |
| slack-sdk | 3.36.0 | http-framework | Slack/Google Chat notification delivery |
| google-api-python-client | 2.181.0 | http-framework | Google API client (Google Chat integration) |
| wavefront-api-client | 2.202.2 | metrics | Wavefront metrics reporting |
| pygithub | 2.8.1 | http-framework | GitHub API client for deployment metadata |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
