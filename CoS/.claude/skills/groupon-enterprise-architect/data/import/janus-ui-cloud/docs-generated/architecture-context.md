---
service: "janus-ui-cloud"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumJanusUiCloudFrontend", "continuumJanusUiCloudGateway"]
---

# Architecture Context

## System Context

Janus UI Cloud is a web application within the Continuum platform, owned by the Platform Data Engineering team. It provides a browser-based user interface for managing data translation rules and schema mappings in the Janus ecosystem. Users access it directly through a browser. The application is split into a React single-page application (SPA) and a Node.js/Express gateway server. The gateway proxies all backend API requests to the Janus Web Cloud metadata service (`continuumJanusWebCloudService`). The UI also loads Google Tag Manager analytics scripts from an external CDN.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Janus UI Frontend | `continuumJanusUiCloudFrontend` | WebApp | React, Redux, Webpack | 15.x / 4.x | Single-page application for Janus rule management and data translation operations |
| Janus UI Cloud Gateway | `continuumJanusUiCloudGateway` | API | Node.js, Express, http-proxy | 10.13.0 / 4.13.x | Express server that serves static assets and proxies Janus API requests to metadata services |

## Components by Container

### Janus UI Frontend (`continuumJanusUiCloudFrontend`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Janus UI Shell (`janusUiShell`) | React/Redux single-page shell that renders modules for rule management workflows; handles client-side routing to raw schema, canonical schema, attributes, UDF, destinations, subscribers, replay, alerts, metrics, sandbox, users, and help sections | React, Redux, react-router-dom |

### Janus UI Cloud Gateway (`continuumJanusUiCloudGateway`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Janus API Proxy Middleware (`juic_janusApiClient`) | Express middleware that rewrites paths and proxies `/api/*` requests to environment-specific Janus metadata endpoints | Express Middleware, http-proxy |
| Static Asset Server (`janusUiAssetServer`) | Serves compiled frontend JavaScript bundles, CSS, images, and the SPA entrypoint HTML | Express Static |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumJanusUiCloudFrontend` | `continuumJanusUiCloudGateway` | Calls Janus API endpoints | HTTPS/JSON |
| `continuumJanusUiCloudFrontend` | `googleTagManager` | Loads web analytics tag script | HTTPS |
| `continuumJanusUiCloudGateway` | `continuumJanusWebCloudService` | Proxies Janus metadata API requests | HTTP/HTTPS |
| `janusUiShell` | `juic_janusApiClient` | Invokes Janus REST API routes exposed through `/api/*` | HTTPS/JSON |

## Architecture Diagram References

- System context: `contexts-continuum-janus-ui-cloud`
- Container: `containers-continuum-janus-ui-cloud`
- Component (Frontend): `components-continuum-janus-ui-cloud-frontend`
- Component (Gateway): `components-continuum-janus-ui-cloud-gateway`
- Dynamic view: `dynamic-janus-ui-request-flow`
