---
service: "ckod-ui"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Data Platform Operations"
platform: "Continuum"
team: "PRE (Platform Reliability Engineering)"
status: active
tech_stack:
  language: "TypeScript"
  language_version: "5.9.3"
  framework: "Next.js"
  framework_version: "15.3.0"
  runtime: "Node.js"
  runtime_version: "18 (Docker), 20.10+ (local)"
  build_tool: "npm + Jenkins dockerBuildPipeline"
  package_manager: "npm"
---

# ckod-ui (DataOps) Overview

## Purpose

ckod-ui (internally called DataOps) is a Next.js full-stack web application that serves as a monitoring and control centre for Groupon's critical data pipelines. It provides centralised dashboards for SLO/SLA compliance tracking across multiple platforms (Keboola, Airflow, EDW, SEM, RM, OP, CDP, MDS Feeds), supports deployment orchestration for both Airflow DAGs and Keboola flows, manages incident records via JIRA integration, and surfaces BigQuery cost alerts. The application also includes an AI-assisted "Hand It Over" feature for team handover management using Vertex AI and LiteLLM.

## Scope

### In scope
- Multi-platform SLO/SLA monitoring dashboards (Keboola, EDW, SEM, RM, OP, CDP, MDS Feeds, Airflow)
- SLO threshold management — creating, editing, and soft-deleting SLO definitions
- Deployment tracking and creation for Airflow pipelines and Keboola flows
- Incident management via JIRA and JIRA Service Management (JSM) integration
- Cost alert monitoring with BigQuery telemetry
- Keboola project management (dependencies, documentation, team assignments)
- Google Cloud Vertex AI multi-agent chat interface
- Hand It Over — AI-backed team handover note generation with Google Chat sharing
- Team-based access control backed by MySQL (CKOD_TEAMS, CKOD_TEAM_MEMBERS)
- Server-side API routes (Next.js route handlers) that proxy to external services
- Winston-based structured logging to file (`/app/logs/ckod-ui.log`)

### Out of scope
- Actual pipeline execution (handled by Airflow / Keboola directly)
- Data warehouse ETL logic (handled by EDW systems)
- Long-term data storage or analytics (no owned data warehouse)
- Alert delivery mechanisms (alerts are read from JSM, not generated here)

## Domain Context

- **Business domain**: Data Platform Operations
- **Platform**: Continuum
- **Upstream consumers**: Groupon data engineering and PRE team operators (human users via browser)
- **Downstream dependencies**: `continuumCkodPrimaryMysql` (read/write), `continuumCkodAirflowMysql` (read/write), `continuumCkodBackendJtier` (CKOD API), JIRA Cloud, JSM Ops, GitHub Enterprise, Keboola Storage API, Deploybot, Google Chat, Vertex AI Reasoning Engine, LiteLLM Proxy

## Stakeholders

| Role | Description |
|------|-------------|
| Data Engineers (PRE team) | Primary users — deploy pipelines, monitor SLOs, manage incidents |
| On-call operators | Monitor SLA dashboards and receive handover summaries |
| Platform managers | Review cost alerts and deployment history |
| Service owner | PRE team (grp_conveyor_stable_ckod-ui, grp_conveyor_production_ckod-ui) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | TypeScript | 5.9.3 | `package.json` devDependencies |
| Framework | Next.js (App Router) | 15.3.0 | `package.json` dependencies |
| Runtime | Node.js | 18 (Docker), 20.10+ (local) | `Dockerfile`, `README.md` |
| ORM | Prisma | 6.10.0 | `package.json`, `prisma/schema.prisma` |
| Build tool | npm + Jenkins dockerBuildPipeline | — | `Jenkinsfile`, `package.json` scripts |
| Package manager | npm | — | `package-lock.json` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `@reduxjs/toolkit` | 2.7.0 | state-management | Redux state store and RTK Query API layer |
| `react-redux` | 9.2.0 | state-management | React bindings for Redux store |
| `next-redux-wrapper` | 8.1.0 | state-management | Redux integration for Next.js SSR |
| `@prisma/client` | 6.10.0 | orm | MySQL database access (read-only and read-write clients) |
| `zod` | 3.24.4 | validation | Schema validation for forms and agent configs |
| `react-hook-form` | 7.56.2 | ui-framework | Form state management with Zod resolver |
| `winston` | 3.17.0 | logging | Server-side structured logging to file and console |
| `google-auth-library` | 10.3.0 | auth | Google Cloud authentication for Vertex AI |
| `next-runtime-env` | 3.3.0 | configuration | Runtime environment variable access for client/server |
| `echarts-for-react` | 3.0.2 | ui-framework | Complex chart visualisations (SLO trend charts) |
| `recharts` | 2.15.3 | ui-framework | Simpler chart visualisations (cost metrics) |
| `date-fns` | 3.6.0 | serialization | Date formatting and manipulation for SLO timestamps |
| `sonner` | 2.0.3 | ui-framework | Toast notification system |
| `react-markdown` | 10.1.0 | ui-framework | Renders AI-generated handover note markdown |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `package.json` for a full list.
