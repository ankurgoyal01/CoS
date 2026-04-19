---
service: "par-automation"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for PAR Automation.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [PAR Request — Auto-Approved (Production)](par-request-auto-approved-production.md) | synchronous | `POST /release/par` from Hybrid Boundary UI | Full production path: validates, classifies, creates Jira PAR and GPROD tickets, applies Hybrid Boundary policy |
| [PAR Request — Denied by Classification Rules](par-request-denied.md) | synchronous | `POST /release/par` from Hybrid Boundary UI | Classification check fails; Jira PAR ticket created in production but no policy change applied |
| [PAR Request — Non-Production (Staging/Sandbox)](par-request-non-production.md) | synchronous | `POST /release/par` from Hybrid Boundary UI | Policy applied to Hybrid Boundary regardless of result; no Jira tickets created |
| [Duplicate PAR Detection](duplicate-par-detection.md) | synchronous | `POST /release/par` from Hybrid Boundary UI | Existing policy found for the principal/domain pair; request rejected before any changes are made |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The end-to-end PAR Request Automation flow is documented in the central architecture model as a dynamic view:

- Architecture dynamic view: `dynamic-par-request-automation-flow`

This view covers the full sequence from administrator action in the Hybrid Boundary UI through to policy application and Jira ticket creation, spanning `continuumHybridBoundaryUi`, `continuumParAutomationApi`, `servicePortal`, `oktaIdp`, `continuumHybridBoundaryLambdaApi`, `continuumJiraService`, and `cloudPlatform`.
