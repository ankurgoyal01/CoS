---
service: "b2b-ui"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Merchant Experience / RBAC Administration"
platform: "Continuum"
team: "RBAC (MerchantCenter-BLR@groupon.com)"
status: active
tech_stack:
  language: "TypeScript"
  language_version: "5.4"
  framework: "Next.js"
  framework_version: "14.0.4"
  runtime: "Node.js"
  runtime_version: "20.12.2"
  build_tool: "Nx 19.0.8 / esbuild"
  package_manager: "pnpm"
---

# RBAC UI Overview

## Purpose

The RBAC UI (`b2b-ui`) is a Next.js web application that provides Groupon's Merchant Access System (MAS) administration interface. It enables internal operators and merchant administrators to manage RBAC roles, permissions, categories, and user provisioning across NA and EMEA regions. The service acts as a full-stack Next.js app — it renders the browser UI and hosts a BFF API layer that proxies and orchestrates calls to the underlying `continuumRbacService` and `continuumUsersService`.

## Scope

### In scope
- Rendering the RBAC administration web interface (roles, permissions, categories screens)
- Session validation and identity propagation via Next.js middleware
- Backend-for-frontend (BFF) API routes under `/api/rbac` and `/api/login`
- User provisioning orchestration across NA and EMEA regions via `/api/rbac/users/create`
- Client-side telemetry ingestion via `/api/metrics/log`
- Akamai bot-detection middleware and geolocation request handling
- CSV export of RBAC data via `@json2csv/plainjs`

### Out of scope
- Core RBAC business logic and data storage (owned by `continuumRbacService`)
- User identity storage and resolution (owned by `continuumUsersService`)
- Authentication token issuance (handled upstream by the UMAPI / auth platform)
- Any merchant-facing storefront or deal-management UIs

## Domain Context

- **Business domain**: Merchant Experience / RBAC Administration
- **Platform**: Continuum
- **Upstream consumers**: Internal Groupon operators and merchant administrators (browser clients)
- **Downstream dependencies**: `continuumRbacService` (RBAC v2 endpoints), `continuumUsersService` (user identity and account creation)

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | Josef Sima (`c_jsima@groupon.com`) |
| Team | RBAC team — MerchantCenter-BLR@groupon.com |
| Consumers | Internal operators and merchant admins using the RBAC administration screens |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | TypeScript | 5.4.2 | `package.json` devDependencies |
| Framework | Next.js | 14.0.4 | `package.json` dependencies |
| Runtime | Node.js | 20.12.2 | `.node-version` |
| Build tool | Nx | 19.0.8 | `package.json` devDependencies |
| Package manager | pnpm | — | `.npmrc`, `nx.json` (pnpm dlx) |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `react` | 18.2.0 | ui-framework | Component rendering for RBAC admin screens |
| `antd` | 5.19.1 | ui-framework | Ant Design component library for admin UI |
| `@ant-design/icons` | 5.3.7 | ui-framework | Icon set for Ant Design components |
| `framer-motion` | 11.2.12 | ui-framework | Animation library for UI transitions |
| `jose` | 5.8.0 | auth | JWT validation in session middleware |
| `cookie` | 0.6.0 | auth | Parses auth cookies in middleware |
| `winston` | 3.13.0 | logging | Structured server-side logging |
| `@json2csv/plainjs` | 7.0.6 | serialization | CSV export of RBAC data |
| `dayjs` | 1.11.11 | validation | Date parsing and formatting utilities |
| `uuid` | 10.0.0 | serialization | UUID generation for request correlation |
| `swagger-client` | 3.28.0 | http-framework | Swagger-based API client for downstream services |
| `zustand` | 4.5.2 | state-management | Client-side state management |
| `@playwright/test` | 1.44.0 | testing | End-to-end test framework (rbac-ui-e2e) |
| `jest` | 29.7.0 | testing | Unit test framework |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
