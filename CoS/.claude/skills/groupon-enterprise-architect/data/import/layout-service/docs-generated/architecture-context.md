---
service: "layout-service"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumLayoutService", "continuumLayoutTemplateCache"]
---

# Architecture Context

## System Context

Layout Service sits within the `continuumSystem` (Continuum Platform) as a shared infrastructure service for frontend rendering. All i-tier frontend applications within Groupon's Continuum platform call Layout Service to obtain rendered page chrome (header, footer, navigation). The service has no direct relationship with the public internet consumer; it acts as a server-side composition layer sitting between i-tier apps and Groupon's CDN-backed static asset infrastructure.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| Layout Service | `continuumLayoutService` | Web Service | Node.js, itier-server | Composes header/footer layouts and shared assets for web clients. Exposes `/layout/*` HTTP endpoints. |
| Layout Template Cache | `continuumLayoutTemplateCache` | Cache | Redis | In-memory cache for rendered templates and fragments used by Layout Service. |

## Components by Container

### Layout Service (`continuumLayoutService`)

| Component | ID | Responsibility | Technology |
|-----------|-----|---------------|-----------|
| HTTP API Endpoints | `layoutSvc_httpApi` | Route handlers for `/layout` and related endpoints consumed by i-tier apps | Express Controllers |
| Request Composition | `layoutSvc_requestComposer` | Builds locale, market, user, and feature context for layout rendering | Core Modules |
| Template Renderer | `layoutSvc_templateRenderer` | Renders Mustache templates and assembles page chrome output | Mustache/Hogan |
| Asset Resolver | `layoutSvc_assetResolver` | Resolves CDN-backed static assets and brand-specific resources | Asset Helpers |
| Template Cache Client | `layoutSvc_templateCacheClient` | Encapsulates cache access for template/fragment read-write operations | Redis Client |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumLayoutService` | `continuumLayoutTemplateCache` | Reads and writes template artifacts | Redis protocol |
| `layoutSvc_httpApi` | `layoutSvc_requestComposer` | Builds the rendering context for layout responses | direct |
| `layoutSvc_requestComposer` | `layoutSvc_templateRenderer` | Invokes template rendering with assembled context | direct |
| `layoutSvc_templateRenderer` | `layoutSvc_templateCacheClient` | Loads/saves compiled templates and fragments | direct |
| `layoutSvc_assetResolver` | `layoutSvc_templateRenderer` | Provides resolved asset URLs and metadata for rendering | direct |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-continuum-layout-service`
- Dynamic flow: `dynamic-layout-service-request-flow`
