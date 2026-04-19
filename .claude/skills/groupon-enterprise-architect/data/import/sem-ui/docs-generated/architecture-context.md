---
service: "sem-ui"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumSemUiWebApp]
---

# Architecture Context

## System Context

SEM Admin UI is a Continuum-platform I-Tier web application that sits at the boundary between SEM operators (internal Groupon staff) and the SEM backend microservices. Operators access the dashboard in a browser; the application proxies their requests to the SEM Keywords Service, SEM Blacklist Service, and GPN Data API. It does not own any persistent data — all state lives in the downstream services.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| SEM Admin UI | `continuumSemUiWebApp` | WebApp | Node.js / Preact / I-Tier | 7.9.2 | I-Tier web application serving the SEM administration dashboard |

## Components by Container

### SEM Admin UI (`continuumSemUiWebApp`)

> No evidence found in codebase. Component-level breakdown is not yet modeled in the architecture DSL (`models/components.dsl` is empty).

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumSemUiWebApp` | `continuumSemBlacklistService` | Manages SEM denylist entries | HTTP/JSON |
| `continuumSemUiWebApp` | `semKeywordsService` | Reads and updates SEM keywords (stub — not in federated model) | HTTP/JSON |
| `continuumSemUiWebApp` | `gpnDataApi` | Fetches attribution order data (stub — not in federated model) | HTTP/JSON |

## Architecture Diagram References

- System context: `contexts-sem-ui`
- Container: `containers-sem-ui`
- Component: `components-sem-ui`
