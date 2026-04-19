---
service: "proxykong"
title: Overview
generated: "2026-03-03"
type: overview
domain: "API Gateway / Route Management"
platform: "Continuum"
team: "Groupon API"
status: active
tech_stack:
  language: "JavaScript/TypeScript"
  language_version: "ES2015+"
  framework: "iTier"
  framework_version: "internal"
  runtime: "Node.js"
  runtime_version: "14.20.0"
  build_tool: "Napistrano / Conveyor CI"
  package_manager: "npm"
---

# ProxyKong Overview

## Purpose

ProxyKong is an internal web application that provides Groupon engineers with a browser-based interface to manage API proxy routing configurations. It automates the end-to-end workflow of creating, promoting, and removing routes in the `api-proxy-config` repository by orchestrating Jira ticket creation and GitHub pull request submission on behalf of the requesting engineer. The service exists to reduce manual toil and enforce consistency in how routing change requests are tracked, reviewed, and applied.

## Scope

### In scope

- Serving the ProxyKong web UI for route management workflows (add, promote, delete routes; delete experiments)
- Reading route, route group, destination, and experiment data from `api-proxy-config` config tools
- Validating destination VIP existence via the Hybrid Boundary edge proxy
- Validating service names against the Service Portal
- Creating Jira issues in the GAPI project (project ID `11500`, issue type `10700`) for route change requests
- Creating GitHub pull requests against `groupon-api/api-proxy-config` on feature branches
- Serving the Argus reporting UI and generating performance reports via the Robin library
- Sending performance report emails

### Out of scope

- Actual HTTP request routing (handled by the API Proxy / Kong infrastructure and configured via `api-proxy-config`)
- Approving or merging pull requests (done by human reviewers)
- Storing routing configuration state (stored in `api-proxy-config` Git repository)
- Direct modification of Kong or API gateway configuration (done downstream after PR merge)

## Domain Context

- **Business domain**: API Gateway / Route Management
- **Platform**: Continuum
- **Upstream consumers**: Groupon engineers accessing the tool via browser (authenticated via Okta)
- **Downstream dependencies**: `api-proxy-config` repository (filesystem/Git), GitHub Enterprise (pull requests), Jira (issue tracking), Service Portal (service metadata), Hybrid Boundary edge proxy (VIP validation), Robin reporting service (Argus metrics)

## Stakeholders

| Role | Description |
|------|-------------|
| Owner | tkuntz |
| Team | Groupon API (apidevs@groupon.com) |
| Notify | apidevs@groupon.com |
| End users | Groupon engineers requesting API proxy route changes |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript / TypeScript | ES2015+ | `modules/**/*.ts`, `modules/**/*.js` |
| Framework | iTier (Groupon internal) | internal | `README.md`, `core/worker-shim.js` |
| Runtime | Node.js | 14.20.0 | `Dockerfile` (alpine-node14.20.0) |
| Build tool | Napistrano / Conveyor CI | nap 2.180.3 | `.deploy-configs/values.yaml` |
| Package manager | npm | — | `.npmrc`, `README.md` |
| UI library | Preact | — | `modules/proxykong/views/proxyKong.tsx` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `@grpn/promise-actions` | internal | http-framework | iTier action/response utilities (`json` responder) |
| `@grpn/jira-client` | internal | integration | Creates Jira issues for route change requests |
| `@grpn/github-client` | internal | integration | Creates branches and pull requests in GitHub Enterprise |
| `@grpn/robin` | internal | metrics | `PerformanceReport` and `EmailGenerator` for Argus reporting |
| `axios` | — | http-client | HTTP calls to Service Portal and Hybrid Boundary for validation |
| `preact` | — | ui-framework | Renders the ProxyKong and Reporting module UIs |
| `moment` | — | utility | Date/time formatting for report query ranges |
| `fs-extra` | — | utility | Copies `api-proxy-config` into a temporary directory for PR mutations |
| `mz` | — | utility | Promise-based `fs.mkdtemp` for temporary directory creation |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
