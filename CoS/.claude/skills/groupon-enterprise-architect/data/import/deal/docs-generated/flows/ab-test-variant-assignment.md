---
service: "deal"
title: "AB Test Variant Assignment"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "ab-test-variant-assignment"
flow_type: synchronous
trigger: "Each deal page request requiring experiment evaluation"
participants:
  - "dealWebApp"
  - "Experimentation Service"
architecture_ref: "dynamic-continuum-ab-test-variant-assignment"
---

# AB Test Variant Assignment

## Summary

On each deal page request, `dealWebApp` calls the Experimentation Service to determine which A/B test variants and feature flag values apply to the requesting consumer. The assigned variants are used during SSR rendering to select which UI components and content blocks to include in the response. This flow runs as an early step within the broader [Deal Page Load](deal-page-load.md) flow.

## Trigger

- **Type**: api-call (sub-flow within deal page load)
- **Source**: `dealWebApp` during processing of `GET /deals/:deal-permalink`
- **Frequency**: Per deal page request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Web App | Requests variant assignment; applies variants during render | `dealWebApp` |
| Experimentation Service | Evaluates active experiments; returns variant assignments for the consumer | > No evidence found in codebase. |

## Steps

1. **Extract Consumer Context**: `dealWebApp` extracts consumer identity and session context from the incoming request (consumer ID, session cookie, device type, region).
   - From: `dealWebApp` (internal)
   - To: `dealWebApp` (internal)
   - Protocol: In-process

2. **Request Variant Assignments**: `dealWebApp` calls the Experimentation Service with the consumer context to obtain active experiment variant assignments.
   - From: `dealWebApp`
   - To: `Experimentation Service`
   - Protocol: REST/HTTP

3. **Receive Variant Assignments**: Experimentation Service returns a set of variant assignments (experiment key → variant value) applicable to the consumer for the current active experiments.
   - From: `Experimentation Service`
   - To: `dealWebApp`
   - Protocol: REST/HTTP (JSON)

4. **Evaluate Feature Flags**: `dealWebApp` passes variant assignments into `itier-feature-flags 2.2.2` to resolve feature flag states for all experiment-gated features on the deal page.
   - From: `dealWebApp` (internal)
   - To: `dealWebApp` (internal)
   - Protocol: In-process

5. **Apply Variants at Render**: Feature flag values are passed to deal page controllers (deal, buy_button_form, deal_highlights, etc.) which conditionally render variant-specific UI components.
   - From: `dealWebApp` (internal)
   - To: `dealWebApp` (internal)
   - Protocol: In-process (Preact component rendering)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Experimentation Service unavailable | Variant assignment call fails; default (control) variants used | Deal page renders with default feature set; no experiment skew |
| Experimentation Service timeout | Same as unavailable; timeout threshold enforced | Default variants applied; page load continues |

## Sequence Diagram

```
dealWebApp -> dealWebApp: extract consumer context from request
dealWebApp -> ExperimentationService: GET variant assignments (consumer context)
ExperimentationService --> dealWebApp: variant assignments (experiment key -> variant)
dealWebApp -> dealWebApp: evaluate feature flags via itier-feature-flags
dealWebApp -> dealWebApp: apply variants to deal page controllers at render
```

## Related

- Architecture dynamic view: `dynamic-continuum-ab-test-variant-assignment`
- Related flows: [Deal Page Load](deal-page-load.md)
