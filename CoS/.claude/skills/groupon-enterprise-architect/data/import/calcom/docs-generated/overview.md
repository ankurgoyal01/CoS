---
service: "calcom"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Calendar Scheduling Infrastructure"
platform: "Continuum"
team: "Conveyor"
status: active
tech_stack:
  language: "TypeScript"
  language_version: ""
  framework: "Next.js"
  framework_version: ""
  runtime: "Node.js"
  runtime_version: ""
  build_tool: "Docker"
  package_manager: "npm"
---

# Calcom Overview

## Purpose

Calcom is Groupon's internally deployed instance of [Cal.com](https://cal.com/) (formerly Calendso), a third-party open-source scheduling platform. It provides calendar scheduling infrastructure that allows Groupon users and customers to book, manage, and receive notifications for meetings. The service is deployed to Kubernetes in both AWS (us-west-1) and GCP (us-central1) and is accessible publicly at `https://meet.groupon.com`.

## Scope

### In scope

- Hosting and operating the Cal.com scheduling web application within Groupon's Kubernetes infrastructure
- Serving the Booking UI for meeting scheduling and availability management
- Processing scheduling API requests: booking creation, availability queries, and calendar synchronization
- Managing user authentication, session tokens, and access control
- Orchestrating confirmation and reminder email and notification dispatch via Gmail SMTP
- Background job processing for asynchronous scheduling workflows (reminders, follow-ups) via the Worker service
- Maintaining scheduling, account, and configuration data in GDS-managed PostgreSQL databases

### Out of scope

- Core Cal.com product development (upstream open-source project maintained by Cal.com)
- Email infrastructure (handled by Gmail SMTP / `gmailSmtpService`)
- Kubernetes cluster management and database provisioning (handled by the Conveyor and GDS teams respectively)
- User management via UI (paid Cal.com feature; admin changes require direct database access)

## Domain Context

- **Business domain**: Calendar Scheduling Infrastructure
- **Platform**: Continuum
- **Upstream consumers**: Groupon users via browser (`calcomClientBrowser`), administrators via browser (`calcomAdminBrowser`)
- **Downstream dependencies**: GDS-managed PostgreSQL (`continuumCalcomPostgres`), Gmail SMTP (`gmailSmtpService`), `continuumCalcomWorkerService` (internal job queue)

## Stakeholders

| Role | Description |
|------|-------------|
| Conveyor Team | Owns and operates the service; contact: conveyor-team@groupon.com |
| Service Owner | c_agrecu |
| GDS Team | Manages and monitors PostgreSQL databases |
| End Users | Groupon users who schedule meetings at meet.groupon.com |
| Administrators | Internal Groupon staff who administer the Cal.com instance |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Container Image | calcom/cal.com | v4.3.5 | `Dockerfile` |
| Language | TypeScript | — | Cal.com upstream (Next.js/Node.js) |
| Framework | Next.js | — | Cal.com upstream |
| Runtime | Node.js | — | Cal.com upstream |
| Build tool | Docker | — | `Dockerfile` |
| Helm chart | cmf-generic-api | 3.88.1 | `.meta/deployment/cloud/scripts/deploy.sh` |
| Deploy tool | krane | — | `.meta/deployment/cloud/scripts/deploy.sh` |

### Key Libraries

> This service is a wrapper around the upstream Cal.com Docker image (`calcom/cal.com:v4.3.5`). Groupon does not own the application source code. Key library composition reflects the Cal.com open-source product. Only deployment-level tooling is directly controlled by Groupon.

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Next.js | — | ui-framework | Server-side rendering, routing, and API routes |
| Node.js | — | runtime | Server execution environment |
| Prisma | — | orm | Database access layer for PostgreSQL (Cal.com standard) |
| NextAuth.js | — | auth | Authentication and session management |
| Nodemailer | — | messaging | SMTP email dispatch |
| Helm (cmf-generic-api) | 3.88.1 | deployment | Kubernetes manifest templating |
| krane | — | deployment | Kubernetes resource deployment |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the upstream Cal.com repository for a full list.
