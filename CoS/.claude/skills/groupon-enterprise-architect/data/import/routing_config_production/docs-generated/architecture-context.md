---
service: "routing_config_production"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["routingConfigProduction"]
---

# Architecture Context

## System Context

`routing_config_production` is a configuration artifact container within the `continuumSystem` (Continuum Platform). It does not serve user traffic directly; instead, it provides the compiled routing ruleset consumed by Groupon's routing service runtime nodes. Every inbound HTTP/HTTPS request to Groupon's consumer and merchant surfaces passes through the routing layer, which uses this config to determine which upstream application service receives the request. The config is loaded at service startup and can be hot-reloaded without restarting the routing nodes.

The container boundary is the Docker image (`docker-conveyor.groupondev.com/routing/routing-config:production_<version>`). This image contains the compiled Flexi configuration under `/var/conf` and is referenced by the routing-service deployment overlays for four production regions.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Routing Config Production | `routingConfigProduction` | Config | Flexi DSL / Docker (BusyBox 1.29.1) | — | Production routing configuration (Flexi) used by Groupon routing infrastructure. Compiled from ~65 per-application Flexi files and packaged as a Docker image. |

## Components by Container

### Routing Config Production (`routingConfigProduction`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Flexi application configs (`src/applications/*.flexi`) | Defines URL pattern groups, route-to-destination mappings, scheme enforcement, CORS, and header injection per application domain | Flexi DSL |
| Main include manifest (`src/applications/index.flexi`) | Aggregates all per-application Flexi files into a single compiled config | Flexi DSL |
| Template renderer (`render_templates.py`) | Applies Jinja2 templating to Flexi files before validation, enabling on-prem vs. cloud environment differences | Python 2.7 / Jinja2 2.10 |
| Validation task (`./gradlew validate`) | Compiles and validates the full Flexi config using the Grout Gradle plugin | Gradle / Grout 1.4.2 |
| Check-routes script (`bin/check-routes`) | Evaluates specific URLs against the compiled routing config for manual verification | Bash / Docker / `api-proxy-cli` |
| Deployment overlays (`routing-deployment` repo) | Kustomize overlays that set the versioned Docker image tag per environment | Kustomize |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `routingConfigProduction` | Routing service nodes (`routing-app[1-10].snc1`, `.sac1`, `.dub1`) | Provides compiled routing config bundle via SSH-based deploy (on-prem) | SSH / tarball |
| `routingConfigProduction` | `routing-deployment` Kustomize overlays | Provides Docker image reference for Kubernetes-based routing nodes | Container registry / Git tagging |
| Routing service nodes | `routingConfigProduction` | Hot-reload of config via `POST localhost:9001/config/routes/reload` | HTTP (localhost) |
| CI pipeline (Jenkins) | `docker-conveyor.groupondev.com` | Publishes versioned Docker image `routing/routing-config:production_<version>` | Docker push / HTTPS |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-routingConfigProduction`
- Component: `components-routingConfigProduction`
