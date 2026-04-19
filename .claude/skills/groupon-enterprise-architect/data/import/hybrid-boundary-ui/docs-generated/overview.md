---
service: "hybrid-boundary-ui"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Infrastructure / Service Mesh Management"
platform: "Continuum"
team: "Continuum Platform / Infrastructure"
status: active
tech_stack:
  language: "TypeScript"
  language_version: ""
  framework: "Angular"
  framework_version: "8"
  runtime: "Nginx"
  runtime_version: ""
  build_tool: "Angular CLI"
  package_manager: "npm"
---

# Hybrid Boundary UI Overview

## Purpose

Hybrid Boundary UI is an Angular single-page application that gives engineers and operators a self-service interface for managing Hybrid Boundary service mesh configuration. It allows users to view and modify service definitions, endpoint registrations, traffic policies, permission assignments, and to initiate PAR (Production Access Request) automation workflows — all without requiring direct API access. Access is secured through Groupon Okta OAuth2/OIDC authentication.

## Scope

### In scope

- Displaying and editing Hybrid Boundary service configuration via the `/release/v1` API
- Managing service endpoints, shifts, and traffic policies
- Managing user permissions for Hybrid Boundary services
- Submitting and tracking PAR automation requests via the `/release/par` API
- OIDC-based authentication and session token management through Groupon Okta

### Out of scope

- Hybrid Boundary API server-side logic (owned by the Hybrid Boundary API service)
- PAR workflow processing (owned by the PAR Automation API service)
- Identity management and user provisioning (owned by Groupon Okta)
- Service mesh data plane (routing, load balancing at the infrastructure level)

## Domain Context

- **Business domain**: Infrastructure / Service Mesh Management
- **Platform**: Continuum
- **Upstream consumers**: Not applicable — this is a user-facing SPA; no services consume it programmatically
- **Downstream dependencies**: Hybrid Boundary API (`/release/v1`), PAR Automation API (`/release/par`), Groupon Okta (OIDC)

## Stakeholders

| Role | Description |
|------|-------------|
| Continuum Platform / Infrastructure Team | Service owners; responsible for operation and evolution |
| Groupon Engineers and Operators | Primary end users managing service mesh configuration |
| Platform SRE | Monitors operational health |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | TypeScript | — | `continuumHybridBoundaryUi` component descriptions |
| Framework | Angular | 8 | `continuumHybridBoundaryUi` container description ("Angular 8 SPA") |
| Runtime | Nginx | — | `continuumHybridBoundaryUi` container description ("Nginx") |
| Build tool | Angular CLI | — | Angular standard toolchain |
| Package manager | npm | — | Angular/Node standard toolchain |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Angular | 8 | ui-framework | Component-based SPA framework and routing |
| angular-oauth2-oidc | — | auth | OAuth2/OIDC integration for Groupon Okta authentication |
| Angular HttpClient | — | http-client | HTTP clients for Hybrid Boundary API and PAR Automation API calls |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
