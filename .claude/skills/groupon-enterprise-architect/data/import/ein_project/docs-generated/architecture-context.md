---
service: "ein_project"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumProdcatWebApp, continuumProdcatWorker, continuumProdcatProxy, continuumProdcatPostgres, continuumProdcatRedis]
---

# Architecture Context

## System Context

ProdCat operates as a set of containers within the `continuumSystem` (Continuum Platform) software system. Inbound HTTP traffic from deployment tooling and engineers enters through the Nginx proxy, which forwards requests to the Django web application. Background compliance tasks run in a separate worker process. Both the web application and worker persist state to a Cloud SQL PostgreSQL database and coordinate via a Memorystore Redis instance. ProdCat integrates outbound with JIRA Cloud, JSM, Google Chat, PagerDuty, Service Portal, GitHub, and Wavefront.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| ProdCat Nginx Proxy | `continuumProdcatProxy` | Proxy | Nginx | — | Reverse proxy for all inbound HTTP traffic |
| ProdCat Web App | `continuumProdcatWebApp` | WebApp | Python/Django | Django 5.2.6 / Gunicorn 23.0.0 | Django application providing the web UI and REST API |
| ProdCat Worker | `continuumProdcatWorker` | Worker | Python/RQ | RQ 2.6.0 | Background job processor for async tasks and database-backed cron jobs |
| ProdCat Cloud SQL PostgreSQL | `continuumProdcatPostgres` | Database | PostgreSQL | — | Primary store for deployment records and configuration |
| ProdCat Memorystore Redis | `continuumProdcatRedis` | Cache | Redis | — | Session storage, validation result cache, and RQ job queue |

## Components by Container

### ProdCat Web App (`continuumProdcatWebApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `einProject_webUi` | Django templates and frontend views for change requests | Django |
| `apiController` | HTTP endpoints for change approvals and status queries | Django REST Framework |
| `einProject_authService` | JWT and session-based authentication and authorization | Django |
| `validationEngine` | Runs validation checks for change requests | Python |
| `policyService` | Evaluates region and approval policies | Python |
| `einProject_dataAccess` | Repository layer for database access | Django ORM |
| `einProject_cacheClient` | Redis-backed caching for validation results and sessions | Redis |
| `asyncTaskDispatcher` | Enqueues background jobs for RQ workers | RQ |
| `einProject_jiraClient` | Integration with JIRA Cloud API v3 | HTTP |
| `jsmAlertsClient` | Integration with Jira Service Management alerts | HTTP |
| `einProject_servicePortalClient` | Validates service configuration via internal portal | HTTP |
| `googleChatClient` | Posts deployment notifications to Google Chat | HTTP |

### ProdCat Worker (`continuumProdcatWorker`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `rqWorker` | Processes async tasks from Redis queues | Python/RQ |
| `dbCronWorker` | Runs scheduled jobs stored in the database | Python |
| `einProject_jobScheduler` | Schedules and triggers background jobs | Python |
| `ticketCloser` | Auto-closes failed or abandoned deployment tickets | Python |
| `incidentMonitor` | Checks ongoing incidents and locks regions | Python |
| `queueMaintenance` | Prunes and cleans background queues | Python |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumProdcatProxy` | `continuumProdcatWebApp` | Reverse proxies HTTP traffic | HTTP |
| `continuumProdcatWebApp` | `continuumProdcatPostgres` | Reads and writes deployment data | TCP/SQL |
| `continuumProdcatWebApp` | `continuumProdcatRedis` | Caches validation results and sessions | TCP/Redis |
| `continuumProdcatWorker` | `continuumProdcatPostgres` | Reads and writes job and deployment data | TCP/SQL |
| `continuumProdcatWorker` | `continuumProdcatRedis` | Consumes and acknowledges job queues | TCP/Redis |
| `apiController` | `validationEngine` | Runs validations | direct |
| `apiController` | `policyService` | Loads policy state | direct |
| `apiController` | `asyncTaskDispatcher` | Enqueues background jobs | direct |
| `apiController` | `googleChatClient` | Posts notifications | direct |
| `validationEngine` | `einProject_jiraClient` | Queries and updates tickets | REST |
| `validationEngine` | `jsmAlertsClient` | Checks incidents for region locks | REST |
| `validationEngine` | `einProject_servicePortalClient` | Validates service configuration | REST |
| `einProject_jobScheduler` | `dbCronWorker` | Schedules cron jobs | direct |
| `einProject_jobScheduler` | `rqWorker` | Schedules async tasks | direct |
| `dbCronWorker` | `ticketCloser` | Auto-closes failed deployments | direct |
| `dbCronWorker` | `incidentMonitor` | Monitors incidents for region locks | direct |
| `dbCronWorker` | `queueMaintenance` | Prunes and cleans queues | direct |

## Architecture Diagram References

- Container: `containers-continuumSystem`
- Component (Web App): `components-prodcat-web-app-components`
- Component (Worker): `components-prodcat-rqWorker-components`
- Dynamic (Change Request): `dynamic-change-request`
- Dynamic (Background Jobs): `dynamic-background-jobs`
