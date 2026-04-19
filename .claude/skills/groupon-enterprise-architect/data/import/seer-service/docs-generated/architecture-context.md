---
service: "seer-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSeerService"
  containers: [continuumSeerService, continuumSeerServicePostgres]
---

# Architecture Context

## System Context

Seer Service sits within the Continuum platform as an internal engineering-effectiveness tool. It has no public-facing traffic; all consumers are internal Groupon teams and dashboards. The service reaches outward to six external developer-tooling systems (Jira, Jenkins, GitHub Enterprise, Deploybot, OpsGenie, SonarQube) and one internal platform service (Service Portal) to collect engineering metrics. Data flows inward only — Seer reads from all dependencies and writes to its own PostgreSQL store. No downstream services are called as a result of a Seer write.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Seer Service | `continuumSeerService` | Backend service | Java, Dropwizard | 1.0.x | Aggregates engineering metrics and operational data from Jira, Jenkins, GitHub, Deploybot, OpsGenie, SonarQube, and Service Portal |
| Seer Service Postgres | `continuumSeerServicePostgres` | Database | PostgreSQL | — | Stores Seer metrics, reports, and integration data |

## Components by Container

### Seer Service (`continuumSeerService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Resources (`seerApiResources`) | Jersey resources exposing REST endpoints for Jira, Jenkins, Deploybot, OpsGenie, Service Portal, SonarQube, and GitHub | JAX-RS |
| Quartz Jobs (`seerJobs`) | Scheduled jobs for weekly ingestion of incident, build, deployment, pull-request, and sprint data | Quartz |
| Jira Service (`seerService_jiraService`) | Integrates with Jira APIs to fetch sprints, issues, incidents, and reports | Retrofit |
| Jenkins Service (`jenkinsService`) | Fetches Jenkins build data and metrics | Retrofit |
| GitHub Service (`seerService_gitHubService`) | Fetches pull-request data and enriches it with service metadata from Service Portal | Retrofit |
| Deploybot Service (`seerService_deploybotClient`) | Fetches deployment information per service and environment | Retrofit |
| OpsGenie Service (`opsGenieService`) | Fetches alert, team, and member information | Retrofit |
| SonarQube Service (`sonarQubeService`) | Fetches code-quality metrics per project | Retrofit |
| Service Portal Service (`servicePortalService`) | Fetches service ownership and metadata; used by GitHub and Deploybot services | Retrofit |
| Persistence Layer (`seerDaos`) | JDBI 3 DAO interfaces for all stored entities (sprints, issues, incidents, builds, deployments, PRs, alerts, quality metrics) | JDBI |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumSeerService` | `continuumSeerServicePostgres` | Reads and writes Seer metrics and reports | JDBC |
| `continuumSeerService` | `githubEnterprise` | Fetches pull-request data | HTTP/JSON |
| `continuumSeerService` | `servicePortal` | Fetches service metadata | HTTP/JSON |
| `continuumSeerService` | `jiraSystem_4c1a` | Syncs sprints, issues, and incidents (stub — not in federated model) | HTTP/JSON |
| `continuumSeerService` | `jenkinsSystem_6a30` | Fetches build data (stub — not in federated model) | HTTP/JSON |
| `continuumSeerService` | `deploybotSystem_1d7f` | Fetches deployment metadata (stub — not in federated model) | HTTP/JSON |
| `continuumSeerService` | `opsGenieSystem_5c2e` | Fetches alert data (stub — not in federated model) | HTTP/JSON |
| `continuumSeerService` | `sonarQubeSystem_84f2` | Fetches quality metrics (stub — not in federated model) | HTTP/JSON |
| `seerApiResources` | `seerService_jiraService` | Invokes Jira data retrieval | direct |
| `seerApiResources` | `jenkinsService` | Invokes build reporting | direct |
| `seerApiResources` | `seerService_gitHubService` | Invokes pull-request reporting | direct |
| `seerApiResources` | `seerService_deploybotClient` | Invokes deployment reporting | direct |
| `seerApiResources` | `opsGenieService` | Invokes alert reporting | direct |
| `seerApiResources` | `sonarQubeService` | Invokes quality metrics reporting | direct |
| `seerApiResources` | `servicePortalService` | Invokes service metadata lookups | direct |
| `seerJobs` | `seerService_jiraService` | Ingests sprint and incident data on schedule | direct |
| `seerJobs` | `jenkinsService` | Ingests build data on schedule | direct |
| `seerJobs` | `seerService_gitHubService` | Ingests pull-request data on schedule | direct |
| `seerJobs` | `seerService_deploybotClient` | Ingests deployment data on schedule | direct |
| `seerJobs` | `opsGenieService` | Ingests alert data on schedule | direct |
| `seerService_gitHubService` | `servicePortalService` | Resolves service ownership metadata | direct |
| `seerService_deploybotClient` | `servicePortalService` | Resolves service ownership metadata | direct |

## Architecture Diagram References

- System context: `contexts-seerService`
- Container: `containers-seerService`
- Component: `components-seerService` (view declaration currently disabled — see `architecture/views/components/seerService.dsl`)
