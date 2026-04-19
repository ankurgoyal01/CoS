---
service: "partner-service"
title: "Simulator Testing Workflow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "simulator-testing-workflow"
flow_type: synchronous
trigger: "API call to /partner-service/v1/simulator/* endpoints"
participants:
  - "continuumPartnerService"
  - "continuumPartnerServicePostgres"
architecture_ref: "dynamic-simulator-testing-workflow"
---

# Simulator Testing Workflow

## Summary

The simulator testing workflow allows integration teams to exercise partner integration paths — including external system calls to Salesforce, Deal Catalog, Deal Management API, and ePOS — without writing to live production data. The `partnerSvc_simulatorModule` manages its own simulator session state in `continuumPartnerServicePostgres` and uses `partnerSvc_integrationClients` to invoke external systems under controlled simulation conditions. Results are returned synchronously to the caller.

## Trigger

- **Type**: api-call
- **Source**: QA engineers, integration testing pipelines, or operator tooling call the simulator endpoints under `/partner-service/v1/simulator/`
- **Frequency**: On-demand during testing and development cycles

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Partner Service | Hosts the simulator module; routes simulator API calls; persists session state | `continuumPartnerService` |
| Partner Service Postgres | Stores simulator session records, scenarios, and result data | `continuumPartnerServicePostgres` |

## Steps

1. **Receives simulator request**: Caller submits a test scenario request to a simulator endpoint.
   - From: External caller (QA tool, test pipeline)
   - To: `partnerSvc_apiResources`
   - Protocol: REST/HTTP

2. **Routes to simulator module**: API resource delegates the request to the simulator module.
   - From: `partnerSvc_apiResources`
   - To: `partnerSvc_simulatorModule`
   - Protocol: direct

3. **Creates simulator session**: Simulator module creates a new session record to track the test execution.
   - From: `partnerSvc_simulatorModule`
   - To: `continuumPartnerServicePostgres`
   - Protocol: JDBC

4. **Executes integration calls under simulation**: Simulator module invokes integration clients with simulation-mode flags, exercising external system paths (Salesforce, Deal Catalog, ePOS, etc.) under controlled conditions.
   - From: `partnerSvc_simulatorModule`
   - To: `partnerSvc_integrationClients`
   - Protocol: direct

5. **Records simulation results**: Stores the outcome of each simulated step in the session record.
   - From: `partnerSvc_simulatorModule`
   - To: `continuumPartnerServicePostgres`
   - Protocol: JDBC

6. **Returns simulation response**: Simulator module returns the session result to the API resource, which responds to the caller.
   - From: `partnerSvc_simulatorModule`
   - To: `partnerSvc_apiResources`
   - Protocol: direct

7. **Caller retrieves results**: Caller may poll the simulator GET endpoint to retrieve session status and detailed results.
   - From: External caller
   - To: `partnerSvc_apiResources`
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Simulated external system returns error | Error recorded in simulator session; returned in API response | Test identifies integration failure mode |
| Database write failure on session record | Exception returned to caller with HTTP 500 | Simulator session not created |
| Invalid simulation scenario submitted | Validated at API layer; HTTP 422 returned | Caller corrects input and retries |
| Concurrent simulator sessions | Each session is independently tracked; no cross-session interference | Parallel tests are isolated |

## Sequence Diagram

```
Caller -> partnerSvc_apiResources: POST /v1/simulator/{scenario}
partnerSvc_apiResources -> partnerSvc_simulatorModule: Delegate to simulator module
partnerSvc_simulatorModule -> continuumPartnerServicePostgres: Create simulator session
partnerSvc_simulatorModule -> partnerSvc_integrationClients: Execute simulated integration steps
partnerSvc_integrationClients --> partnerSvc_simulatorModule: Integration step results
partnerSvc_simulatorModule -> continuumPartnerServicePostgres: Write session results
partnerSvc_simulatorModule --> partnerSvc_apiResources: Session result payload
partnerSvc_apiResources --> Caller: 200 OK with simulation result
Caller -> partnerSvc_apiResources: GET /v1/simulator/{sessionId} (optional poll)
partnerSvc_apiResources -> continuumPartnerServicePostgres: Read session result
continuumPartnerServicePostgres --> partnerSvc_apiResources: Session record
partnerSvc_apiResources --> Caller: 200 OK with session detail
```

## Related

- Architecture dynamic view: `dynamic-simulator-testing-workflow`
- Related flows: [Partner Onboarding Workflow](partner-onboarding-workflow.md)
