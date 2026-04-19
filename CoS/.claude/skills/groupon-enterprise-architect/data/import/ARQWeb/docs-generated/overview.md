---
service: "ARQWeb"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Identity and Access Management"
platform: "Continuum"
team: "Continuum Platform"
status: active
tech_stack:
  language: "Python"
  language_version: "3.x"
  framework: "Flask"
  framework_version: "2.x"
  runtime: "uWSGI"
  runtime_version: "2.x"
  build_tool: "pip / setuptools"
  package_manager: "pip"
---

# ARQWeb Overview

## Purpose

ARQWeb (Access Request Queue Web) is Groupon's internal identity governance and access request platform. It provides a Flask-based web UI and REST APIs that allow employees to request access to systems, managers to approve or reject those requests, and administrators to manage SOX compliance workflows. A companion background worker handles all asynchronous job processing including cron-scheduled tasks, Jira ticket automation, Active Directory group changes, GitHub repository access provisioning, and outbound webhook delivery.

## Scope

### In scope
- Accepting and routing employee access requests via web UI and API
- Multi-step approval workflows including manager and SOX gating
- Onboarding workflow automation for new employees
- Active Directory group membership queries and updates
- GitHub Enterprise team and repository access management (SOX-aligned)
- Jira ticket creation and lifecycle management for access workflows
- Workday employee and manager hierarchy synchronization
- Service Portal metadata and ownership synchronization
- Cyclops SOX role workflow execution
- Scheduled and queued background job execution with retry and timeout handling
- Audit trail recording for all access decisions
- Email notifications (approval requests, reminders, digests) via SMTP relay
- Outbound webhook delivery to registered external consumers
- Elastic APM telemetry for the web app and worker processes

### Out of scope
- Provisioning of application-level permissions within downstream systems (delegated to AD, GitHub, Cyclops)
- Authentication and SSO (handled upstream)
- Employee HR data creation (sourced read-only from Workday)
- Jira project/board administration (only ticket lifecycle management)

## Domain Context

- **Business domain**: Identity and Access Management
- **Platform**: Continuum
- **Upstream consumers**: Internal Groupon employees (web browser), any system submitting access requests via API
- **Downstream dependencies**: Active Directory (LDAP/LDAPS), Service Portal (HTTPS/JSON), Workday (HTTPS), GitHub Enterprise (HTTPS API), Jira (HTTPS API), SMTP relay (SMTP), Cyclops (HTTPS API), Elastic APM (APM agent), external webhook consumers (HTTPS POST)

## Stakeholders

| Role | Description |
|------|-------------|
| Requestor | Groupon employee submitting an access request via the ARQWeb UI or API |
| Approver / Manager | Groupon manager who reviews and approves or rejects access requests |
| Security / SOX Admin | Security or compliance team member managing SOX workflows and audit records |
| Platform Engineer | Engineer operating, deploying, and maintaining the ARQWeb service |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 3.x | architecture/models/components/arqweb-app.dsl |
| Framework | Flask | 2.x | architecture/models/components/arqweb-app.dsl ("Python Flask/uWSGI") |
| Runtime | uWSGI | 2.x | architecture/models/components/arqweb-app.dsl ("Python Flask/uWSGI") |
| Background worker runtime | Python Worker | — | architecture/models/components/arq-worker.dsl ("Python Worker") |
| Build tool | pip / setuptools | — | architecture DSL (Python ecosystem) |
| Package manager | pip | — | architecture DSL (Python ecosystem) |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Flask | 2.x | http-framework | Web application routing, blueprints, and request handling |
| uWSGI | 2.x | http-framework | WSGI application server for production serving |
| psycopg | 2.x/3.x | db-client | PostgreSQL database adapter for request/job/audit data access |
| ldap3 or python-ldap | — | auth | LDAP/LDAPS client for Active Directory group membership operations |
| requests | — | http-client | HTTP client for outbound calls to Service Portal, Workday, GitHub, Jira, Cyclops, webhooks |
| Elastic APM Python agent | — | metrics | Distributed tracing and error telemetry to Elastic APM |
| smtplib / email | — | messaging | Standard library SMTP client for notification and digest emails |
| apscheduler or custom cron | — | scheduling | Cron-style scheduler driving the ARQ Worker loop |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
