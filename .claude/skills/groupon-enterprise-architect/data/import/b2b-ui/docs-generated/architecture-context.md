---
service: "b2b-ui"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumRbacUiService"]
---

# Architecture Context

## System Context

The RBAC UI (`b2b-ui`) is a container within the `continuumSystem` (Continuum Platform — Groupon's core commerce engine). It sits at the browser-facing edge of the RBAC administration domain, translating operator and merchant-admin interactions into orchestrated calls to `continuumRbacService` and `continuumUsersService`. All HTTP requests from the browser pass through Next.js middleware for JWT/cookie validation before reaching the BFF API routes.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| RBAC UI Service | `continuumRbacUiService` | WebApp | TypeScript, Next.js | 14.0.4 | Next.js application that serves the RBAC web UI and BFF API routes |

## Components by Container

### RBAC UI Service (`continuumRbacUiService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| RBAC Web UI | Renders Next.js pages and React components for RBAC administration screens (roles, permissions, categories) | TypeScript, React 18 |
| Session Middleware | Validates the auth cookie/JWT on every request and injects requester identity headers for downstream consumption | TypeScript, Next.js Middleware |
| RBAC BFF API | Exposes API routes under `/api/rbac` and `/api/login` that orchestrate RBAC operations against downstream services | TypeScript, Next.js API Routes |
| User Provisioning Flow | Orchestrates multi-region (NA and EMEA) user creation with permission checks via `/api/rbac/users/create` | TypeScript |
| Metrics Logging API | Receives browser/client telemetry and writes structured server-side logs | TypeScript |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `rbacUi_webUi` | `rbacUi_sessionMiddleware` | Sends every request through route protection and identity propagation | HTTP (internal) |
| `rbacUi_sessionMiddleware` | `rbacUi_bffApi` | Forwards authenticated requests with RBAC identity headers | HTTP (internal) |
| `rbacUi_webUi` | `rbacUi_bffApi` | Calls `/api/rbac` and `/api/login` endpoints directly | REST/HTTP |
| `rbacUi_webUi` | `rbacUi_metricsLogging` | Posts client telemetry to `/api/metrics/log` | REST/HTTP |
| `rbacUi_bffApi` | `rbacUi_userProvisioning` | Invokes create-user orchestration for `/api/rbac/users/create` | Direct (in-process) |
| `rbacUi_bffApi` | `rbacUi_metricsLogging` | Writes request and error logs | Direct (in-process) |
| `rbacUi_bffApi` | `continuumRbacService` | Calls RBAC v2 endpoints for roles, permissions, categories, and requests | REST/HTTP |
| `rbacUi_bffApi` | `continuumUsersService` | Calls users-service APIs to validate users, resolve identities, and create accounts | REST/HTTP |
| `rbacUi_userProvisioning` | `rbacUi_metricsLogging` | Writes user-creation audit logs | Direct (in-process) |
| `continuumRbacUiService` | `continuumRbacService` | Calls RBAC v2 endpoints for roles, permissions, categories, and requests | REST/HTTP |
| `continuumRbacUiService` | `continuumUsersService` | Validates users, resolves identities, and creates accounts | REST/HTTP |

## Architecture Diagram References

- Component: `components-continuum-rbac-rbacUi_webUi-service`
- Dynamic flow: `dynamic-rbac-rbacUi_webUi-role-management-flow`
