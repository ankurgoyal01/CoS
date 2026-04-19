---
service: "keboola"
title: "Ops Notification Flow"
generated: "2026-03-03"
type: flow
flow_name: "ops-notification-flow"
flow_type: event-driven
trigger: "Pipeline stage completion or failure event emitted by Destination Writers or Pipeline Orchestrator"
participants:
  - "kbcPipelineOrchestrator"
  - "kbcDestinationWriters"
  - "kbcOpsNotifier"
  - "googleChat"
architecture_ref: "dynamic-pipeline-run-flow"
---

# Ops Notification Flow

## Summary

The Ops Notification Flow captures how run-status events propagate from internal pipeline components to the Groupon operations team. Both the Pipeline Orchestrator (emitting overall pipeline success/failure) and the Destination Writers (reporting load-stage outcomes) feed status events to the Ops Notifier. The Ops Notifier consolidates these events and delivers alerts and notifications to the configured Google Chat space via outbound webhook. This flow is the primary visibility mechanism for Groupon teams monitoring Keboola pipeline health.

## Trigger

- **Type**: event
- **Source**: `kbcDestinationWriters` (load outcome events) and `kbcPipelineOrchestrator` (overall pipeline status events)
- **Frequency**: Per pipeline run — triggered once per run upon stage completion or failure

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Pipeline Orchestrator | Emits overall pipeline success/failure status events | `kbcPipelineOrchestrator` |
| Destination Writers | Reports destination load outcomes (success/failure) | `kbcDestinationWriters` |
| Ops Notifier | Receives status events and dispatches notifications | `kbcOpsNotifier` |
| Google Chat | Receives operational alert messages via webhook | `googleChat` |

## Steps

1. **Emit load outcome**: Destination Writers report the result of the BigQuery load stage (success or error details) to the Ops Notifier.
   - From: `kbcDestinationWriters`
   - To: `kbcOpsNotifier`
   - Protocol: Internal (Keboola platform event)

2. **Emit pipeline status**: Pipeline Orchestrator emits the overall success or failure status of the completed pipeline run to the Ops Notifier.
   - From: `kbcPipelineOrchestrator`
   - To: `kbcOpsNotifier`
   - Protocol: Internal (Keboola platform event)

3. **Format and dispatch notification**: Ops Notifier composes the alert message from received status events and sends it to the Google Chat space (`AAAArqovlCY`) via outbound webhook.
   - From: `kbcOpsNotifier`
   - To: `googleChat`
   - Protocol: Webhook (HTTPS POST)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Google Chat webhook unreachable | Notification delivery fails silently | Run result is not delivered to operations team; Keboola UI still reflects run status; no retry mechanism documented |
| Google Chat webhook returns error | Notification delivery fails | Same as above — Keboola UI is the fallback monitoring surface |

## Sequence Diagram

```
DestinationWriters -> OpsNotifier: Emit load status and errors
PipelineOrchestrator -> OpsNotifier: Emit success/failure status events
OpsNotifier -> GoogleChat: Send operational alert (Webhook HTTPS POST)
GoogleChat --> OpsNotifier: HTTP 200 OK
```

## Related

- Architecture dynamic view: `dynamic-pipeline-run-flow`
- Related flows: [Pipeline Run Flow](pipeline-run-flow.md), [Extraction Flow](extraction-flow.md)
