---
service: "deploybot"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 11
internal_count: 2
---

# Integrations

## Overview

deploybot integrates with 11 external systems and 2 internal Groupon services. Its integration surface reflects its role as a deployment hub: it receives triggers from GitHub, authenticates via Okta, executes workloads on Kubernetes and Docker, tracks compliance via Jira, notifies via Slack, validates images in Artifactory, checks readiness via ProdCAT and Service Portal, publishes lifecycle events to PEST, and monitors CI via Conveyor. Log archival is handled through AWS S3. Most integrations are synchronous REST over HTTPS.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GitHub | webhook + REST | Receives push events; reads `.deploy_bot.yml`; checks commit CI statuses | yes | stub |
| Okta | OIDC (HTTPS) | OAuth2/OIDC authentication for kill, authorize, and promote actions | yes | stub |
| Kubernetes API | client-go (HTTPS) | Deploys and monitors Kubernetes workloads | yes | stub |
| Docker Engine | Docker API | Executes legacy container deployments | yes | stub |
| Jira | REST (HTTPS) | Creates and closes SOX logbook tickets per deployment | yes | stub |
| Slack | REST (HTTPS) | Sends deployment lifecycle notifications | no | stub |
| Artifactory | REST (HTTPS) | Validates Docker image existence; promotes images between registries | yes | stub |
| AWS S3 | AWS SDK (HTTPS) | Archives deployment log output | no | `externalS3Bucket_4b6c` |
| PEST | REST / Event bus | Publishes `deploy_start` and `deploy_complete` lifecycle events | no | stub |
| ProdCAT | REST (HTTPS) | Checks production readiness gates before deployment executes | yes | stub |
| Conveyor CI | REST (HTTPS) | Queries CI build status and maintenance windows | yes | stub |

### GitHub Detail

- **Protocol**: Webhook (inbound push events) + GitHub REST API (outbound status queries)
- **Base URL / SDK**: GitHub REST API; webhook secret via `/auth/creds`
- **Auth**: `X-Hub-Signature` HMAC for inbound webhooks; GitHub token from `/auth/creds` for outbound API calls
- **Purpose**: Primary deployment trigger; source of `.deploy_bot.yml` per-repo config; CI build status gating
- **Failure mode**: Inbound webhook failures return error to GitHub; outbound API failures block CI-gated deployments
- **Circuit breaker**: No

### Okta Detail

- **Protocol**: OIDC over HTTPS
- **Base URL / SDK**: coreos/go-oidc 2.0.0 + golang.org/x/oauth2 0.10.0
- **Auth**: OAuth2 Authorization Code flow
- **Purpose**: Authenticates engineers for protected deployment actions (kill, authorize, promote) via web UI
- **Failure mode**: Unauthenticated requests to protected endpoints are redirected to Okta login; Okta unavailability blocks all OAuth-protected actions
- **Circuit breaker**: No

### Kubernetes API Detail

- **Protocol**: HTTPS via kubernetes.io/client-go 0.29.15
- **Base URL / SDK**: Kubernetes API server (configured via kubeconfig or in-cluster service account)
- **Auth**: Kubernetes service account token (initialized by `deploybotInitExec`)
- **Purpose**: Deploys containerized workloads to Kubernetes; monitors pod execution during deployment
- **Failure mode**: Kubernetes API unavailability causes deployment execution to fail; deployment marked as failed in MySQL
- **Circuit breaker**: No

### Docker Engine Detail

- **Protocol**: Docker API (Unix socket or TCP)
- **Base URL / SDK**: docker/distribution 2.7.1 for image reference parsing
- **Auth**: Configured Docker credentials
- **Purpose**: Executes legacy Capistrano / UberDeploy / Napistrano deployments in Docker containers
- **Failure mode**: Docker Engine unavailability causes deployment to fail; error captured in deployment log
- **Circuit breaker**: No

### Jira Detail

- **Protocol**: REST (HTTPS)
- **Base URL / SDK**: Jira REST API; credentials from `/auth/creds` (jira user/pass)
- **Auth**: HTTP Basic Auth
- **Purpose**: Creates SOX logbook ticket at deployment start; closes ticket with outcome and log URL at finalization
- **Failure mode**: Jira unavailability is logged; deployment may proceed but SOX audit record may be incomplete
- **Circuit breaker**: No

### Slack Detail

- **Protocol**: REST (HTTPS)
- **Base URL / SDK**: Slack API / incoming webhook
- **Auth**: Webhook token or bot token (from credentials store)
- **Purpose**: Notifies engineers of deployment stages: queued, started, completed, failed, overridden
- **Failure mode**: Slack unavailability is non-blocking; notification failure is logged but does not halt deployment
- **Circuit breaker**: No

### Artifactory Detail

- **Protocol**: REST (HTTPS)
- **Base URL / SDK**: Artifactory REST API; credentials from `/auth/creds` (artifactory user/pass)
- **Auth**: HTTP Basic Auth
- **Purpose**: Validates that deployment Docker images exist and are accessible; promotes images between Artifactory repositories during environment promotion
- **Failure mode**: Image validation failure blocks deployment execution
- **Circuit breaker**: No

### AWS S3 Detail

- **Protocol**: AWS SDK (HTTPS)
- **Base URL / SDK**: aws/aws-sdk-go 1.42.10
- **Auth**: AWS credentials (IAM role or access key)
- **Purpose**: Uploads deployment log files to S3 for long-term archival after deployment finalizes
- **Failure mode**: S3 upload failure is logged; deployment outcome is not affected but log archival may be incomplete
- **Circuit breaker**: No

### PEST Detail

- **Protocol**: REST / Event bus (HTTPS)
- **Base URL / SDK**: PEST API
- **Auth**: Service credentials
- **Purpose**: Publishes `deploy_start` and `deploy_complete` lifecycle events for downstream consumers
- **Failure mode**: PEST unavailability is non-blocking; event publication failure is logged
- **Circuit breaker**: No

### ProdCAT Detail

- **Protocol**: REST (HTTPS)
- **Base URL / SDK**: ProdCAT API
- **Auth**: Service credentials
- **Purpose**: Validates production readiness gates before a deployment to production proceeds
- **Failure mode**: ProdCAT check failure blocks deployment; deployment remains in validating state until resolved or overridden
- **Circuit breaker**: No

### Conveyor CI Detail

- **Protocol**: REST (HTTPS)
- **Base URL / SDK**: Conveyor Cloud API
- **Auth**: Service credentials
- **Purpose**: Queries active maintenance windows to block deployments during maintenance; also surfaces CI build status
- **Failure mode**: Conveyor API unavailability may block or skip maintenance window check depending on configuration
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Service Portal | REST (HTTPS) | Looks up service metadata for a project being deployed | stub |
| Artifactory | REST (HTTPS) | Validates and promotes deployment images | stub |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

- GitHub sends push webhook events to `POST /request/webhook`
- Internal automation and CI pipelines call `POST /v1/request` for programmatic deployments

## Dependency Health

> No evidence found in codebase for circuit breakers, retry policies, or automated dependency health checks. Dependencies that fail cause the deployment to fail or the validation gate to block. Failures are recorded in deployment logs and MySQL audit records.
