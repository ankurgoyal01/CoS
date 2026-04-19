---
service: "par-automation"
title: "PAR Request — Denied by Classification Rules"
generated: "2026-03-03"
type: flow
flow_name: "par-request-denied"
flow_type: synchronous
trigger: "POST /release/par from Hybrid Boundary UI"
participants:
  - "administrator"
  - "continuumHybridBoundaryUi"
  - "continuumParAutomationApi"
  - "servicePortal"
  - "continuumHybridBoundaryLambdaApi"
  - "continuumJiraService"
architecture_ref: "dynamic-par-request-automation-flow"
---

# PAR Request — Denied by Classification Rules

## Summary

This flow describes the production path when a PAR request is evaluated and the data-classification rules determine that automatic approval is not permitted. A PAR Jira ticket is still created (with an `auto-denied` label) to record the request, but no GPROD ticket is created, no Hybrid Boundary policy change is applied, and the caller receives `HTTP 403`. The requester must pursue a manual review process.

## Trigger

- **Type**: api-call
- **Source**: Hybrid Boundary UI (`continuumHybridBoundaryUi`) calling `POST /release/par`
- **Frequency**: On-demand (per PAR form submission)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Administrator (engineer) | Initiates PAR request via Hybrid Boundary UI | `administrator` |
| Hybrid Boundary UI | Forwards PAR form data to the automation API | `continuumHybridBoundaryUi` |
| PAR Automation API | Orchestrates validation, classification, and Jira recording | `continuumParAutomationApi` |
| Service Portal | Provides regulatory classification metadata for both services | `servicePortal` |
| Hybrid Boundary Lambda API | Queried for duplicate check only; no write occurs | `continuumHybridBoundaryLambdaApi` |
| Jira | Receives PAR Task creation with `auto-denied` label | `continuumJiraService` |

## Classification Rules That Cause Denial

The Policy Automation Rules Engine (`policyAutomationRulesEngine`) denies the request under the following conditions (evaluated in order):

| Condition | Denial Reason |
|-----------|--------------|
| Either service is PCI-classified | All PCI combinations require manual PAR review |
| `FromService.Sox == false` AND `ToService.Sox == true` | Non-SOX service accessing SOX domain requires manual review |
| `FromService` is C2 AND `ToService` is C1 | C2 service cannot automatically access C1 domain |
| `FromService` is C3 AND `ToService` is C1 or C2 | C3 service cannot automatically access a higher-class domain |
| `FromService` is unclassified AND `ToService` is classified (C1/C2/C3) | Unclassified service cannot automatically access a classified domain |

## Steps

1. **Submit PAR request**: Administrator submits the PAR form in the Hybrid Boundary UI.
   - From: `administrator`
   - To: `continuumHybridBoundaryUi`
   - Protocol: HTTPS / browser

2. **Forward request to PAR Automation API**:
   - From: `continuumHybridBoundaryUi`
   - To: `continuumParAutomationApi` — `POST /release/par`
   - Protocol: REST/HTTP

3. **Validate payload**: All four fields checked; returns `HTTP 400` if any are missing.
   - From: `parRequestHandler`
   - To: (internal validation)

4. **Fetch FromService metadata from Service Portal**:
   - From: `continuumParAutomationApi`
   - To: `servicePortal`
   - Protocol: REST/HTTP

5. **Fetch ToDomain metadata from Service Portal**:
   - From: `continuumParAutomationApi`
   - To: `servicePortal`
   - Protocol: REST/HTTP

6. **Evaluate classification rules**: The Policy Automation Rules Engine determines `automatable = false` and sets the denial message.
   - From: `policyAutomationRulesEngine`
   - To: (in-process decision)

7. **Check for duplicate policy**: Even if the request will be denied, a duplicate check is performed to prevent recording a denial for an already-existing policy.
   - From: `continuumParAutomationApi`
   - To: `continuumHybridBoundaryLambdaApi`
   - Protocol: REST/HTTP

8. **Create PAR Jira ticket with `auto-denied` label**: PAR Task created, transitioned to `In Review`; NOT transitioned to `Approve`.
   - From: `continuumParAutomationApi`
   - To: `continuumJiraService`
   - Protocol: REST/HTTPS

9. **Return denial response**: PAR Automation returns `HTTP 403` with the denial description and the PAR ticket key. No GPROD ticket key is returned.
   - From: `continuumParAutomationApi`
   - To: `continuumHybridBoundaryUi`
   - Protocol: REST/HTTP
   - Payload: `{"Description": "Access Denied: ...", "PAR": "PAR-XXXX", "GPROD": ""}`

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing request fields | Validate on entry; return `HTTP 400` | Request rejected; no downstream calls |
| Service not found in Service Portal | Return `HTTP 404` | Request rejected; no Jira ticket |
| Duplicate principal exists | Return `HTTP 400` after duplicate check | Request rejected; no Jira ticket |
| Jira ticket creation fails | Return `HTTP 500` | No record created; no policy change |

## Sequence Diagram

```
Administrator         -> HybridBoundaryUI         : Submit PAR form
HybridBoundaryUI      -> ParAutomationAPI          : POST /release/par
ParAutomationAPI      -> ServicePortal             : GET /api/v2/services/{FromService}?includes=regulatory_classifications
ServicePortal         --> ParAutomationAPI         : 200 OK (classifications)
ParAutomationAPI      -> ServicePortal             : GET /api/v2/services/{ToDomain}?includes=regulatory_classifications
ServicePortal         --> ParAutomationAPI         : 200 OK (classifications)
ParAutomationAPI      -> ParAutomationAPI          : canAutomatePar() => false (denial message set)
ParAutomationAPI      -> HybridBoundaryLambdaAPI   : GET .../authorization/policies (duplicate check)
HybridBoundaryLambdaAPI --> ParAutomationAPI       : 200 OK (no duplicate)
ParAutomationAPI      -> Jira                      : Create PAR Task (auto-denied label)
Jira                  --> ParAutomationAPI         : PAR-XXXX created
ParAutomationAPI      -> Jira                      : Transition PAR to "In Review"
ParAutomationAPI      --> HybridBoundaryUI         : 403 Forbidden {"Description": "Access Denied: ...", "PAR": "PAR-XXXX"}
```

## Related

- Architecture dynamic view: `dynamic-par-request-automation-flow`
- Related flows: [PAR Request — Auto-Approved (Production)](par-request-auto-approved-production.md), [PAR Request — Non-Production](par-request-non-production.md), [Duplicate PAR Detection](duplicate-par-detection.md)
