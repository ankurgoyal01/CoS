---
service: "metro-ui"
title: "AI Content Generation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "ai-content-generation"
flow_type: synchronous
trigger: "Merchant clicks AI content generation action in the deal creation UI"
participants:
  - "continuumMetroUiService"
  - "metroUi_routing"
  - "metroUi_integrationAdapters"
architecture_ref: "dynamic-metro-ui-draft-edit-flow"
---

# AI Content Generation

## Summary

This flow enables merchants to automatically generate deal copy (titles, descriptions) using an AI/GenAI backend service. The merchant triggers the action from the deal creation UI, Metro UI proxies the request to the AI content generation endpoint, and returns the generated content to the browser for the merchant to review and accept. The flow is orchestrated by `metroUi_integrationAdapters` via the `generate_ai_content` internal action.

## Trigger

- **Type**: user-action
- **Source**: Merchant clicks the AI content generation button in the deal creation form
- **Frequency**: On-demand (per merchant request during deal creation)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (Browser) | Initiates the AI content generation request | External user |
| Routing and Controllers | Receives the API call and dispatches to the integration adapter | `metroUi_routing` |
| Integration Adapters | Orchestrates the `generate_ai_content` action; proxies to GenAI service | `metroUi_integrationAdapters` |
| GenAI / DSSI Airflow Platform | Performs AI content generation inference (external, currently unresolved stub) | `unknown_dssiairflowplatform_ebf3826e` |

## Steps

1. **Initiate AI Content Request**: Merchant browser sends a POST request to `/v2/merchants/{id}/mdm/deals/{id}/ai/contentai` with deal context.
   - From: Merchant Browser
   - To: `metroUi_routing`
   - Protocol: HTTPS/JSON

2. **Dispatch to Integration Adapters**: Route handler invokes the `generate_ai_content` integration action with deal and merchant context.
   - From: `metroUi_routing`
   - To: `metroUi_integrationAdapters`
   - Protocol: Internal

3. **Call GenAI Service**: Integration adapters forward the content generation request to the GenAI/DSSI Airflow Platform.
   - From: `metroUi_integrationAdapters`
   - To: `unknown_dssiairflowplatform_ebf3826e` (GenAI Service)
   - Protocol: HTTPS/JSON

4. **Return Generated Content**: GenAI service returns AI-generated deal copy (titles, descriptions).
   - From: `unknown_dssiairflowplatform_ebf3826e`
   - To: `metroUi_integrationAdapters`
   - Protocol: HTTPS/JSON

5. **Return to Browser**: Metro UI returns the generated content to the merchant browser as a JSON response.
   - From: `metroUi_routing`
   - To: Merchant Browser
   - Protocol: HTTPS/JSON

6. **Merchant Reviews and Accepts**: The merchant reviews AI-generated copy in the deal editor. If accepted, the content populates the deal form fields and is saved via the [Deal Creation and Draft](deal-creation-and-draft.md) flow.
   - From: Merchant Browser
   - To: Deal form state (client-side Redux)
   - Protocol: In-browser

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GenAI service unreachable | `metroUi_integrationAdapters` returns error to browser | AI content generation button shows error; merchant must write copy manually |
| GenAI service returns invalid/empty content | Response returned as-is or with error flag | Merchant sees empty or error state in AI content panel |
| Request timeout | itier-server timeout handling | Error response returned to browser; feature gracefully unavailable |

> Note: The GenAI/DSSI Airflow Platform dependency (`unknown_dssiairflowplatform_ebf3826e`) is currently an unresolved external dependency stub in the architecture model. Confirm the exact service endpoint and auth mechanism with the DSSI platform team.

## Sequence Diagram

```
Merchant Browser -> metroUi_routing: POST /v2/merchants/{id}/mdm/deals/{id}/ai/contentai
metroUi_routing -> metroUi_integrationAdapters: generate_ai_content(deal context)
metroUi_integrationAdapters -> GenAI Service: Request AI-generated deal copy (HTTPS/JSON)
GenAI Service --> metroUi_integrationAdapters: Return generated titles and descriptions
metroUi_integrationAdapters --> metroUi_routing: Return generated content
metroUi_routing --> Merchant Browser: JSON response with AI-generated copy
```

## Related

- Architecture dynamic view: `dynamic-metro-ui-draft-edit-flow`
- Related flows: [Deal Creation and Draft](deal-creation-and-draft.md), [Deal Publication](deal-publication.md)
