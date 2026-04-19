---
service: "booster"
title: "Integration Health Monitoring"
generated: "2026-03-03"
type: flow
flow_name: "integration-health-monitoring"
flow_type: event-driven
trigger: "API contract component emits health signals on each Booster API interaction"
participants:
  - "boosterSvc_apiContract"
  - "boosterSvc_integrationHealth"
  - "boosterSvc_supportRunbook"
architecture_ref: "dynamic-booster-relevance-request"
---

# Integration Health Monitoring

## Summary

This flow describes how the Booster integration boundary (`continuumBoosterService`) continuously monitors the health of the Booster external API. The `boosterSvc_apiContract` component emits integration health metrics and error context to `boosterSvc_integrationHealth` after each API interaction. The `boosterSvc_supportRunbook` component consumes the current health state from `boosterSvc_integrationHealth` to guide on-call engineers through incident response procedures.

## Trigger

- **Type**: event
- **Source**: Each interaction between `boosterSvc_apiContract` and the Booster external API emits health signals (availability, latency, error rate)
- **Frequency**: Continuous — triggered on every Booster API call made by `continuumRelevanceApi`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Booster API Contract | Defines integration interface; emits health signals and error context after each API call | `boosterSvc_apiContract` |
| Integration Health Monitoring | Receives and aggregates availability, latency, and error signals from the API contract | `boosterSvc_integrationHealth` |
| Support Runbook | Consumes health state from the health monitor to guide incident response for on-call engineers | `boosterSvc_supportRunbook` |

## Steps

1. **Emit integration health metrics**: After each call to the Booster external API, the `boosterSvc_apiContract` component emits availability, latency, and error context as integration health signals.
   - From: `boosterSvc_apiContract`
   - To: `boosterSvc_integrationHealth`
   - Protocol: Internal

2. **Aggregate health state**: `boosterSvc_integrationHealth` receives and aggregates the health signals to maintain a current view of Booster API availability, latency, and error rates. Metrics are surfaced to the Wavefront dashboard.
   - From: `boosterSvc_integrationHealth`
   - To: Wavefront (https://groupon.wavefront.com/u/lVgXTqptGN?t=groupon)
   - Protocol: Internal / metrics push

3. **Consume health signals for support workflows**: When an incident is triggered, `boosterSvc_supportRunbook` consults the current health state from `boosterSvc_integrationHealth` to direct on-call engineers to the appropriate resolution steps.
   - From: `boosterSvc_supportRunbook`
   - To: `boosterSvc_integrationHealth`
   - Protocol: Internal (read / query)

4. **Alert on-call engineer**: When health thresholds are breached, the monitoring system pages the on-call engineer via PagerDuty (service PPPC7X8) and notifies the team via Slack (channel C04779SKR8T).
   - From: `boosterSvc_integrationHealth`
   - To: On-call engineer
   - Protocol: PagerDuty / Slack

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Health signal emission fails | No evidence found in codebase | Potential gap in monitoring coverage |
| PagerDuty alert not acknowledged | Escalation per PagerDuty escalation policy | Escalation to relevance-engineering@groupon.com |
| Booster API health degrades below threshold | Alert fires; on-call consults `boosterSvc_supportRunbook` | Incident response initiated; vendor (Data Breakers) contacted if needed |

## Sequence Diagram

```
boosterSvc_apiContract -> boosterSvc_integrationHealth: Emit integration health metrics and error context
boosterSvc_supportRunbook -> boosterSvc_integrationHealth: Query health state for support workflows
boosterSvc_integrationHealth --> boosterSvc_supportRunbook: Current health state
boosterSvc_integrationHealth -> OnCallEngineer: PagerDuty alert (on threshold breach)
```

## Related

- Architecture dynamic view: `dynamic-booster-relevance-request`
- Component view: `components-continuum-booster-service`
- Related flows: [Booster Relevance Request](booster-relevance-request.md)
- [Runbook](../runbook.md)
- [Architecture Context](../architecture-context.md)
