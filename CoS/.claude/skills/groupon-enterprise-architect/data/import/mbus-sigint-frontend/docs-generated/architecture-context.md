---
service: "mbus-sigint-frontend"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumMbusSigintFrontend"]
---

# Architecture Context

## System Context

`continuumMbusSigintFrontend` sits within the Continuum platform as the browser-facing entry point for all MessageBus self-service workflows. Internal Groupon engineers access it via a public-facing URL (`https://mbus.groupondev.com`). The service does not process or persist configuration directly — it acts as a thin proxy, delegating all business logic to `continuumMbusSigintConfigurationService` and metadata queries to `servicePortal`. Authentication is enforced by Groupon's Hybrid Boundary layer (Okta), which injects user identity headers before the request reaches the Node.js server.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| MBus Sigint Frontend | `continuumMbusSigintFrontend` | WebApp + Backend | Node.js (iTier), React | Node ^14 / React 16 | MessageBus self-service portal UI and backend proxy for configuration workflows |

## Components by Container

### MBus Sigint Frontend (`continuumMbusSigintFrontend`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `sigintReactUi` | Single-page application rendering configuration and admin workflows | React 16, Redux, @reach/router |
| `sigintBackendController` | Serves SPA shell HTML, `/api/mbus-sigint-frontend/app-config`, `/api/mbus-sigint-frontend/session-info`, and `/manifest.webmanifest` | Node.js (iTier actions) |
| `sigintBackendApiProxy` | Forwards all `/api/{serviceId}/*` requests to upstream services by dynamically selecting the correct Gofer client based on `serviceId` | gofer-proxy |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMbusSigintFrontend` | `continuumMbusSigintConfigurationService` | Proxies MessageBus configuration APIs (cluster config, change requests, deploy schedules, admin actions) | HTTPS/JSON |
| `continuumMbusSigintFrontend` | `servicePortal` | Retrieves service catalog metadata (service names list) | HTTPS/JSON |
| `sigintReactUi` | `sigintBackendController` | Reads app config and session info on SPA bootstrap | HTTPS/JSON |
| `sigintReactUi` | `sigintBackendApiProxy` | Sends all configuration and admin API requests | HTTPS/JSON |

## Architecture Diagram References

- Component: `components-continuum-mbus-sigint-frontend`
- Dynamic flow: `dynamic-configuration-change-flow`
