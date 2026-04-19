---
service: "garvis"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 8
internal_count: 0
---

# Integrations

## Overview

Garvis integrates with eight external systems to deliver its Change Management, Operations, and DevEx capabilities. All external integrations are outbound REST/SDK calls or inbound webhooks. There are no internal Groupon service-to-service dependencies beyond the Continuum platform's shared data stores. The `continuumJarvisBot` and `continuumJarvisWorker` containers are the primary callers of external APIs; `continuumJarvisWebApp` receives inbound webhooks from JIRA.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google Cloud Pub/Sub | SDK (google-cloud-pubsub) | Delivers Google Chat events to the bot subscriber | yes | `googlePubSub` |
| Google Chat API | REST (google-api-python-client) | Sends messages, manages spaces, handles bot interactions | yes | `googleChatApi` |
| JIRA | REST (jira library) | Creates and updates change and incident tickets | yes | `jiraApi` |
| PagerDuty | REST (pdpyras) | On-call schedule lookup and incident alerting | yes | — |
| GitHub | REST (PyGithub) | Repository and PR queries for change context | no | — |
| Google Drive / Docs / Calendar | SDK (google-api-python-client) | Document retrieval, runbook access, calendar event creation | no | — |
| ProdCAT | REST (requests) | Product catalog and service health data for ORR flows | no | — |
| Service Health / ORR | REST (requests) | Operational readiness review status and health signals | no | — |

### Google Cloud Pub/Sub Detail

- **Protocol**: Google Cloud Pub/Sub SDK (`google-cloud-pubsub` 2.34.0)
- **Base URL / SDK**: `google-cloud-pubsub` Python library; subscription configured per environment
- **Auth**: Google service account credentials (Application Default Credentials or explicit key file)
- **Purpose**: `botPubSubSubscriber` in `continuumJarvisBot` maintains a streaming subscription to the Google Chat Pub/Sub topic; all Google Chat events arrive via this channel
- **Failure mode**: Pub/Sub messages are redelivered until acknowledged; bot loses real-time responsiveness if subscriber is down
- **Circuit breaker**: No

### Google Chat API Detail

- **Protocol**: HTTPS / REST via `google-api-python-client`
- **Base URL / SDK**: `googleapiclient.discovery` for Chat API (`chat.googleapis.com`)
- **Auth**: Google service account with Chat API scopes
- **Purpose**: `botChatClient` in `continuumJarvisBot` and `workerPluginJobs` in `continuumJarvisWorker` send messages to Chat spaces, create direct messages, and manage space memberships for notifications
- **Failure mode**: Bot cannot send responses or notifications; user-facing interactions time out silently
- **Circuit breaker**: No

### JIRA Detail

- **Protocol**: HTTPS / REST via `jira` Python library
- **Base URL / SDK**: `jira` library pointing to the Groupon JIRA instance
- **Auth**: JIRA API token or basic auth credentials (secret-managed)
- **Purpose**: `botPluginHandlers` and `workerPluginJobs` create and update change approval tickets and incident records; `continuumJarvisWebApp` consumes JIRA webhooks for status change events
- **Failure mode**: Change approval and incident workflows are blocked; JIRA-dependent commands fail with error responses to the user
- **Circuit breaker**: No

### PagerDuty Detail

- **Protocol**: HTTPS / REST via `pdpyras`
- **Base URL / SDK**: `pdpyras` library targeting the PagerDuty REST API (`api.pagerduty.com`)
- **Auth**: PagerDuty API key (secret-managed)
- **Purpose**: Looks up on-call schedules and escalation policies; triggers and resolves incidents for the on-call lookup and incident response flows
- **Failure mode**: On-call lookup returns no results; incident escalation cannot proceed
- **Circuit breaker**: No

### GitHub Detail

- **Protocol**: HTTPS / REST via `PyGithub`
- **Base URL / SDK**: `PyGithub` library (`api.github.com`)
- **Auth**: GitHub personal access token or GitHub App credentials (secret-managed)
- **Purpose**: Queries repository metadata, PR status, and deployment context to enrich change approval records
- **Failure mode**: Change records lack GitHub context; non-critical degradation
- **Circuit breaker**: No

### Google Drive / Docs / Calendar Detail

- **Protocol**: HTTPS / SDK via `google-api-python-client`
- **Base URL / SDK**: Google Drive API, Google Docs API, Google Calendar API
- **Auth**: Google service account credentials with Drive, Docs, and Calendar scopes
- **Purpose**: Retrieves runbooks and documentation from Google Drive/Docs; creates or reads calendar events for maintenance windows and change freeze periods
- **Failure mode**: Document retrieval and calendar operations degrade gracefully; non-critical
- **Circuit breaker**: No

### ProdCAT Detail

- **Protocol**: REST via `requests` 2.32.5
- **Base URL / SDK**: Internal Groupon ProdCAT service endpoint
- **Auth**: Internal service credentials (secret-managed)
- **Purpose**: Fetches product catalog and service ownership metadata to associate changes and incidents with the correct service owners
- **Failure mode**: Service ownership context is unavailable in change/incident records; non-critical degradation
- **Circuit breaker**: No

### Service Health / ORR Detail

- **Protocol**: REST via `requests` 2.32.5
- **Base URL / SDK**: Internal Groupon Service Health / ORR service endpoint
- **Auth**: Internal service credentials (secret-managed)
- **Purpose**: Surfaces operational readiness review status and service health signals in bot responses and change approval workflows
- **Failure mode**: ORR status is unavailable; change approval proceeds without health signal context
- **Circuit breaker**: No

## Internal Dependencies

> Not applicable. Garvis has no modeled internal Groupon service-to-service dependencies beyond its own data stores (`continuumJarvisPostgres`, `continuumJarvisRedis`).

## Consumed By

> Upstream consumers are tracked in the central architecture model. Garvis is consumed by Google Chat users (engineers, on-call responders, release managers) through Google Chat spaces; it is not called directly by other Groupon services.

## Dependency Health

- The `/grpn/healthcheck` endpoint provides a liveness signal for the `continuumJarvisWebApp` container.
- The `/django-rq/` dashboard surfaces RQ worker and queue health for `continuumJarvisWorker`.
- No automated circuit breakers or retries are modeled for external API calls; failures surface as error messages to the Google Chat user or as failed RQ jobs visible in the RQ dashboard.
