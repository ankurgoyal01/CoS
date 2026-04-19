---
service: "mbus-sigint-frontend"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Global Message Bus"
platform: "Continuum"
team: "GMB (Global Message Bus)"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "ES2020 (Node.js ^14.21.3)"
  framework: "iTier"
  framework_version: "7.7.2"
  runtime: "Node.js"
  runtime_version: "^14.21.3"
  build_tool: "Webpack 4 / Napistrano"
  package_manager: "npm"
---

# MBus Sigint Frontend Overview

## Purpose

MBus Sigint Frontend is the MessageBus self-service portal UI. It provides engineering teams with a unified interface to request configuration changes to the MessageBus infrastructure — such as creating JMS topics, granting access to queues, and managing cluster-level settings — without needing direct infrastructure access. The application runs as an iTier Node.js server that serves a React single-page application and proxies all backend API calls to the `mbus-sigint-config` service and the Groupon Service Portal.

## Scope

### In scope

- Serving the React SPA shell and static assets to browser clients
- Providing authenticated session info and application config to the SPA
- Proxying `/api/{serviceId}` requests to `mbus-sigint-config` and `service-portal`
- Displaying and submitting MessageBus configuration change requests
- Viewing cluster configuration (destinations, credentials, diverts)
- Managing deploy schedules for MessageBus clusters (admin workflow)
- Initiating ad-hoc deployments (admin workflow)
- Approving or rejecting pending change requests (admin workflow)
- Exposing a web app manifest for progressive web app (PWA) installation

### Out of scope

- Processing or persisting configuration changes (handled by `mbus-sigint-config`)
- Service catalog data (provided by `service-portal`)
- MessageBus broker operations and message routing
- Authentication enforcement (delegated to Groupon's Hybrid Boundary / Okta layer)

## Domain Context

- **Business domain**: Global Message Bus (GMB) — internal messaging infrastructure
- **Platform**: Continuum
- **Upstream consumers**: Browser clients (internal Groupon engineers) via `https://mbus.groupondev.com` (production) and `https://mbus-sigint-staging.groupondev.com` (staging)
- **Downstream dependencies**: `mbus-sigint-config` (configuration API), `service-portal` (service catalog)

## Stakeholders

| Role | Description |
|------|-------------|
| Team owner | GMB (Global Message Bus) — messagebus-team@groupon.com |
| On-call | mbus@groupon.pagerduty.com — PagerDuty service PGG3KB5 |
| End users | Internal Groupon engineers who produce or consume MessageBus topics/queues |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript (Node.js) | ^14.21.3 | `package.json` engines |
| Frontend framework | React | ^16.12.0 | `package.json` dependencies |
| Server framework | iTier (itier-server) | ^7.7.2 | `package.json` dependencies |
| Build tool | Webpack | ^4.46.0 | `package.json` devDependencies |
| Deployment tool | Napistrano | ^2.180.13 | `package.json` devDependencies |
| Container base | alpine-node16.14.2 | 2022.04.20 | `Dockerfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `itier-server` | ^7.7.2 | http-framework | iTier Node.js web server foundation |
| `react` | ^16.12.0 | ui-framework | SPA rendering engine |
| `react-redux` | ^7.1.3 | state-management | Redux bindings for React component tree |
| `redux` | ^4.0.4 | state-management | Centralised client-side state store |
| `@reach/router` | ^1.3.3 | ui-framework | Client-side SPA routing (/, /configuration/*, /admin/*) |
| `axios` | ^0.27.2 | http-framework | Browser HTTP client for proxy API calls |
| `gofer` | ^4.1.2 | http-framework | Server-side HTTP client for upstream calls |
| `gofer-proxy` | ^1.0.3 | http-framework | Pipes incoming requests to Gofer-backed upstreams |
| `keldor` | ^7.3.7 | http-framework | iTier routing and middleware layer |
| `keldor-config` | ^4.19.0 | http-framework | Stage/environment-aware configuration loading |
| `itier-instrumentation` | ^9.10.4 | metrics | SMA metrics emission (Wavefront) |
| `itier-tracing` | ^1.6.1 | logging | Distributed tracing integration |
| `itier-feature-flags` | ^2.2.2 | validation | Runtime feature flag evaluation |
| `@grpn/mx-components` | ^3.30.0 | ui-framework | Groupon Merchant Experience React component library |
| `cronstrue` | ^1.94.0 | ui-framework | Human-readable cron expression rendering for deploy schedules |
