---
service: "par-automation"
title: "PAR Request — Non-Production (Staging/Sandbox)"
generated: "2026-03-03"
type: flow
flow_name: "par-request-non-production"
flow_type: synchronous
trigger: "POST /release/par from Hybrid Boundary UI (staging or sandbox environment)"
participants:
  - "continuumHybridBoundaryUi"
  - "continuumParAutomationApi"
  - "servicePortal"
  - "continuumHybridBoundaryLambdaApi"
architecture_ref: "dynamic-par-request-automation-flow"
---

# PAR Request — Non-Production (Staging/Sandbox)

## Summary

In staging and sandbox environments, PAR Automation always applies the Hybrid Boundary policy change regardless of whether the classification rules would approve or deny the request. This allows teams to test access control configuration without requiring Jira infrastructure. No PAR or GPROD Jira tickets are created. The response still reflects what the classification outcome would be (`HTTP 200` if approvable, `HTTP 403` if not), providing early feedback to the developer without blocking the policy update.

## Trigger

- **Type**: api-call
- **Source**: Hybrid Boundary UI (`continuumHybridBoundaryUi`) calling `POST /release/par` in a staging or sandbox environment
- **Frequency**: On-demand (per PAR form submission)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Hybrid Boundary UI | Forwards PAR form data to the automation API | `continuumHybridBoundaryUi` |
| PAR Automation API | Orchestrates validation, classification, and policy update (no Jira) | `continuumParAutomationApi` |
| Service Portal | Provides regulatory classification metadata | `servicePortal` |
| Hybrid Boundary Lambda API | Queried for duplicate check; policy write always applied | `continuumHybridBoundaryLambdaApi` |

## Steps

1. **Forward request to PAR Automation API**: Hybrid Boundary UI posts form data.
   - From: `continuumHybridBoundaryUi`
   - To: `continuumParAutomationApi` — `POST /release/par`
   - Protocol: REST/HTTP

2. **Validate payload**: All four fields checked; returns `HTTP 400` if any are missing.
   - From: `parRequestHandler`
   - To: (internal validation)

3. **Fetch FromService metadata from Service Portal**:
   - From: `continuumParAutomationApi`
   - To: `servicePortal`
   - Protocol: REST/HTTP

4. **Fetch ToDomain metadata from Service Portal**:
   - From: `continuumParAutomationApi`
   - To: `servicePortal`
   - Protocol: REST/HTTP

5. **Evaluate classification rules**: The Policy Automation Rules Engine determines `automatable` (true or false) and the result message. This result influences the HTTP response code but NOT the policy update.
   - From: `policyAutomationRulesEngine`
   - To: (in-process decision)

6. **Check for duplicate policy**:
   - From: `continuumParAutomationApi`
   - To: `continuumHybridBoundaryLambdaApi`
   - Protocol: REST/HTTP

7. **Apply authorization policy unconditionally**: The Hybrid Boundary Client posts the new policy entry regardless of the classification outcome. No Okta token is needed because this code path uses the same `UpdateHybridBoundaryConfigs` call with a `nil` GPROD reference.
   - From: `continuumParAutomationApi`
   - To: `continuumHybridBoundaryLambdaApi` — `POST /release/v1/services/{toService}/{toDomain}/authorization/policies`
   - Protocol: REST/HTTP

8. **Return classification-aware response**: If the classification engine would have approved the request, return `HTTP 200`; if it would have denied it, return `HTTP 403`. No PAR or GPROD keys are included.
   - From: `continuumParAutomationApi`
   - To: `continuumHybridBoundaryUi`
   - Protocol: REST/HTTP
   - Payload (approvable): `{"Description": "Access Approved: ..."}`
   - Payload (deniable): `{"Description": "Access Denied: ..."}`

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing request fields | Validate on entry; return `HTTP 400` | Request rejected |
| Service not found in Service Portal | Return `HTTP 404` | Request rejected |
| Duplicate principal exists | Return `HTTP 400` | Request rejected |
| Hybrid Boundary API POST fails | Return `HTTP 500` | No policy change |

## Sequence Diagram

```
HybridBoundaryUI      -> ParAutomationAPI          : POST /release/par
ParAutomationAPI      -> ServicePortal             : GET /api/v2/services/{FromService}?includes=regulatory_classifications
ServicePortal         --> ParAutomationAPI         : 200 OK
ParAutomationAPI      -> ServicePortal             : GET /api/v2/services/{ToDomain}?includes=regulatory_classifications
ServicePortal         --> ParAutomationAPI         : 200 OK
ParAutomationAPI      -> ParAutomationAPI          : canAutomatePar() => true|false (informational only)
ParAutomationAPI      -> HybridBoundaryLambdaAPI   : GET .../authorization/policies (duplicate check)
HybridBoundaryLambdaAPI --> ParAutomationAPI       : 200 OK
ParAutomationAPI      -> HybridBoundaryLambdaAPI   : POST .../authorization/policies (always applied)
HybridBoundaryLambdaAPI --> ParAutomationAPI       : 201 Created
ParAutomationAPI      --> HybridBoundaryUI         : 200 OK or 403 Forbidden {"Description": "..."}
```

## Related

- Architecture dynamic view: `dynamic-par-request-automation-flow`
- Related flows: [PAR Request — Auto-Approved (Production)](par-request-auto-approved-production.md), [PAR Request — Denied](par-request-denied.md), [Duplicate PAR Detection](duplicate-par-detection.md)
