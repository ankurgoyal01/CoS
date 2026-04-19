---
service: "ARQWeb"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 8
internal_count: 1
---

# Integrations

## Overview

ARQWeb integrates with eight external systems and one internal Continuum service. Both the web application (`continuumArqWebApp`) and the background worker (`continuumArqWorker`) share most external dependencies, with the worker additionally calling Cyclops and webhook consumers. All external calls use HTTPS or LDAP/LDAPS protocols. There is no inbound dependency from other Continuum services — ARQWeb is a consumer, not a provider, within the Continuum inter-service graph.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Active Directory | LDAP/LDAPS | Query and update AD group memberships for access provisioning | yes | `activeDirectory` |
| Service Portal | HTTPS/JSON | Fetch service metadata and ownership; sync service chain classifications | yes | `servicePortal` |
| Workday | HTTPS | Read employee profiles and manager hierarchy data; run user sync | yes | `workday` |
| GitHub Enterprise | HTTPS API | Manage SOX team/repository access; apply GitHub access changes | yes | `githubEnterprise` |
| Jira | HTTPS API | Create and update access workflow tickets; process queued Jira jobs | yes | `continuumJiraService` |
| SMTP Relay | SMTP | Send approval notification, reminder, and digest emails | no | `smtpRelay` |
| Cyclops | HTTPS API | Run SOX and role workflow automation | yes | `cyclops` |
| External Webhook Consumers | HTTPS POST | Deliver queued webhook notifications for access state changes | no | `externalWebhookConsumers` |
| Elastic APM | APM agent | Publish distributed traces and error telemetry | no | `elasticApm` |

### Active Directory Detail

- **Protocol**: LDAP/LDAPS
- **Base URL / SDK**: Internal AD server (host configurable via environment)
- **Auth**: Service account credentials (LDAP bind DN and password)
- **Purpose**: ARQWeb queries AD to read current group memberships and writes changes when access requests are approved. The worker processes batched AD membership jobs asynchronously.
- **Failure mode**: Access provisioning stalls; jobs are retried by the worker
- **Circuit breaker**: No evidence found in codebase

### Service Portal Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: Internal Service Portal API (URL configurable via environment)
- **Auth**: API token or service account credentials
- **Purpose**: ARQWeb fetches service ownership and metadata to associate access requests with the correct service owners. The worker periodically syncs service chain and classification data.
- **Failure mode**: Service ownership lookups return stale or empty data; approvals may be delayed
- **Circuit breaker**: No evidence found in codebase

### Workday Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: Workday REST/SOAP API (URL configurable via environment)
- **Auth**: OAuth2 or service account credentials
- **Purpose**: Reads employee profiles, reporting manager chains, and termination status. Used to validate requestors, identify approvers, and run periodic user sync.
- **Failure mode**: Manager chain lookups fail; user sync jobs deferred until next scheduled run
- **Circuit breaker**: No evidence found in codebase

### GitHub Enterprise Detail

- **Protocol**: HTTPS API
- **Base URL / SDK**: GitHub Enterprise REST API (base URL configurable via environment)
- **Auth**: Personal access token or GitHub App credentials
- **Purpose**: Manages team membership and repository access for SOX-gated GitHub resources. Both the web app (immediate changes) and worker (queued changes) call GitHub.
- **Failure mode**: GitHub access changes are queued and retried by the worker
- **Circuit breaker**: No evidence found in codebase

### Jira Detail

- **Protocol**: HTTPS API
- **Base URL / SDK**: Jira REST API via `continuumJiraService` (internal Continuum Jira adapter)
- **Auth**: API token or service account
- **Purpose**: Creates Jira tickets for each access request workflow step; updates ticket status as requests progress through approval stages.
- **Failure mode**: Ticket creation fails; worker retries queued Jira jobs
- **Circuit breaker**: No evidence found in codebase

### SMTP Relay Detail

- **Protocol**: SMTP
- **Base URL / SDK**: Internal SMTP relay (host/port configurable via environment)
- **Auth**: SMTP AUTH credentials or open relay on internal network
- **Purpose**: Sends approval request emails, reminder emails, and periodic digest emails to requestors, approvers, and admins.
- **Failure mode**: Email delivery fails silently; requests still progress without email notification
- **Circuit breaker**: No evidence found in codebase

### Cyclops Detail

- **Protocol**: HTTPS API
- **Base URL / SDK**: Internal Cyclops service (URL configurable via environment)
- **Auth**: Service-to-service auth credentials
- **Purpose**: Worker-only. Executes Cyclops SOX and role workflow automation as part of access provisioning for SOX-controlled systems.
- **Failure mode**: SOX workflow jobs fail and are retried by the worker
- **Circuit breaker**: No evidence found in codebase

### External Webhook Consumers Detail

- **Protocol**: HTTPS POST
- **Base URL / SDK**: Consumer-registered callback URLs stored in ARQ database
- **Auth**: Per-consumer shared secret or bearer token (configurable per consumer)
- **Purpose**: Worker-only. Delivers queued outbound webhook notifications when access request state changes occur.
- **Failure mode**: Delivery failures are retried by the worker; consumer URL is marked as erroring after repeated failures
- **Circuit breaker**: No evidence found in codebase

### Elastic APM Detail

- **Protocol**: APM agent (HTTP)
- **Base URL / SDK**: Elastic APM Python agent
- **Auth**: APM secret token
- **Purpose**: Captures distributed traces, performance metrics, and error/exception telemetry from both the web app and worker processes.
- **Failure mode**: Telemetry is dropped; service continues to operate normally
- **Circuit breaker**: Not applicable (fire-and-forget telemetry)

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Jira Service (Continuum) | HTTPS API | Provides Jira ticket lifecycle management for access workflows | `continuumJiraService` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. ARQWeb is accessed directly by internal Groupon employees via web browser and is not known to be called by other Continuum microservices.

## Dependency Health

Both the web application and worker share the same set of external adapters (`arqWebExternalAdapters`, `arqWorkerExternalAdapters`). The worker's `arqWorkerCronLoop` provides retry logic with timeout protection for all job-based external calls. There is no evidence of circuit breaker patterns in the architecture model; failures in external dependencies result in job retries up to a maximum attempt count before the job is marked as failed.
