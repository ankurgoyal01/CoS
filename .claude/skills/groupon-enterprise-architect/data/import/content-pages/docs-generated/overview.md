---
service: "content-pages"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Content & Information / Platform Pages"
platform: "Continuum"
team: "Content Platform"
status: active
tech_stack:
  language: "Node.js"
  language_version: "16"
  framework: "itier-server"
  framework_version: "7.14.2"
  runtime: "Node.js"
  runtime_version: "16"
  build_tool: "webpack"
  package_manager: "npm"
---

# Content Pages Overview

## Purpose

The Content Pages service (`content-pages`) is a server-side-rendered Node.js application that serves Groupon's static CMS-backed pages — including legal documents, privacy disclosures, incident reporting forms, and intellectual property infringement reporting forms. It fetches page content from a Content Pages GraphQL API, renders it via Preact, and handles multi-step form workflows for incident and infringement submissions including image upload and email notification.

## Scope

### In scope

- Serving CMS-managed content pages via `GET /pages/{permalink}` and `GET /legal/{permalink}`
- Rendering the Privacy Hub (`GET /privacy-hub`) and Cookie Consent disclosure (`GET /cookie-consent`)
- Handling incident report submission (`GET/POST /report_incident`) including image upload to Image Service and email via Rocketman
- Handling intellectual property infringement report submission (`GET/POST /report_infringement`) with email notification via Rocketman
- Resolving legacy permalink redirects to canonical URLs
- Rendering standard HTTP error pages (404, 500, etc.)
- Rendering the Savored landing page

### Out of scope

- Authoring or managing CMS content (owned by the Content Pages GraphQL API backend)
- Email delivery infrastructure (owned by Rocketman Email Service)
- Image storage (upload delegated to Image Service; storage is Image Service's responsibility)
- Cookie consent enforcement or tracking (only disclosure page; enforcement is platform-level)

## Domain Context

- **Business domain**: Content & Information / Platform Pages
- **Platform**: Continuum
- **Upstream consumers**: End-user browsers navigating to legal, privacy, and reporting pages; Groupon's routing/CDN layer
- **Downstream dependencies**: Content Pages GraphQL API, `continuumImageService`, Rocketman Email Service, Routing Service

## Stakeholders

| Role | Description |
|------|-------------|
| Content Platform Team | Owns and maintains this service |
| Legal & Compliance | Consumers of the legal and privacy pages rendered by this service |
| End Users | Users submitting incident and infringement reports |
| Content Editors | Manage page content via the upstream CMS/GraphQL API |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Node.js | 16 | models/containers.dsl |
| Framework | itier-server | 7.14.2 | service inventory |
| HTTP Framework | Express | 4.17.1 | service inventory |
| UI Framework | Preact | 10.5.13 | service inventory |
| Build tool | webpack | 5.40.0 | service inventory |
| Package manager | npm | — | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| itier-server | 7.14.2 | http-framework | Core HTTP server and iTier application shell |
| express | 4.17.1 | http-framework | HTTP routing and middleware layer |
| preact | 10.5.13 | ui-framework | Server-side and client-side page rendering |
| itier-localization | 11.0.3 | serialization | Locale and i18n support for rendered pages |
| itier-cached | 8.1.3 | state-management | In-memory response caching |
| itier-groupon-v2-content-pages | 1.0.6 | http-client | Client for fetching content from the GraphQL API |
| image-service-client | 2.1.4 | http-client | Client for uploading incident report images |
| @grpn/rocketman-client | 1.0.7 | http-client | Client for sending email notifications via Rocketman |
| gofer | 5.0.5 | http-client | Base HTTP fetch abstraction |
| cheerio | 1.0.0-rc.5 | serialization | HTML parsing for server-side content manipulation |
| itier-instrumentation | 9.13.4 | metrics | Service observability and instrumentation |
| webpack | 5.40.0 | build | Client-side asset bundling |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
