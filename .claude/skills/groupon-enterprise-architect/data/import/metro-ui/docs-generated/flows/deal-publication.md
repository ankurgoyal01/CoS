---
service: "metro-ui"
title: "Deal Publication"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-publication"
flow_type: synchronous
trigger: "Merchant submits a completed deal for publication"
participants:
  - "continuumMetroUiService"
  - "metroUi_routing"
  - "metroUi_integrationAdapters"
  - "apiProxy"
  - "continuumDealManagementApi"
  - "continuumMarketingDealService"
architecture_ref: "dynamic-metro-ui-draft-edit-flow"
---

# Deal Publication

## Summary

This flow covers the process by which a merchant submits a completed deal draft for publication. Metro UI coordinates eligibility checks via `continuumMarketingDealService` and transitions the deal state in `continuumDealManagementApi`. The flow enforces that all required deal fields are valid and that the merchant meets campaign eligibility criteria before the deal is submitted for publication.

## Trigger

- **Type**: user-action
- **Source**: Merchant clicks the "Submit" or "Publish" action in the deal creation form
- **Frequency**: On-demand (once per deal publication attempt)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (Browser) | Initiates the publication submission | External user |
| Routing and Controllers | Receives the submit request and dispatches publication actions | `metroUi_routing` |
| Integration Adapters | Orchestrates eligibility checks and deal state transition calls | `metroUi_integrationAdapters` |
| API Proxy | Routes deal management API traffic | `apiProxy` |
| Deal Management API | Persists the final deal state and triggers publication | `continuumDealManagementApi` |
| Marketing Deal Service | Validates merchant campaign eligibility before publication | `continuumMarketingDealService` |

## Steps

1. **Submit Deal for Publication**: Merchant browser submits the completed deal form.
   - From: Merchant Browser
   - To: `metroUi_routing`
   - Protocol: HTTPS/JSON

2. **Dispatch Publication Flow**: Route handler invokes the integration adapters to run the publication workflow.
   - From: `metroUi_routing`
   - To: `metroUi_integrationAdapters`
   - Protocol: Internal

3. **Check Campaign and Merchant Eligibility**: Integration adapters call `continuumMarketingDealService` to validate that the merchant and deal meet campaign eligibility criteria.
   - From: `metroUi_integrationAdapters`
   - To: `continuumMarketingDealService`
   - Protocol: HTTPS/JSON

4. **Return Eligibility Result**: Marketing Deal Service returns approval or rejection with eligibility details.
   - From: `continuumMarketingDealService`
   - To: `metroUi_integrationAdapters`
   - Protocol: HTTPS/JSON

5. **Submit Deal to Deal Management API (if eligible)**: Integration adapters forward the publish request via `apiProxy` to `continuumDealManagementApi` to transition the deal to published state.
   - From: `metroUi_integrationAdapters`
   - To: `apiProxy` -> `continuumDealManagementApi`
   - Protocol: HTTPS/JSON

6. **Confirm Publication State**: Deal Management API confirms the deal state transition and returns the updated deal record.
   - From: `continuumDealManagementApi`
   - To: `metroUi_integrationAdapters` (via `apiProxy`)
   - Protocol: HTTPS/JSON

7. **Return Outcome to Merchant**: Metro UI returns success or failure response to the merchant browser; the UI reflects the publication outcome.
   - From: `metroUi_routing`
   - To: Merchant Browser
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Merchant ineligible for campaign | `continuumMarketingDealService` returns rejection | UI displays eligibility error; deal not submitted |
| `continuumDealManagementApi` error on publish | Error propagated to browser | Publication fails; merchant retains draft; error message displayed |
| `continuumMarketingDealService` unreachable | Error returned to browser | Publication blocked; eligibility checks cannot be completed |
| `apiProxy` unreachable | Error returned to browser | Publication blocked; deal remains in draft state |

## Sequence Diagram

```
Merchant Browser -> metroUi_routing: POST deal publication submit
metroUi_routing -> metroUi_integrationAdapters: Run publication workflow
metroUi_integrationAdapters -> continuumMarketingDealService: Check campaign and merchant eligibility (HTTPS/JSON)
continuumMarketingDealService --> metroUi_integrationAdapters: Eligibility result
metroUi_integrationAdapters -> apiProxy: Submit deal for publication (HTTPS/JSON)
apiProxy -> continuumDealManagementApi: Transition deal to published state (HTTPS/JSON)
continuumDealManagementApi --> apiProxy: Confirmed deal state
apiProxy --> metroUi_integrationAdapters: Confirmed deal state
metroUi_integrationAdapters --> metroUi_routing: Publication outcome
metroUi_routing --> Merchant Browser: Success or error response
```

## Related

- Architecture dynamic view: `dynamic-metro-ui-draft-edit-flow`
- Related flows: [Deal Creation and Draft](deal-creation-and-draft.md), [Location and Service Area Management](location-service-area-management.md)
