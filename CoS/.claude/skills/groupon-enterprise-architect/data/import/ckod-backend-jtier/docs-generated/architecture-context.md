---
service: "ckod-backend-jtier"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumCkodBackendJtier", "continuumCkodMySql"]
---

# Architecture Context

## System Context

`ckod-backend-jtier` lives inside the `continuumSystem` (Continuum Platform) software system. It acts as the primary observability and deployment-tracking backend for Groupon's Keboola data platform projects. The service is deployed as two Kubernetes workloads — an HTTP API server (`app` component) and a background worker (`worker` component) — both running the same Docker image. It connects outward to five external systems: Keboola Cloud for job data, Jira Cloud for ticket management, GitHub Enterprise for diff metadata, Google Chat for notifications, and Deploybot for deployment payload metadata. All persistent state is stored in `continuumCkodMySql`, which the service owns exclusively.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| CKOD Backend JTier | `continuumCkodBackendJtier` | Backend API + Worker | Java 17, Dropwizard/JTier | 5.14.0 | JTier-based backend service exposing CKOD APIs for deployments, SLA data, costs, dependencies, and project metadata |
| CKOD MySQL | `continuumCkodMySql` | Database | MySQL | — | Primary operational datastore for deployment tracking, SLA entities, project metadata, and cost alerts |

## Components by Container

### CKOD Backend JTier (`continuumCkodBackendJtier`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Resources (`continuumCkodApiResources`) | Exposes REST endpoints for deployments, SLA reports, project metadata, dependencies, active users, and cost alerts | JAX-RS (Dropwizard/Jersey) |
| Domain Services (`continuumCkodDomainServices`) | Orchestrates tracker updates, ticket creation, notifications, and query workflows | Java Services |
| Persistence DAOs (`continuumCkodPersistenceDaos`) | DAO and ORM layers handling reads/writes for CKOD relational data | Hibernate/JPA/JDBI |
| Integration Clients (`continuumCkodIntegrationClients`) | HTTP clients used to call Jira, GitHub, Keboola, Deploybot, and Google Chat APIs | Apache HttpClient |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCkodBackendJtier` | `continuumCkodMySql` | Reads and writes deployment tracking, SLA, project, and cost data | JDBC/MySQL |
| `continuumCkodBackendJtier` | `continuumJiraService` | Creates and links deployment tickets; resolves account/on-call metadata | HTTPS/REST |
| `continuumCkodBackendJtier` | `githubEnterprise` | Retrieves compare commits and repository metadata for deployment diffs | HTTPS/REST |
| `continuumCkodBackendJtier` | `keboola` | Retrieves job runs, branches, and component metadata | HTTPS/REST |
| `continuumCkodBackendJtier` | `googleChat` | Sends deployment and incident notifications | HTTPS/REST |
| `continuumCkodApiResources` | `continuumCkodDomainServices` | Invokes application use cases | Direct (in-process) |
| `continuumCkodDomainServices` | `continuumCkodPersistenceDaos` | Reads and writes CKOD domain data | Direct (in-process) |
| `continuumCkodDomainServices` | `continuumCkodIntegrationClients` | Calls external provider APIs | Direct (in-process) |

## Architecture Diagram References

- Component: `components-continuumCkodBackendJtier-components`
- Dynamic flow: `dynamic-ckod-deployment-tracking-flow`
