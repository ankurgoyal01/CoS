---
service: "service-portal-mcp"
title: "service-portal-mcp Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "servicePortal"
  containers: [servicePortalMcpServer]
tech_stack:
  language: "Python 3.13.7"
  framework: "FastMCP 2.12.5"
  runtime: "Python 3.13.7"
---

# Service Portal MCP Documentation

MCP server providing AI-friendly access to Service Portal data, exposing service metadata, cost analysis, and API documentation as callable tools for AI agents and assistants.

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
| Language | Python 3.13.7 |
| Framework | FastMCP 2.12.5 |
| Runtime | Python 3.13.7 |
| Build tool | pip / pyproject.toml |
| Platform | Starlette ASGI |
| Domain | Service Discovery / Cost Analysis / API Documentation |
| Team | Platform Engineering |
