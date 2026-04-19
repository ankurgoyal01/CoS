---
service: "web-config"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 1
---

# Integrations

## Overview

web-config has four integration points: one internal Continuum service (`apiProxy`) that receives the generated config, and three external systems used by the Redirect Automation CLI — Jira (ticket source), GitHub Enterprise (PR creation), and AWS Secrets Manager (credential retrieval). All integrations are synchronous; there is no async messaging.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Jira (continuumJiraService) | HTTPS REST | Reads `MESH` project redirect/legal-redirect tickets in `To Do` status; updates ticket status and posts comments after PR creation | yes | `continuumJiraService` |
| GitHub Enterprise | Git + HTTPS REST | Creates branches, commits rewrite rule changes, and opens pull requests against the `routing/web-config` repository | yes | `githubEnterprise` |
| AWS Secrets Manager | AWS SDK (HTTPS) | Retrieves the `hybrid-boundary-svc-user-jira` secret containing the Jira API token for the `svc_hbuser` service account | yes | `cloudPlatform` |

### Jira Detail

- **Protocol**: HTTPS REST (go-jira library)
- **Base URL**: Configured per environment in `conf/config_{environment}.yaml` (`jira_url` field)
- **Auth**: Basic authentication — dedicated Jira service account with token read from AWS Secrets Manager; injected via custom `APITransport` RoundTripper adding `X-OpenID-Extras`, `X-Grpn-Samaccountname`, `X-Remote-User`, and `Authorization: Basic` headers
- **Purpose**: Queries `project = 'MESH' AND status IN ('To Do') AND component IN ('Redirects', 'Legal Redirects')` for pending redirect work; after PR creation, transitions each ticket to `In PR - Needs Review` and posts a comment with the PR URL
- **Failure mode**: CLI aborts with an error message; no redirects are generated or committed
- **Circuit breaker**: No evidence found

### GitHub Enterprise Detail

- **Protocol**: Git (SSH for push) + HTTPS REST (go-github library)
- **Base URL**: `https://github.groupondev.com/api/v3`
- **Auth**: OAuth2 bearer token from `REDIRECT_API_TOKEN` environment variable; SSH key from `svcdcos-ssh` Jenkins credential for git push
- **Purpose**: Creates a feature branch named `{user_initials}/{JIRA_KEY}`, commits updated rewrite data files, pushes branch to `github.groupondev.com/routing/web-config`, and opens a pull request against `master`
- **Failure mode**: CLI prints error and returns; no Jira status updates are performed if PR creation fails
- **Circuit breaker**: No evidence found

### AWS Secrets Manager Detail

- **Protocol**: AWS SDK (HTTPS, us-west-2 by default, overridable with `-r`)
- **Base URL / SDK**: `github.com/aws/aws-sdk-go/service/secretsmanager`
- **Auth**: IAM role credentials from the execution environment
- **Purpose**: Retrieves the JSON secret `hybrid-boundary-svc-user-jira` to obtain the Jira API token for the `svc_hbuser` service account
- **Failure mode**: Panics with a descriptive AWS error code (DecryptionFailure, ResourceNotFoundException, etc.)
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| apiProxy (grout) | SSH/Fabric | Receives generated nginx config and error pages; config is deployed to `/var/groupon/nginx/conf` on routing hosts via Fabric SSH tasks | `apiProxy` |

### apiProxy Detail

- **Protocol**: SSH (Fabric paramiko transport); config files copied to `/var/groupon/routing-web-config/releases/{sha}/` and symlinked as current
- **Purpose**: The `apiProxy` nginx process reads config from the path that web-config deploys to; after deploy, nginx is reloaded via `/usr/local/etc/init.d/nginx reload`
- **Failure mode**: `nginx -t` config validation runs before deploy; if validation fails the Fabric task aborts and the existing config remains active

## Consumed By

> Upstream consumers are tracked in the central architecture model. The generated Docker images are consumed by the `routing-deployment` Kubernetes manifest repository via kustomize image-tag updates triggered by the Jenkins pipeline.

## Dependency Health

- **Jira**: No health-check endpoint polled; failures surface as Go runtime errors at CLI startup.
- **GitHub Enterprise**: PR creation failure is logged and reported to the operator; the operator must manually intervene.
- **AWS Secrets Manager**: Connection failure causes a panic; the operator must verify IAM permissions and network connectivity.
- **apiProxy / routing hosts**: nginx config validation (`nginx -t`) acts as a pre-deployment health gate; a failed validation prevents config delivery.
