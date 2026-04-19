---
service: "janus-ui-cloud"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Platform Data Engineering — Data Translation & Rule Management"
platform: "Continuum"
team: "dnd-ingestion"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "ES2017+"
  framework: "React / Express"
  framework_version: "15.x / 4.13.x"
  runtime: "Node.js"
  runtime_version: "10.13.0"
  build_tool: "Webpack 4"
  package_manager: "yarn"
---

# Janus UI Cloud Overview

## Purpose

Janus UI Cloud is a browser-based management application for Groupon's Janus data translation platform, operated by the Platform Data Engineering team. It provides data engineers and platform operators with a single interface to create and maintain schema mappings, attribute definitions, canonical events, UDF (User-Defined Function) configurations, data destinations, subscribers, and alerting rules. The service is a cloud-native remake of the original Janus UI, rewritten with React and hosted on Kubernetes.

## Scope

### In scope

- Browsing, creating, and editing raw schema definitions
- Browsing, creating, and editing canonical schema mappings
- Managing attribute libraries and value mappings
- Configuring UDFs (User-Defined Functions) for data transformation
- Managing data destinations and subscriber configurations
- Configuring and monitoring alerts and alert thresholds
- Running sandbox and sample queries against Janus metadata
- Viewing metrics dashboards within the UI
- Replaying data events through the replay interface
- User management within the Janus platform

### Out of scope

- Actual data translation execution (handled by Janus Web Cloud / Janus engine)
- Storage of translation rule data (stored in Janus metadata service backend)
- Message bus publishing or event streaming (UI does not produce async events)

## Domain Context

- **Business domain**: Platform Data Engineering — Data Translation & Rule Management
- **Platform**: Continuum
- **Upstream consumers**: Internal data engineering and platform operations teams (browser users)
- **Downstream dependencies**: `continuumJanusWebCloudService` (Janus metadata API, proxied via Gateway)

## Stakeholders

| Role | Description |
|------|-------------|
| Data Curation Platform Team | Primary owners; contact: data-curation-platform@groupon.com |
| dnd-ingestion Team | Engineering team responsible for development and operations |
| Platform Data Engineers | Primary end users of the UI |
| SRE / On-call | janus-prod-alerts@groupon.com; PagerDuty service P25RQWA |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript | ES2017+ | `package.json`, `@babel/preset-env ^7.1.0` |
| UI Framework | React | 15.x | `package.json` — `react: ^15.3.0` |
| State Management | Redux | 3.x | `package.json` — `redux: ^3.6.0` |
| HTTP Server | Express | 4.13.x | `package.json` — `express: ~4.13.1` |
| Runtime | Node.js | 10.13.0 | `Dockerfile` — `FROM node:10.13.0` |
| Build tool | Webpack | 4.x | `package.json` — `webpack: ^4.23.1` |
| Package manager | yarn | — | `Dockerfile` — `yarn install` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `react-redux` | 5.x | state-management | Connects React components to Redux store |
| `redux-thunk` | 2.x | state-management | Async action middleware for API calls |
| `connected-react-router` | 4.x | ui-framework | Redux-integrated client-side routing |
| `react-router-dom` | 4.x | ui-framework | Client-side SPA routing for all UI modules |
| `axios` | 0.16.x | http-framework | HTTP client for backend API calls |
| `http-proxy` | 1.18.1 | http-framework | Express proxy middleware for API forwarding |
| `express-session` | 1.15.x | auth | Session management on the Express server |
| `bootstrap` | 4.x | ui-framework | Responsive layout and base component styling |
| `recharts` | 1.x | ui-framework | Chart/metrics visualizations within the UI |
| `socket.io` | 1.x | http-framework | WebSocket support (real-time updates) |
| `redux-form` | 7.x | ui-framework | Form state management for create/edit flows |
| `moment` | 2.x | serialization | Date/time formatting for replay and alerts |
| `react-table` | 6.x | ui-framework | Tabular data display across schema modules |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `package.json` for a full list.
