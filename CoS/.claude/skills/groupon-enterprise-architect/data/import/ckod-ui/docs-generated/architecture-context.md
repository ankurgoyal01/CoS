---
service: "ckod-ui"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumCkodUi, continuumCkodPrimaryMysql, continuumCkodAirflowMysql]
---

# Architecture Context

## System Context

ckod-ui sits within the **Continuum** platform as the primary operational UI for Groupon's data engineering and PRE team. It is accessed directly by administrators and engineers via browser over HTTPS. The application mediates all interactions between human operators and the underlying data systems — including two owned MySQL databases, the internal CKOD backend API (JTier service), and a set of external SaaS and internal platform integrations (JIRA, Keboola, Vertex AI, GitHub Enterprise, Google Chat).

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| ckod-ui | `continuumCkodUi` | Web Application | TypeScript, Next.js | Next.js application serving the DataOps UI and server-side API route handlers |
| CKOD Primary MySQL | `continuumCkodPrimaryMysql` | Database | MySQL | Read/write and read-only CKOD relational data store for SLO definitions, deployments, incidents, teams |
| CKOD Airflow MySQL | `continuumCkodAirflowMysql` | Database | MySQL | Read/write and read-only Airflow-related CKOD relational data store for pipeline SLO monitoring |

## Components by Container

### ckod-ui (`continuumCkodUi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Web UI (`ckodUi_webUi`) | Next.js App Router pages and React components for all user interactions across dashboards | React, Next.js App Router |
| API Routes (`ckodUi_apiRoutes`) | Next.js route handlers under `/app/api` exposing all DataOps operations APIs consumed by the Web UI via RTK Query | Next.js Route Handlers |
| Authentication and Authorization (`authz`) | Header token checks (`x-grpn-email`, `ckod-token`) and team-based access control for protected workflows | TypeScript Module (`src/lib/auth.ts`, `src/lib/authorization.ts`) |
| Deployment Orchestration (`deploymentOrchestration`) | Deployment creation, validation, JIRA ticket workflow, and SOX compliance logic for Airflow and Keboola | TypeScript Services (`src/lib/external-apis/`) |
| Handover Notes Service (`handoverNotes`) | AI-backed handover note generation using LiteLLM, and Google Chat card composition for sharing | TypeScript Services (`src/lib/handitover/`) |
| External Integration Adapters (`integrationAdapters`) | Dedicated client modules for Jira, JSM, Deploybot, GitHub, Keboola, Vertex AI, Google Chat, and LiteLLM | TypeScript Clients (`src/lib/external-apis/*.ts`) |
| Data Access Layer (`ckodUi_dataAccess`) | Dual Prisma clients (`prismaRO`, `prismaRW`) for MySQL access; schema in `prisma/schema.prisma` | Prisma, MySQL |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `administrator` | `continuumCkodUi` | Uses CKOD UI and operational APIs | HTTPS |
| `continuumCkodUi` | `continuumCkodPrimaryMysql` | Reads and writes CKOD domain data (SLOs, deployments, incidents, teams) | Prisma / MySQL |
| `continuumCkodUi` | `continuumCkodAirflowMysql` | Reads and writes Airflow-related SLO data | Prisma / MySQL |
| `continuumCkodUi` | `continuumCkodBackendJtier` | Calls CKOD backend endpoints | HTTPS REST |
| `continuumCkodUi` | `continuumJiraService` | Creates and links tickets through Jira REST APIs | HTTPS REST |
| `continuumCkodUi` | `jsmOps` | Retrieves alerts and on-call data | HTTPS REST |
| `continuumCkodUi` | `githubEnterprise` | Retrieves repository metadata and diffs | HTTPS REST |
| `continuumCkodUi` | `googleChat` | Sends deployment and handover notifications | HTTPS Webhook |
| `continuumCkodUi` | `keboola` | Reads project branch/component data for deployment workflows | HTTPS REST |
| `continuumCkodUi` | `vertexAi` | Streams chat requests to reasoning engines | HTTPS / streaming |

> Note: Deploybot and LiteLLM Proxy are consumed by `continuumCkodUi` (via integration adapters) but are stub-only in the central model — they do not appear as named containers in the primary DSL.

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-continuumCkodUi`
- Dynamic view: `dynamic-deployment-workflow` (deployment request flow through Web UI and API Routes)
