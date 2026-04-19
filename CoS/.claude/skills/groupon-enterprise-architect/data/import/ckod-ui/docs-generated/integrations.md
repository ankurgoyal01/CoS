---
service: "ckod-ui"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 7
internal_count: 1
---

# Integrations

## Overview

ckod-ui integrates with seven external systems and one internal Groupon service. All integrations are synchronous HTTP REST calls made from server-side Next.js API route handlers via dedicated client modules in `src/lib/external-apis/`. There are no message-bus integrations. The most critical external dependencies are JIRA (for incident and deployment ticket workflows) and Keboola (for deployment orchestration). Vertex AI and LiteLLM power the AI features.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Jira Cloud | REST | Create and manage deployment and incident tickets | yes | `continuumJiraService` |
| JSM Ops | REST | Retrieve on-call rotation and active JSM alerts | yes | `jsmOps` |
| GitHub Enterprise | REST | Retrieve repo diffs and author lists for deployment review | yes | `githubEnterprise` |
| Keboola Storage API | REST | Read project, branch, and component data for deployment workflows | yes | `keboola` |
| Deploybot | REST | Retrieve deployment metadata, diff links, and SOX information | yes | `extDeploybot` |
| Google Chat | HTTPS Webhook | Send deployment notifications and AI-generated handover chat cards | no | `googleChat` |
| Vertex AI Reasoning Engine | HTTPS | Stream chat requests to configured reasoning engine agents | no | `vertexAi` |
| LiteLLM Proxy | HTTPS | Generate AI handover note text via LLM inference | no | `extLiteLlm` |

### Jira Cloud Detail

- **Protocol**: REST (HTTPS)
- **Client**: `src/lib/external-apis/jira-client.ts`
- **Auth**: API token (environment secret)
- **Purpose**: Creates deployment tickets (Keboola and Airflow), creates incident records, transitions ticket status, adds comments
- **Failure mode**: Deployment creation fails; error returned to UI
- **Circuit breaker**: No

### JSM Ops Detail

- **Protocol**: REST (HTTPS)
- **Client**: `src/lib/external-apis/jsm-client.ts`
- **Auth**: API token (environment secret)
- **Purpose**: Retrieves current on-call engineer and active JSM alerts for the Hand It Over feature
- **Failure mode**: Hand It Over on-call and alert data unavailable; feature degrades gracefully
- **Circuit breaker**: No

### GitHub Enterprise Detail

- **Protocol**: REST (HTTPS)
- **Client**: `src/lib/external-apis/github-client.ts`
- **Auth**: Personal access token or app token (environment secret)
- **Purpose**: Fetches Git diff between two refs for deployment review; retrieves pipeline authors
- **Failure mode**: Diff view unavailable in deployment UI
- **Circuit breaker**: No

### Keboola Storage API Detail

- **Protocol**: REST (HTTPS)
- **Client**: `src/lib/external-apis/keboola-client.ts`
- **Auth**: Per-project Keboola tokens stored in `keboola_project.token` MySQL column
- **Purpose**: Reads project branch data, component configurations, and triggers job reruns for deployment workflows
- **Failure mode**: Branch deployment details unavailable; deployment creation blocked
- **Circuit breaker**: No

### Deploybot Detail

- **Protocol**: REST (HTTPS)
- **Client**: `src/lib/external-apis/deploybot-client.ts`
- **Auth**: Environment secret
- **Purpose**: Retrieves deployment metadata, Git diff links, environment information, and SOX requester data for the deployment tracking UI
- **Failure mode**: Deployment metadata fields show as unavailable in the UI
- **Circuit breaker**: No

### Google Chat Detail

- **Protocol**: HTTPS Webhook
- **Client**: `src/lib/external-apis/google-chat-client.ts`
- **Auth**: Webhook URL (environment secret)
- **Purpose**: Sends structured deployment notification cards and AI-generated handover summary cards to configured Google Chat spaces
- **Failure mode**: Notifications silently fail; core functionality unaffected
- **Circuit breaker**: No

### Vertex AI Reasoning Engine Detail

- **Protocol**: HTTPS (streaming supported)
- **Auth**: Google service account credentials via `google-auth-library`; credentials pointed to by `CKOD_AGENTS_JSON[].credentialsEnvKey`
- **Purpose**: Hosts multi-agent reasoning sessions for the `/vertex-ai-agent` dashboard page; supports multiple configured agents with team-based access control
- **Failure mode**: AI agent chat feature unavailable
- **Circuit breaker**: No

### LiteLLM Proxy Detail

- **Protocol**: HTTPS
- **Client**: `src/lib/external-apis/litellm-client.ts`
- **Auth**: Environment secret
- **Purpose**: Generates AI-written handover notes by invoking LLM models through the internal LiteLLM proxy
- **Failure mode**: Handover note generation unavailable; manual notes only
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| CKOD API (JTier) | REST | Calls CKOD backend endpoints for additional operational data | `continuumCkodBackendJtier` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. ckod-ui is a user-facing application consumed directly by browser clients (Groupon data engineers and PRE team operators). No machine-to-machine consumers are known.

## Dependency Health

No automated circuit breaker or retry framework is implemented. Each external API client handles errors internally and propagates them to the API route handler, which returns an HTTP 500 response to the UI. The UI surfaces errors via the Sonner toast notification system. For Vertex AI, the `google-auth-library` manages token refresh automatically.
