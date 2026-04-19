---
service: "elit-github-app"
title: "ELIT GitHub App Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumElitGithubAppService"]
tech_stack:
  language: "Java 17"
  framework: "JTier / Dropwizard"
  runtime: "JVM 17 (Eclipse Temurin / Alpine)"
---

# ELIT GitHub App Documentation

A GitHub App service that receives webhook events from GitHub Enterprise, scans pull request diffs for non-inclusive language violations according to ELIT (Equitable Language in Tech) guidelines, and reports results as GitHub Checks with inline annotations.

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
| Language | Java 17 |
| Framework | JTier / Dropwizard |
| Runtime | JVM 17 (Alpine-based Docker) |
| Build tool | Maven 3.6.3 |
| Platform | Continuum |
| Domain | Developer Tooling / Engineering Effectiveness |
| Team | alasdair@groupon.com |
