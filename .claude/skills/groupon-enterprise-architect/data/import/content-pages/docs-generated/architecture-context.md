---
service: "content-pages"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumContentPagesService]
---

# Architecture Context

## System Context

The Content Pages service sits within the Continuum platform as a user-facing web application. It serves Groupon's institutional and compliance pages — legal disclosures, privacy notices, and reporting forms — to end-user browsers. The service is stateless: all page content is fetched from an upstream Content Pages GraphQL API on each request (with in-process caching). The sole active federation-modeled outbound relationship is to `continuumImageService` for incident image uploads; all other external integrations (GraphQL API, Rocketman Email, CDN, Memcached) are modeled as stubs or commented out in the local workspace.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Content Pages Service | `continuumContentPagesService` | Web Application | Node.js / itier-server | 7.14.2 | Serves content, legal, privacy, and reporting pages with server-side rendering and form workflows |

## Components by Container

### Content Pages Service (`continuumContentPagesService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `contentPagesController` | Serves `/pages/*` and `/legal/*` content pages | Node.js |
| `privacyHubController` | Renders privacy hub legal pages with table of contents | Node.js |
| `cookieConsentController` | Renders cookie consent disclosure page | Node.js |
| `errorPagesController` | Renders HTTP error pages (404, 500, etc.) | Node.js |
| `incidentController` | Handles incident report flow including file upload | Node.js |
| `infringementController` | Handles intellectual property infringement report flow | Node.js |
| `legacyPermalinksController` | Maps legacy URL paths to canonical permalinks | Node.js |
| `savoredController` | Renders Savored landing page | Node.js |
| `permalinksService` | Resolves legal, redirect, and legacy permalinks | Node.js |
| `emailerService` | Sends incident and infringement notification emails via Rocketman | Node.js |
| `imageUploadService` | Validates and uploads incident report images to Image Service | Node.js |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumContentPagesService` | `continuumImageService` | Uploads incident report images | HTTPS |
| `continuumContentPagesService` | Content Pages GraphQL API | Fetches legal and static page content (stub-only) | HTTPS/JSON |
| `continuumContentPagesService` | Rocketman Email Service | Sends incident and infringement emails (stub-only) | HTTPS |
| `continuumContentPagesService` | Memcached Cache | Caches legal and static pages (stub-only) | Memcached |
| `continuumContentPagesService` | Groupon CDN | Serves static assets (stub-only) | HTTPS |
| `emailerService` | Rocketman Email Service | Routes email notifications through `@grpn/rocketman-client` | HTTPS |
| `imageUploadService` | `continuumImageService` | Validates and uploads images via `image-service-client` | HTTPS |
| `permalinksService` | Content Pages GraphQL API | Resolves permalink-to-content mappings | HTTPS/JSON |

> Relationships marked stub-only reference systems not present in the federated central model. Only `continuumImageService` is a fully modeled relationship.

## Architecture Diagram References

- Container view: `contentPagesContainers`
- Component view: `contentPagesComponents`
- Dynamic views: No dynamic views defined in DSL
- Component DSL: `components/content-pages-service.dsl`
