---
service: "b2b-ui"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for the RBAC UI.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Role Management Request Flow](role-management-request.md) | synchronous | Browser action on RBAC admin screen | User views or modifies roles, permissions, or categories; request passes through session middleware, BFF API, and RBAC service |
| [User Provisioning Flow](user-provisioning.md) | synchronous | Operator submits create-user form | Orchestrates multi-region (NA and EMEA) user creation with permission checks across RBAC and Users services |
| [Session Validation Flow](session-validation.md) | synchronous | Every inbound browser request | Next.js middleware validates the auth cookie/JWT and injects identity headers before the request reaches any BFF route or page |
| [Client Telemetry Logging Flow](client-telemetry-logging.md) | synchronous | Browser posts client-side log events | Browser sends telemetry to `/api/metrics/log`; BFF writes structured server logs via Winston |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The Role Management Request Flow and User Provisioning Flow both span multiple Continuum services. Their cross-service interactions are modeled in the architecture dynamic view:

- `dynamic-rbac-rbacUi_webUi-role-management-flow` (Structurizr dynamic view)
