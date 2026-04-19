---
service: "releasegen"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumReleasegenService"]
---

# Architecture Context

## System Context

Releasegen sits within the Continuum platform as a Release Engineering utility service. It is deployed independently on Kubernetes and interacts with three external systems: Deploybot (to query deployment records), GitHub Enterprise (to create releases and deployment statuses), and JIRA (to label tickets and add release links). No other internal Continuum microservices call Releasegen's API at runtime; it is instead triggered by Deploybot events and its own background polling worker.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Releasegen Service | `continuumReleasegenService` | Service | Java, Dropwizard | 1.0.x | Dropwizard service that synchronizes deployment state across Deploybot, GitHub Releases, and JIRA |

## Components by Container

### Releasegen Service (`continuumReleasegenService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| HTTP Resources (`releasegen_apiResources`) | Routes all inbound JAX-RS requests to the appropriate sub-resource | Dropwizard / Jersey |
| Admin Resource (`adminResource`) | Provides admin-only endpoints for listing and reprocessing Deploybot records | Dropwizard / Jersey |
| Deploybot Resource (`deploybotResource`) | Exposes deployment lookup by org, project, and ID | Dropwizard / Jersey |
| Deployment Resource (`deploymentResource`) | Accepts explicit deployment publication requests | Dropwizard / Jersey |
| Jira Resource (`jiraResource`) | Exposes JIRA release ticket query endpoints | Dropwizard / Jersey |
| Worker Resource (`workerResource`) | Controls the lifecycle (start / stop) of the background polling worker | Dropwizard / Jersey |
| Deployment Service (`deploymentService`) | Coordinates Deploybot, GitHub, and JIRA updates for a single deployment event | Service |
| Deploybot Service (`deploybotClient`) | Wraps the Deploybot REST API via Retrofit | Retrofit |
| GitHub Service (`releasegen_gitHubService`) | Manages GitHub App authentication, release creation, and deployment status recording | Service |
| Jira Service (`releasegen_jiraService`) | Wraps the JIRA REST API via Retrofit for issue search, labeling, and remote links | Retrofit |
| Deployment Worker (`deploymentWorker`) | Orchestrates the polling-and-publishing pipeline using a cached thread pool | Worker |
| Jira Deployment Source (`jiraDeploymentSource`) | Polls JIRA for unprocessed RE-project tickets and resolves corresponding Deploybot deployment records | Worker |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `releasegen_apiResources` | `deploybotClient` | Reads deployment details | REST (Retrofit) |
| `releasegen_apiResources` | `releasegen_jiraService` | Queries JIRA issues and tickets | REST (Retrofit) |
| `releasegen_apiResources` | `deploymentService` | Manages release and deployment publication | In-process |
| `adminResource` | `deploybotClient` | Triggers Deploybot refresh | REST (Retrofit) |
| `deploymentResource` | `deploymentService` | Publishes deployments | In-process |
| `jiraResource` | `releasegen_jiraService` | Queries and updates JIRA issues | REST (Retrofit) |
| `workerResource` | `deploymentWorker` | Controls worker lifecycle | In-process |
| `deploymentWorker` | `jiraDeploymentSource` | Polls for release issues | In-process |
| `deploymentWorker` | `deploymentService` | Publishes deployments after polling | In-process |
| `jiraDeploymentSource` | `releasegen_jiraService` | Loads JIRA RE-project release issues | REST (Retrofit) |
| `jiraDeploymentSource` | `deploybotClient` | Fetches deployment data by ID | REST (Retrofit) |
| `deploymentService` | `deploybotClient` | Reads deployment metadata | REST (Retrofit) |
| `deploymentService` | `releasegen_gitHubService` | Creates GitHub releases and deployment statuses | GitHub API |
| `deploymentService` | `releasegen_jiraService` | Labels tickets and adds remote release links | REST (Retrofit) |
| `continuumReleasegenService` | `deploybotSystem_7f4e` | Fetches deployment data from Deploybot | REST |
| `continuumReleasegenService` | `githubSystem_3a1b` | Creates releases and deployment statuses in GitHub | GitHub REST / App API |
| `continuumReleasegenService` | `jiraSystem_9c2d` | Reads and updates release tickets in JIRA | REST |

## Architecture Diagram References

- Component: `components-releasegen-service`
