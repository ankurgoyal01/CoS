---
service: "ckod-ui"
title: "ckod-ui Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumCkodUi, continuumCkodPrimaryMysql, continuumCkodAirflowMysql]
tech_stack:
  language: "TypeScript 5.9.3"
  framework: "Next.js 15.3.0"
  runtime: "Node.js 18 (Docker), 20.10+ (local)"
---

# ckod-ui (DataOps) Documentation

DataOps is a Next.js monitoring and control centre for Groupon's critical data pipelines, providing SLO/SLA dashboards, deployment orchestration, incident management, cost alerting, and AI-assisted handover capabilities across Keboola and Airflow platforms.

## Contents

| Document | Description |
|----------|-------------|
| [Overview](overview.md) | Service identity, purpose, domain context, tech stack |
| [Architecture Context](architecture-context.md) | Containers, components, C4 references |
| [API Surface](api-surface.md) | Endpoints, contracts, protocols |
| [Events](events.md) | Async messages published and consumed |
| [Data Stores](data-stores.md) | Databases, caches, storage |
| [Integrations](integrations.md) | External and internal dependencies |
| [Configuration](configuration.md) | Environment, flags, secrets |
| [Flows](flows/index.md) | Process and flow documentation |
| [Deployment](deployment.md) | Infrastructure and environments |
| [Runbook](runbook.md) | Operations, monitoring, troubleshooting |

## Quick Facts

| Property | Value |
|----------|-------|
| Language | TypeScript 5.9.3 |
| Framework | Next.js 15.3.0 |
| Runtime | Node.js 18 (Docker), 20.10+ (local) |
| Build tool | npm + Jenkins (dockerBuildPipeline) |
| Platform | Continuum (DataOps domain) |
| Domain | Data Platform Operations |
| Team | PRE (Platform Reliability Engineering) |
