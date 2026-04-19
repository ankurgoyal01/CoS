---
service: "cloud-ui"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 1
---

# Integrations

## Overview

The Cloud Backend API integrates with four external systems: Jenkins for build status tracking, Artifactory for Helm chart metadata and archive downloads, Git repositories over SSH for GitOps config commits, and Deploybot for surfacing deployment URLs. The Cloud UI frontend integrates internally with the Cloud Backend API over HTTPS/JSON.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Jenkins | REST/HTTP | Poll build status and locate builds by commit hash | Yes | `jenkinsController` |
| Artifactory Helm Registry | REST/HTTP | Retrieve chart index, version metadata, and download chart archives | Yes | (stub) `artifactorySystem` |
| Git Repositories | SSH Git | Clone, commit, and push generated Helm values config files for GitOps pipeline | Yes | (stub) `gitRepositorySystem` |
| Deploybot | HTTPS | Construct deployment trigger URL when Jenkins build reaches `ready_to_deploy` | Yes | (stub) `deploybotSystem` |

### Jenkins Detail

- **Protocol**: HTTPS/Jenkins REST API
- **Base URL**: `https://cloud-jenkins.groupondev.com` (hardcoded in `deployment_status.go`)
- **Auth**: No auth credentials observed in code; expected to be network-level or environment-injected
- **Purpose**: Poll Jenkins to find the build corresponding to a Git commit hash; advance deployment phase from `synced` → `building` → `ready_to_deploy` or `failed`; retrieve build number and build URL for display in the UI
- **Failure mode**: If Jenkins is unreachable or the build is not found within 5 minutes of the `synced` phase, the deployment is marked `failed` with an error message; subsequent status polls will not retry
- **Circuit breaker**: No circuit breaker configured

### Artifactory Helm Registry Detail

- **Protocol**: HTTPS/Helm repository protocol (index.yaml + chart archive download)
- **Base URL**: `https://artifactory.groupondev.com/artifactory/list/helm-generic/` (constant `DefaultArtifactoryURL` in `helm.go`)
- **Auth**: No explicit credentials in code; assumed network-level access within Groupon infrastructure
- **Purpose**: Fetch the Helm repository index to look up chart versions for `cmf-generic-api` and `cmf-generic-worker`; download `.tgz` chart archives for manifest rendering; validate that a specific chart version exists
- **Failure mode**: Chart operations fail with an internal error; the Helm cache (6-hour index TTL, 24-hour chart TTL) reduces dependency on availability during normal rendering
- **Circuit breaker**: No circuit breaker configured; in-memory and filesystem caches provide partial resilience

### Git Repositories Detail

- **Protocol**: SSH Git (`go-git` v5 with `ssh.PublicKeys` auth)
- **Auth**: SSH private key loaded from Encore secret `CloudBackendGitSSHKey`; key content is written to a temporary file and cached for the process lifetime
- **Purpose**: Clone application main repository and secrets repository; generate environment-specific Helm values YAML files; commit and push config changes as part of the GitOps sync flow
- **Failure mode**: Sync operation fails with an error; deployment phase remains at `syncing` / `failed`; sync lock on the application is released on failure
- **Circuit breaker**: No circuit breaker; a per-application sync lock (`sync_in_progress` flag) prevents concurrent sync operations on the same application

### Deploybot Detail

- **Protocol**: HTTPS URL construction (no direct HTTP calls from backend)
- **Base URL pattern**: `https://deploybot.groupondev.com/{organizationId}/{applicationId}`
- **Auth**: Not applicable — the backend only constructs the URL and returns it to the frontend; the engineer clicks through to Deploybot directly
- **Purpose**: Surface the Deploybot deployment trigger URL in the UI when a Jenkins build completes successfully (`ready_to_deploy` phase)
- **Failure mode**: Not applicable — no runtime dependency; URL construction is pure string formatting

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Cloud Backend API | HTTPS/JSON | Provides all data and operations for the Cloud UI frontend: application CRUD, deployment lifecycle, Git sync, Helm rendering, and status polling | `continuumCloudBackendApi` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. The Cloud UI is intended for use by internal platform engineers and application team members via web browser.

## Dependency Health

- **Jenkins**: The `backendDeploymentStatusApi` component polls Jenkins on each `GET /cloud-backend/deployments/:deploymentId/status` call when phase is `synced` or `building`. A 5-minute stale-lock timeout exists to mark stuck deployments as failed.
- **Artifactory**: Protected by two-layer caching (in-memory index cache, filesystem chart cache). Cache can be manually purged via `POST /cloud-backend/helm/clear-cache`.
- **Git**: The `backendGitSyncApi` acquires a per-application sync lock in PostgreSQL before cloning; the lock is released on success or failure to prevent deadlock.
- **PostgreSQL**: No explicit connection health retry logic observed; Encore framework manages the connection pool. The `GET /cloud-backend/ready` endpoint reports database health.
