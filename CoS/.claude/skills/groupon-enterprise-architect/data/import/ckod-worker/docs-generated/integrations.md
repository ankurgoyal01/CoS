---
service: "ckod-worker"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 7
internal_count: 1
---

# Integrations

## Overview

CKOD Worker integrates with seven external systems and one internal Continuum service. The integration landscape is broad: SaaS platforms (Jira, JSM, Keboola, Google Chat, Vertex AI), external shared databases (Service Portal, Optimus Prime), and the CKOD UI API. All outbound calls are made via the `cwExternalClients` component or the `cwDatabaseAccess` layer. There is no inbound API surface.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Jira Cloud | HTTPS | Create, update, and transition incident and deployment approval tickets | yes | `continuumJiraService` |
| JSM Ops | HTTPS | Fetch on-call schedules, incident details, and send heartbeats | yes | `jsmOps` |
| Keboola | HTTPS | Fetch pipeline project metadata, storage details, run status, and execution results | yes | `keboola` |
| Google Chat | HTTPS webhook | Send operational and deployment notification messages | yes | `googleChat` |
| Vertex AI | Google Cloud API | Invoke reasoning-engine sessions for AI-assisted deployment automation | no | `vertexAi` |
| Service Portal | MySQL | Read user, group, and membership data for authorization sync | yes | `servicePortal` |
| Optimus Prime | PostgreSQL | Read job run data for SLA calculations | yes | `optimusPrime` |

### Jira Cloud Detail

- **Protocol**: HTTPS REST API
- **Base URL / SDK**: Jira Cloud REST API via Python HTTP client (`cwExternalClients`)
- **Auth**: > No evidence found in codebase for specific auth method; typically API token
- **Purpose**: `cwDeploymentOps` creates and transitions deployment approval tickets. `cwSlaOrchestration` and `cwMonitoring` open and update incident tickets when SLA violations are detected.
- **Failure mode**: Incident and deployment tickets cannot be created or updated; alerts fall back to Google Chat notifications only.
- **Circuit breaker**: > No evidence found in codebase.

### JSM Ops Detail

- **Protocol**: HTTPS REST API
- **Base URL / SDK**: Atlassian JSM Ops API via Python HTTP client (`cwExternalClients`)
- **Auth**: > No evidence found in codebase for specific auth method; typically API token
- **Purpose**: Fetches on-call rotation data for incident routing; retrieves incident details; sends worker heartbeats for availability monitoring.
- **Failure mode**: On-call routing data unavailable; heartbeat monitoring disrupted.
- **Circuit breaker**: > No evidence found in codebase.

### Keboola Detail

- **Protocol**: HTTPS REST API
- **Base URL / SDK**: Keboola Storage and Queue APIs via Python HTTP client (`cwExternalClients`)
- **Auth**: > No evidence found in codebase for specific auth method; typically API token
- **Purpose**: `cwSlaOrchestration` fetches pipeline run status to compute SLA compliance. `cwDataSync` fetches project metadata, storage details, and execution results for enrichment jobs.
- **Failure mode**: SLA calculations for Keboola-managed pipelines cannot run; pipeline sync data becomes stale.
- **Circuit breaker**: > No evidence found in codebase.

### Google Chat Detail

- **Protocol**: HTTPS webhook
- **Base URL / SDK**: Google Chat Incoming Webhook URL via Python HTTP client (`cwExternalClients`)
- **Auth**: Webhook URL contains embedded token
- **Purpose**: `cwMonitoring` and `cwDeploymentOps` send operational alerts and deployment notifications to designated Google Chat spaces.
- **Failure mode**: Notifications not delivered; incident and deployment state still tracked internally.
- **Circuit breaker**: > No evidence found in codebase.

### Vertex AI Detail

- **Protocol**: Google Cloud API (gRPC/REST)
- **Base URL / SDK**: Google Cloud Vertex AI SDK via Python (`cwAgentPolling`)
- **Auth**: > No evidence found in codebase; typically Google service account credentials
- **Purpose**: `cwAgentPolling` invokes reasoning-engine sessions and streams query results to automate deployment-related decisions based on tasks fetched from CKOD UI.
- **Failure mode**: AI-assisted automation unavailable; tasks remain pending in CKOD UI queue.
- **Circuit breaker**: > No evidence found in codebase.

### Service Portal Detail

- **Protocol**: MySQL direct database connection
- **Base URL / SDK**: Python database adapter (`cwDatabaseAccess`)
- **Auth**: > No evidence found in codebase for specific credentials
- **Purpose**: `cwDataSync` reads user, group, and membership tables to rebuild authorization data in the CKOD database.
- **Failure mode**: Authorization sync fails; CKOD authorization data becomes stale.
- **Circuit breaker**: > Not applicable for direct database connections.

### Optimus Prime Detail

- **Protocol**: PostgreSQL direct database connection
- **Base URL / SDK**: Python database adapter (`cwDatabaseAccess`)
- **Auth**: > No evidence found in codebase for specific credentials
- **Purpose**: `cwSlaOrchestration` reads Optimus Prime job run tables to calculate SLA compliance for OP-managed pipeline flows.
- **Failure mode**: SLA calculations for Optimus Prime flows cannot run; related SLA records become stale.
- **Circuit breaker**: > Not applicable for direct database connections.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| CKOD UI API | HTTPS | Poll for pending agent tasks and deployment context; provides work items to the agent polling workflow | `continuumCkodUi` |

### CKOD UI API Detail

- **Protocol**: HTTPS
- **Purpose**: `cwAgentPolling` polls the CKOD UI API at short intervals to retrieve pending agent tasks. Retrieved tasks are processed via Vertex AI reasoning-engine sessions.
- **Failure mode**: Agent task queue cannot be read; AI-assisted automation paused.

## Consumed By

> Upstream consumers are tracked in the central architecture model. CKOD Worker has no inbound API; it is not consumed by other services.

## Dependency Health

> Operational procedures to be defined by service owner. No circuit breaker or health check patterns are explicitly described in the architecture model. The `jsmOps` heartbeat integration provides an external liveness signal for JSM-based monitoring.
