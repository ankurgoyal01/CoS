---
service: "ARQWeb"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumArqWebApp", "continuumArqWorker", "continuumArqPostgres"]
---

# Architecture Context

## System Context

ARQWeb is a service within the Continuum Platform (`continuumSystem`) — Groupon's core commerce and operations engine. It occupies the identity governance layer, sitting between Groupon employees (who submit and approve access requests via a web UI) and a set of authoritative identity and project management systems: Active Directory, GitHub Enterprise, Workday, Service Portal, Jira, Cyclops, and an SMTP relay. ARQWeb has no inbound dependencies from other Continuum services; it is accessed directly by human users and acts as an orchestrator of access-change operations across external systems.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| ARQWeb App | `continuumArqWebApp` | WebApp | Python Flask / uWSGI | Flask web application serving the ARQ UI and APIs for access requests, approvals, and admin workflows |
| ARQ Worker | `continuumArqWorker` | Worker | Python Worker | Background cron worker executing scheduled jobs and queue processors for ARQ workflows |
| ARQ PostgreSQL | `continuumArqPostgres` | Database | PostgreSQL | Relational database storing ARQ requests, jobs, audit trails, and configuration data |

## Components by Container

### ARQWeb App (`continuumArqWebApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Routing and Controllers (`arqWebRouting`) | Flask blueprints and request handlers for all UI and API endpoints | Flask Blueprints |
| Access Request Domain Services (`arqWebAccessRequestDomain`) | Core access request, approval, onboarding, and SOX workflow logic | Python modules |
| Persistence Layer (`arqWebPersistence`) | Database wrappers and models for requests, jobs, tokens, and audit records | psycopg / SQL |
| External Integration Adapters (`arqWebExternalAdapters`) | Integrations for LDAP, Jira, GitHub, Service Portal, Workday, email, and webhooks | HTTP / SDK clients |

### ARQ Worker (`continuumArqWorker`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Cron Worker Loop (`arqWorkerCronLoop`) | Schedules and runs due jobs with retries, timeout protection, and graceful shutdown | arqweb.cron.worker |
| Job Handlers (`arqWorkerJobHandlers`) | Processes queued requests, Jira jobs, webhook jobs, and recurring maintenance jobs | arqweb.scripts and background_jobs |
| Worker Persistence (`arqWorkerPersistence`) | Reads and writes cron/job queue state and execution logs in PostgreSQL | psycopg / SQL |
| Worker External Adapters (`arqWorkerExternalAdapters`) | Calls LDAP, Jira, GitHub, Service Portal, Workday, Cyclops, SMTP, and webhook endpoints | HTTP / SDK clients |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumArqWebApp` | `continuumArqPostgres` | Reads and writes ARQ data | SQL/TCP |
| `continuumArqWorker` | `continuumArqPostgres` | Processes cron and queued jobs | SQL/TCP |
| `continuumArqWebApp` | `activeDirectory` | Queries and updates group memberships | LDAP/LDAPS |
| `continuumArqWebApp` | `servicePortal` | Fetches service metadata and ownership | HTTPS/JSON |
| `continuumArqWebApp` | `workday` | Reads employee and manager hierarchy data | HTTPS |
| `continuumArqWebApp` | `githubEnterprise` | Manages SOX team/repository access | HTTPS API |
| `continuumArqWebApp` | `continuumJiraService` | Creates and updates access workflow tickets | HTTPS API |
| `continuumArqWebApp` | `smtpRelay` | Sends notification and digest emails | SMTP |
| `continuumArqWebApp` | `elasticApm` | Publishes traces and error telemetry | APM agent |
| `continuumArqWorker` | `activeDirectory` | Processes AD membership jobs | LDAP/LDAPS |
| `continuumArqWorker` | `servicePortal` | Syncs service chain and classification data | HTTPS/JSON |
| `continuumArqWorker` | `workday` | Runs user sync and manager chain refreshes | HTTPS |
| `continuumArqWorker` | `githubEnterprise` | Applies GitHub access changes | HTTPS API |
| `continuumArqWorker` | `continuumJiraService` | Processes queued Jira ticket jobs | HTTPS API |
| `continuumArqWorker` | `cyclops` | Runs Cyclops SOX and role workflows | HTTPS API |
| `continuumArqWorker` | `smtpRelay` | Sends scheduled reminder and digest emails | SMTP |
| `continuumArqWorker` | `externalWebhookConsumers` | Delivers queued webhook notifications | HTTPS POST |
| `continuumArqWorker` | `elasticApm` | Publishes worker telemetry and exceptions | APM agent |
| `arqWebRouting` | `arqWebAccessRequestDomain` | Invokes request/approval and admin workflows | direct |
| `arqWebAccessRequestDomain` | `arqWebPersistence` | Reads and updates access request state | direct |
| `arqWebAccessRequestDomain` | `arqWebExternalAdapters` | Uses external systems for approvals, directory, and notifications | direct |
| `arqWebExternalAdapters` | `arqWebPersistence` | Persists integration outputs and job entries | direct |
| `arqWorkerCronLoop` | `arqWorkerJobHandlers` | Dispatches runnable jobs | direct |
| `arqWorkerJobHandlers` | `arqWorkerPersistence` | Reads runnable jobs and writes execution results | direct |
| `arqWorkerJobHandlers` | `arqWorkerExternalAdapters` | Executes external side effects for jobs | direct |
| `arqWorkerExternalAdapters` | `arqWorkerPersistence` | Updates queue and audit state after external calls | direct |

## Architecture Diagram References

- Component (ARQWeb App): `components-continuum-arq-web-app`
- Component (ARQ Worker): `components-continuum-arq-worker`
