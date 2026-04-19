---
service: "cloud-ui"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumCloudUi, continuumCloudBackendApi, continuumCloudBackendPostgres]
---

# Architecture Context

## System Context

Cloud UI is a subsystem of the Continuum Platform (`continuumSystem`). It consists of two runtime containers: a Next.js web application (`continuumCloudUi`) serving the browser-facing management interface, and an Encore Go API (`continuumCloudBackendApi`) that handles all persistent state, GitOps operations, and Helm orchestration. Platform engineers and application teams access Cloud UI through a browser. The backend API integrates outward to Git repositories (SSH), Jenkins for build tracking, Deploybot for deployment delivery, and Artifactory for Helm chart metadata.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Cloud UI Web App | `continuumCloudUi` | WebApp | TypeScript, Next.js | 14 | Next.js App Router web application serving the management UI; contains API routes for runtime config and local health |
| Cloud Backend API | `continuumCloudBackendApi` | Backend | Go, Encore | latest | Encore Go API service managing application lifecycle, deployment workflow, Git sync, and Helm operations |
| Cloud Backend PostgreSQL | `continuumCloudBackendPostgres` | Database | PostgreSQL | latest | Primary relational datastore for applications, organizations, deployments, and sync state |

## Components by Container

### Cloud UI Web App (`continuumCloudUi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `cloudUiPages` | Next.js App Router pages and React UI components driving workflows for applications, organizations, and deployments | TypeScript, React |
| `cloudUiApiRoutes` | Server-side route handlers exposing runtime config (`/api/config`) and local health (`/api/health`) to the frontend | Next.js Route Handlers |
| `cloudUiConfigManager` | Resolves backend API base URL from server route or environment variables at runtime | TypeScript |
| `cloudUiApiClient` | Typed fetch client for cloud-backend application, organization, deployment, and status endpoints | TypeScript Fetch Client |
| `cloudUiHelmClient` | Typed fetch client for cloud-backend Helm chart selection and template rendering endpoints | TypeScript Fetch Client |

### Cloud Backend API (`continuumCloudBackendApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `backendApplicationsApi` | Encore endpoints for CRUD operations on applications and deployments; core health and readiness checks | Go, Encore |
| `backendGitSyncApi` | Encore endpoint and workflow that generates Helm values files, commits to Git repositories, and manages sync locks | Go, go-git |
| `backendDeploymentStatusApi` | Encore endpoint tracking deployment phase and enriching status via Jenkins polling | Go, Encore |
| `backendHelmApi` | Encore endpoints for chart selection, version validation, values rendering, and full manifest rendering | Go, Encore |
| `backendConfigDiffApi` | Encore endpoint computing differences between current configuration and last deployment snapshot | Go, Encore |
| `backendValidation` | Shared validation for request structures, port ranges, image registry format, and configuration constraints | Go |
| `backendPostgresAccess` | SQL access through Encore sqldb and repository functions for persistent state | Go, PostgreSQL |
| `backendJenkinsClient` | HTTP client wrapper for Jenkins build discovery and status inspection | Go, net/http |
| `backendHelmAdapter` | Maps UI component configuration to Helm values and template render requests | Go, Helm SDK |
| `backendArtifactoryClient` | Retrieves Helm chart index and version metadata from Artifactory with in-memory caching | Go, Helm repo client |
| `backendConfigDiffService` | Domain service computing semantic diffs for application configuration | Go |
| `backendYamlService` | Filesystem/YAML utility for normalized config serialization and parsing | Go |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCloudUi` | `continuumCloudBackendApi` | Calls REST endpoints for application, organization, deployment, and Helm workflows | HTTPS/JSON |
| `continuumCloudBackendApi` | `continuumCloudBackendPostgres` | Stores and queries applications, deployments, organizations, sync locks, and deployment phases | SQL |
| `continuumCloudBackendApi` | `jenkinsController` | Reads build status and metadata for deployment tracking | HTTPS/Jenkins API |
| `cloudUiPages` | `cloudUiApiClient` | Uses API client methods to load and mutate application and deployment data | In-process |
| `cloudUiPages` | `cloudUiHelmClient` | Uses Helm client methods for chart selection and template rendering previews | In-process |
| `cloudUiApiClient` | `cloudUiConfigManager` | Reads backend base URL configuration at runtime | In-process |
| `backendApplicationsApi` | `backendPostgresAccess` | Reads and writes application and deployment records | In-process/SQL |
| `backendGitSyncApi` | `backendHelmAdapter` | Renders component Helm values for Git repository commits | In-process |
| `backendDeploymentStatusApi` | `backendJenkinsClient` | Polls Jenkins build status by commit hash and job name | In-process/HTTP |
| `backendHelmApi` | `backendArtifactoryClient` | Retrieves chart indexes and versions from Artifactory | In-process/HTTP |
| `backendConfigDiffApi` | `backendConfigDiffService` | Computes current vs. deployed configuration differences | In-process |

## Architecture Diagram References

- Component view (Cloud UI): `components-cloud-ui`
- Component view (Cloud Backend): `components-cloud-backend-backendApplicationsApi`
- Dynamic view (GitOps deployment flow): `dynamic-gitops-deployment-flow`
