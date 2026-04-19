---
service: "par-automation"
title: "PAR Request — Auto-Approved (Production)"
generated: "2026-03-03"
type: flow
flow_name: "par-request-auto-approved-production"
flow_type: synchronous
trigger: "POST /release/par from Hybrid Boundary UI"
participants:
  - "administrator"
  - "continuumHybridBoundaryUi"
  - "continuumParAutomationApi"
  - "servicePortal"
  - "oktaIdp"
  - "continuumHybridBoundaryLambdaApi"
  - "continuumJiraService"
  - "cloudPlatform"
architecture_ref: "dynamic-par-request-automation-flow"
---

# PAR Request — Auto-Approved (Production)

## Summary

This flow describes the complete production path when a developer submits a PAR request that is eligible for automatic approval based on service data-classification rules. The service evaluates both the requesting service and target domain's regulatory classifications (C1/C2/C3/SOX/PCI), creates Jira PAR and GPROD tickets, applies the authorization policy to Hybrid Boundary, and returns the ticket identifiers to the caller. The whole interaction occurs synchronously within a single HTTP request/response cycle.

## Trigger

- **Type**: api-call
- **Source**: Hybrid Boundary UI (`continuumHybridBoundaryUi`) calling `POST /release/par` on behalf of a logged-in engineer
- **Frequency**: On-demand (per PAR form submission)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Administrator (engineer) | Initiates PAR request via the Hybrid Boundary UI | `administrator` |
| Hybrid Boundary UI | Forwards PAR form data to the automation API | `continuumHybridBoundaryUi` |
| PAR Automation API | Orchestrates validation, classification, Jira, and policy update | `continuumParAutomationApi` |
| Service Portal | Provides service metadata and regulatory classifications | `servicePortal` |
| Okta IdP | Issues OAuth2 bearer token for Hybrid Boundary API authentication | `oktaIdp` |
| Hybrid Boundary Lambda API | Stores the new authorization policy entry | `continuumHybridBoundaryLambdaApi` |
| Jira | Receives PAR Task and GPROD Logbook ticket creation requests | `continuumJiraService` |
| GCP Secret Manager | Provides service credentials at startup | `cloudPlatform` |

## Steps

1. **Submit PAR request**: Administrator fills in the PAR form in the Hybrid Boundary UI, providing `FromService`, `ToDomain`, `User`, and `Reason`.
   - From: `administrator`
   - To: `continuumHybridBoundaryUi`
   - Protocol: HTTPS / browser

2. **Forward request to PAR Automation API**: The Hybrid Boundary UI posts the form data.
   - From: `continuumHybridBoundaryUi`
   - To: `continuumParAutomationApi` — `POST /release/par`
   - Protocol: REST/HTTP
   - Payload: `{"FromService": "...", "ToDomain": "...", "User": "...", "Reason": "..."}`

3. **Validate payload**: The PAR Request Handler checks that all four fields (`FromService`, `ToDomain`, `User`, `Reason`) are non-empty; returns `HTTP 400` if any are missing.
   - From: `parRequestHandler`
   - To: (internal validation)

4. **Check Service Portal availability and fetch FromService metadata**: The Service Portal Client calls `GET /grpn/healthcheck` then `GET /api/v2/services/{FromService}?includes=regulatory_classifications`.
   - From: `continuumParAutomationApi`
   - To: `servicePortal`
   - Protocol: REST/HTTP

5. **Fetch ToDomain metadata**: The Service Portal Client repeats the lookup for the target domain.
   - From: `continuumParAutomationApi`
   - To: `servicePortal`
   - Protocol: REST/HTTP

6. **Evaluate classification rules**: The Policy Automation Rules Engine determines approvability using both services' C1/C2/C3/SOX/PCI attributes. For this flow, the result is `automatable = true`.
   - From: `policyAutomationRulesEngine`
   - To: (in-process decision)

7. **Check for duplicate policy**: The Hybrid Boundary Client calls `GET /release/v1/services/{toService}/{toDomain}/authorization/policies` to verify the requesting service's principal does not already have access.
   - From: `continuumParAutomationApi`
   - To: `continuumHybridBoundaryLambdaApi`
   - Protocol: REST/HTTP

8. **Create PAR Jira ticket**: The Jira Client creates a Task in the `PAR` project with `auto-approved` label, sets status to `In Review`, then transitions to `Approve`.
   - From: `continuumParAutomationApi`
   - To: `continuumJiraService`
   - Protocol: REST/HTTPS

9. **Create GPROD Jira ticket**: The Jira Client creates a Logbook in the `GPROD` project; links it back to the PAR ticket by updating the PAR description.
   - From: `continuumParAutomationApi`
   - To: `continuumJiraService`
   - Protocol: REST/HTTPS

10. **Obtain Okta bearer token**: The Okta Client requests a token using the `svc_hbuser` credentials via OAuth2 password grant.
    - From: `continuumParAutomationApi`
    - To: `oktaIdp`
    - Protocol: OAuth2/HTTPS

11. **Apply authorization policy**: The Hybrid Boundary Client posts the new policy entry with the requester's principal(s), GPROD key as comment, and signed-off-by user.
    - From: `continuumParAutomationApi`
    - To: `continuumHybridBoundaryLambdaApi` — `POST /release/v1/services/{toService}/{toDomain}/authorization/policies`
    - Protocol: REST/HTTP (Bearer token auth)

12. **Mark GPROD as Done**: The Jira Client transitions the GPROD ticket to `Done` status.
    - From: `continuumParAutomationApi`
    - To: `continuumJiraService`
    - Protocol: REST/HTTPS

13. **Return approval response**: PAR Automation returns `HTTP 200` with the PAR ticket key, GPROD ticket key, and approval description.
    - From: `continuumParAutomationApi`
    - To: `continuumHybridBoundaryUi`
    - Protocol: REST/HTTP
    - Payload: `{"Description": "Access Approved: ...", "PAR": "PAR-XXXX", "GPROD": "GPROD-YYYY"}`

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing request fields | Validate on entry; return `HTTP 400` immediately | Request rejected; no downstream calls made |
| Service not found in Service Portal | Return `HTTP 404` mapped to caller | Request rejected; no policy or Jira changes |
| Service Portal unavailable | Return `HTTP 500` | Request rejected; no policy or Jira changes |
| Duplicate principal already exists | Return `HTTP 400` after duplicate check | Request rejected; no Jira tickets created |
| Okta token request fails | Return `HTTP 500` | Jira tickets created; policy NOT applied; tickets left in inconsistent state |
| Hybrid Boundary API `POST` fails | Return `HTTP 500` with HB error body | Jira tickets created; policy NOT applied |
| Jira ticket creation fails | Return `HTTP 500` | No Jira tickets; no policy change |
| GPROD status update fails | Return `HTTP 500` | Policy applied; GPROD may remain open |

## Sequence Diagram

```
Administrator         -> HybridBoundaryUI         : Submit PAR form
HybridBoundaryUI      -> ParAutomationAPI          : POST /release/par (FromService, ToDomain, User, Reason)
ParAutomationAPI      -> ServicePortal             : GET /grpn/healthcheck
ServicePortal         --> ParAutomationAPI         : 200 OK
ParAutomationAPI      -> ServicePortal             : GET /api/v2/services/{FromService}?includes=regulatory_classifications
ServicePortal         --> ParAutomationAPI         : 200 OK (C1/C2/C3/SOX/PCI metadata)
ParAutomationAPI      -> ServicePortal             : GET /api/v2/services/{ToDomain}?includes=regulatory_classifications
ServicePortal         --> ParAutomationAPI         : 200 OK (C1/C2/C3/SOX/PCI metadata)
ParAutomationAPI      -> ParAutomationAPI          : canAutomatePar() => true
ParAutomationAPI      -> HybridBoundaryLambdaAPI   : GET .../authorization/policies (duplicate check)
HybridBoundaryLambdaAPI --> ParAutomationAPI       : 200 OK (no duplicate found)
ParAutomationAPI      -> Jira                      : Create PAR Task (auto-approved label)
Jira                  --> ParAutomationAPI         : PAR-XXXX created
ParAutomationAPI      -> Jira                      : Transition PAR to "In Review" -> "Approve"
ParAutomationAPI      -> Jira                      : Create GPROD Logbook
Jira                  --> ParAutomationAPI         : GPROD-YYYY created
ParAutomationAPI      -> Jira                      : Update PAR description with GPROD link
ParAutomationAPI      -> OktaIdP                   : POST /oauth2/.../v1/token (password grant)
OktaIdP               --> ParAutomationAPI         : id_token
ParAutomationAPI      -> HybridBoundaryLambdaAPI   : POST .../authorization/policies (Bearer token)
HybridBoundaryLambdaAPI --> ParAutomationAPI       : 201 Created
ParAutomationAPI      -> Jira                      : Transition GPROD to "Done"
ParAutomationAPI      --> HybridBoundaryUI         : 200 OK {"Description": "Access Approved...", "PAR": "PAR-XXXX", "GPROD": "GPROD-YYYY"}
```

## Related

- Architecture dynamic view: `dynamic-par-request-automation-flow`
- Related flows: [PAR Request — Denied](par-request-denied.md), [PAR Request — Non-Production](par-request-non-production.md), [Duplicate PAR Detection](duplicate-par-detection.md)
