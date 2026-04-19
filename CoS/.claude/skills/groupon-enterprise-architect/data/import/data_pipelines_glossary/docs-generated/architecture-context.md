---
service: "data_pipelines_glossary"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["dataPipelinesGlossary"]
---

# Architecture Context

## System Context

The Data Pipelines Glossary is a container within the `continuumSystem` — Groupon's core commerce and data platform. It sits at the boundary of the data engineering domain and serves as a static navigational resource. It has no runtime relationships with other containers; its role is purely informational, linking engineers to the appropriate workflow repositories within the broader data platform.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Data Pipelines Glossary | `dataPipelinesGlossary` | Documentation | Static site | N/A | Point of entry and navigation to workflow repositories in the data platform. |

## Components by Container

### Data Pipelines Glossary (`dataPipelinesGlossary`)

> No evidence found in codebase. The DSL declares no components for this container (`// No components defined for this repository.`).

## Key Relationships

> No evidence found in codebase. The DSL declares no container relations (`// No container relations defined.`) and no component-level relations (`// No component-to-component relations defined.`).

## Architecture Diagram References

- Container: `data_pipelines_glossary_container`
- Component: `data_pipelines_glossary_container` (container view; no dedicated component view)
