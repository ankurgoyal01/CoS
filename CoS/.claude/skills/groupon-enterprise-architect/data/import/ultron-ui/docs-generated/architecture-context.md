---
service: "ultron-ui"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumUltronUiWeb]
---

# Architecture Context

## System Context

Ultron UI sits within the Continuum platform as the operator-facing web console for the Ultron data integration job orchestration subsystem. Browser-based users (data engineers, platform operators) interact exclusively with this container. Ultron UI has no direct database connections; all state is retrieved from and persisted through `continuumUltronApi` over HTTP/JSON. There are no messaging systems in scope.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Ultron UI Web | `continuumUltronUiWeb` | WebApp | Play Framework, Java, AngularJS, Bootstrap | Play 2.4.8 / Java 8 | Stateless web application serving the job orchestration operator console |

## Components by Container

### Ultron UI Web (`continuumUltronUiWeb`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `playControllers` | Handles inbound HTTP requests, applies LDAP auth, proxies calls to Ultron API, returns JSON or rendered views | Play Framework (Java) |
| `uiTemplates` | Renders server-side HTML shell; hosts AngularJS SPA assets (JS, CSS, templates) | Play Twirl templates, AngularJS, Bootstrap 3.2.0 |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumUltronUiWeb` | `continuumUltronApi` | Uses — proxies all job, group, instance, lineage, and resource operations | HTTP/JSON |

## Architecture Diagram References

- System context: `contexts-ultron-ui`
- Container: `containers-ultron-ui`
- Component: `components-continuumUltronUiWeb`
