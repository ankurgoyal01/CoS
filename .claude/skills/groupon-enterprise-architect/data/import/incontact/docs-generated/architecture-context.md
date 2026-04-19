---
service: "incontact"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumIncontactService]
---

# Architecture Context

## System Context

InContact is modelled as a container within the `continuumSystem` software system (Groupon's core commerce engine). It represents the boundary of the third-party SaaS contact centre platform consumed by Groupon's GSS team. The service has declared dependencies on two internal Continuum services — `ogwall` and `global_support_systems` — though these relationships are currently marked as stub-only in the architecture model and are not yet fully elaborated with protocol or data-flow details.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| InContact | `continuumIncontactService` | Service | SaaS Platform | N/A | SaaS Platform service represented by this repository. Provides cloud contact centre capabilities for GSS. |

## Components by Container

### InContact (`continuumIncontactService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| .service.yml Definition | Service metadata, ownership, and declared dependencies for InContact | YAML Configuration |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumIncontactService` | `ogwall` | Depends on (stub-only — not yet elaborated) | Unknown |
| `continuumIncontactService` | `global_support_systems` | Depends on (stub-only — not yet elaborated) | Unknown |

> Note: Both relationships are recorded as `[stub-only]` in the architecture DSL (`models/relations.dsl`). Full protocol and data-flow details are pending elaboration by the GSS team.

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-incontact-repo-component`
