---
service: "par-automation"
title: "Duplicate PAR Detection"
generated: "2026-03-03"
type: flow
flow_name: "duplicate-par-detection"
flow_type: synchronous
trigger: "POST /release/par — principal already exists in Hybrid Boundary"
participants:
  - "continuumHybridBoundaryUi"
  - "continuumParAutomationApi"
  - "servicePortal"
  - "continuumHybridBoundaryLambdaApi"
architecture_ref: "dynamic-par-request-automation-flow"
---

# Duplicate PAR Detection

## Summary

Before applying any changes, PAR Automation checks whether the requesting service's principal already exists in the target domain's Hybrid Boundary authorization policies. If a matching principal is found, the request is immediately rejected with `HTTP 400` and no Jira tickets are created and no policy updates are made. This guard applies in all environments (production, staging, sandbox) and runs after the classification check but before any write operations.

## Trigger

- **Type**: api-call
- **Source**: Hybrid Boundary UI (`continuumHybridBoundaryUi`) calling `POST /release/par` with a `FromService` that already has a policy entry for the `ToDomain`
- **Frequency**: On-demand (per PAR form submission where access already exists)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Hybrid Boundary UI | Forwards PAR form data to the automation API | `continuumHybridBoundaryUi` |
| PAR Automation API | Detects duplicate and rejects the request | `continuumParAutomationApi` |
| Service Portal | Provides classification data needed to construct the principal string | `servicePortal` |
| Hybrid Boundary Lambda API | Returns existing policies for the target domain | `continuumHybridBoundaryLambdaApi` |

## Principal Construction Logic

The principal string used for duplicate detection is constructed as:

```
{env}/{fromService}[/sox]
```

Where:
- `env` maps: `sandbox` -> `dev`, `staging` -> `staging`, `production` -> `production`
- `/sox` suffix is appended if `FromService` has `Sox = true`
- For staging, an additional `dev/{fromService}[/sox]` principal is also checked

The duplicate check compares this computed principal against `{policy.Target.PathPrefix} + {principal}` values in all existing policies returned by Hybrid Boundary.

## Steps

1. **Forward request to PAR Automation API**:
   - From: `continuumHybridBoundaryUi`
   - To: `continuumParAutomationApi` — `POST /release/par`
   - Protocol: REST/HTTP

2. **Validate payload**: All four fields checked.
   - From: `parRequestHandler`
   - To: (internal validation)

3. **Fetch FromService metadata**: Retrieves classification data to construct the principal string (SOX suffix needed).
   - From: `continuumParAutomationApi`
   - To: `servicePortal`
   - Protocol: REST/HTTP

4. **Fetch ToDomain metadata**: Retrieves classification data for the approvability check (runs before the duplicate check in code).
   - From: `continuumParAutomationApi`
   - To: `servicePortal`
   - Protocol: REST/HTTP

5. **Evaluate classification rules**: Determines approvability (result is set aside; duplicate check runs next).
   - From: `policyAutomationRulesEngine`
   - To: (in-process decision)

6. **Read existing Hybrid Boundary policies**: Calls `GET /release/v1/services/{toService}/{toDomain}/authorization/policies` to retrieve all existing policy entries for the target domain.
   - From: `continuumParAutomationApi`
   - To: `continuumHybridBoundaryLambdaApi`
   - Protocol: REST/HTTP

7. **Match principal against existing policies**: The Hybrid Boundary Client iterates all returned policy principals and compares against the constructed principal string.
   - From: `hybridBoundaryClient`
   - To: (in-process comparison)

8. **Reject duplicate request**: A matching principal is found; the request is rejected.
   - From: `continuumParAutomationApi`
   - To: `continuumHybridBoundaryUi`
   - Protocol: REST/HTTP
   - Response: `HTTP 400`
   - Payload: `{"Description": "cannot add a principal that already exists from {fromService} to {toDomain}"}`

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Hybrid Boundary API `GET` fails | Return `HTTP 500` | Request rejected; principal match not checked |
| Target domain not found in Hybrid Boundary (`HTTP 404`) | Return `HTTP 404` | Request rejected; service name likely wrong |
| No duplicate found | Flow continues to Jira/policy-write steps | Normal processing resumes |

## Sequence Diagram

```
HybridBoundaryUI      -> ParAutomationAPI          : POST /release/par
ParAutomationAPI      -> ServicePortal             : GET /api/v2/services/{FromService}?includes=regulatory_classifications
ServicePortal         --> ParAutomationAPI         : 200 OK (SOX flag used for principal string)
ParAutomationAPI      -> ServicePortal             : GET /api/v2/services/{ToDomain}?includes=regulatory_classifications
ServicePortal         --> ParAutomationAPI         : 200 OK
ParAutomationAPI      -> ParAutomationAPI          : canAutomatePar() => true|false (not used yet)
ParAutomationAPI      -> HybridBoundaryLambdaAPI   : GET .../authorization/policies
HybridBoundaryLambdaAPI --> ParAutomationAPI       : 200 OK [existing policy list]
ParAutomationAPI      -> ParAutomationAPI          : match "{env}/{fromService}[/sox]" in existing principals => FOUND
ParAutomationAPI      --> HybridBoundaryUI         : 400 Bad Request {"Description": "cannot add a principal that already exists..."}
```

## Related

- Architecture dynamic view: `dynamic-par-request-automation-flow`
- Related flows: [PAR Request — Auto-Approved (Production)](par-request-auto-approved-production.md), [PAR Request — Denied](par-request-denied.md), [PAR Request — Non-Production](par-request-non-production.md)
