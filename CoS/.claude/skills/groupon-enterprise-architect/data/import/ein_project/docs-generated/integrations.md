---
service: "ein_project"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 6
internal_count: 2
---

# Integrations

## Overview

ProdCat integrates with six external systems to enforce deployment compliance: JIRA Cloud and JSM for ticket validation and incident-driven region locking, Google Chat for deployment notifications, Wavefront for metrics, Service Portal for service configuration validation, and GitHub for deployment metadata. Two internal Continuum systems are referenced: the hybrid boundary/load balancer that routes inbound traffic, and the Kafka-based log shipping pipeline (referenced in stubs, not yet modeled in the central architecture).

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| JIRA Cloud | REST (SDK: `jira` 3.10.5) | Validate and update deployment tickets; auto-close failed tickets | yes | `jiraCloudSystem_unk_c3d4` |
| Jira Service Management (JSM) | REST (SDK: `pdpyras` 5.4.1 / `jira`) | Check active incidents to drive region locking | yes | `jsmAlertsSystem_unk_d4e5` |
| Google Chat | REST (SDK: `google-api-python-client` 2.181.0) | Post deployment approval and rejection notifications | no | `googleChatSystem_unk_e5f6` |
| Wavefront | REST (SDK: `wavefront-api-client` 2.202.2) | Emit deployment compliance metrics | no | `metricsCollectionSystem_unk_b22c` |
| Service Portal | REST (`requests` 2.32.5) | Validate service registration and configuration before approving change | yes | `servicePortalSystem_unk_f6a7` |
| GitHub | REST (SDK: `pygithub` 2.8.1) | Retrieve deployment metadata (commit, PR, branch) for change request context | no | — |
| PagerDuty | REST (SDK: `pdpyras` 5.4.1) | Check active PagerDuty incidents for region lock evaluation | yes | — |

### JIRA Cloud Detail

- **Protocol**: REST (JIRA Cloud API v3)
- **Base URL / SDK**: `jira` Python library 3.10.5
- **Auth**: API token (configured via environment secret)
- **Purpose**: On every change request validation, the Validation Engine queries the linked JIRA ticket to confirm it exists, is in the correct status, and is approved. After a deployment completes or fails, the Worker auto-closes the ticket via `ticketCloser`.
- **Failure mode**: Validation fails closed — a change request is rejected if JIRA is unreachable and ticket status cannot be confirmed.
- **Circuit breaker**: No evidence found.

### Jira Service Management (JSM) Detail

- **Protocol**: REST
- **Base URL / SDK**: `jsmAlertsClient` component; `pdpyras` 5.4.1 / JIRA SDK
- **Auth**: API token (configured via environment secret)
- **Purpose**: The `incidentMonitor` background job and the `jsmAlertsClient` component check for active JSM alerts scoped to a region. When an active incident is detected, the region is locked, preventing all deployments.
- **Failure mode**: If JSM is unreachable, region lock state derived from last known check is preserved.
- **Circuit breaker**: No evidence found.

### Google Chat Detail

- **Protocol**: REST (Google Chat Webhooks / Chat API)
- **Base URL / SDK**: `google-api-python-client` 2.181.0; `slack-sdk` 3.36.0
- **Auth**: Webhook URL or OAuth2 service account (configured via environment secret)
- **Purpose**: `googleChatClient` posts notifications to configured chat spaces when a change request is approved, rejected, or when a region lock is applied or lifted.
- **Failure mode**: Notification failure is non-blocking; change request outcome is not affected.
- **Circuit breaker**: No evidence found.

### Wavefront Detail

- **Protocol**: REST
- **Base URL / SDK**: `wavefront-api-client` 2.202.2
- **Auth**: API token (configured via environment secret)
- **Purpose**: Emits deployment compliance metrics (approval rate, rejection reasons, lock durations) for observability dashboards.
- **Failure mode**: Metrics emission failure is non-blocking.
- **Circuit breaker**: No evidence found.

### Service Portal Detail

- **Protocol**: REST
- **Base URL / SDK**: `requests` 2.32.5 via `einProject_servicePortalClient` component
- **Auth**: Internal service credentials (configured via environment)
- **Purpose**: Before approving a change request, the Validation Engine calls Service Portal to confirm the target service is registered and its configuration is valid.
- **Failure mode**: Validation fails closed — an unregistered or misconfigured service causes the change request to be rejected.
- **Circuit breaker**: No evidence found.

### GitHub Detail

- **Protocol**: REST (GitHub API v3)
- **Base URL / SDK**: `pygithub` 2.8.1
- **Auth**: GitHub App or personal access token (configured via environment secret)
- **Purpose**: Retrieves commit SHA, pull request number, and branch name associated with a deployment to enrich the change request record.
- **Failure mode**: Metadata enrichment failure is non-blocking; change request proceeds without Git context.
- **Circuit breaker**: No evidence found.

### PagerDuty Detail

- **Protocol**: REST
- **Base URL / SDK**: `pdpyras` 5.4.1
- **Auth**: PagerDuty API token (configured via environment secret)
- **Purpose**: Supplements JSM incident checks; `incidentMonitor` also queries PagerDuty for active incidents to determine whether a region lock should be applied or lifted.
- **Failure mode**: If PagerDuty is unreachable, last known lock state is preserved.
- **Circuit breaker**: No evidence found.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Hybrid Boundary / Load Balancer | HTTP | Routes inbound traffic to `continuumProdcatProxy` | `hybridBoundarySystem_unk_a2b1` |
| Kafka Log Pipeline | Kafka (log shipping) | Receives application, worker, and proxy logs | `kafkaLogging_unk_a11b` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Deployment tooling (DeployBot / CI pipelines) | REST | Submits change requests to `/api/changes/` and queries `/api/check/` before deploying |
| Release engineers (web UI) | HTTP/Browser | Reviews and approves change requests via the Django web UI |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

The `/api/heartbeat/` endpoint provides a liveness check for orchestration layer probes. Dependency health for JIRA, JSM, Service Portal, and PagerDuty is implicitly monitored via validation failure rates visible in Wavefront. No explicit circuit breaker or retry configuration is documented in the architecture model; operational retry behavior is to be confirmed by the service owner.
