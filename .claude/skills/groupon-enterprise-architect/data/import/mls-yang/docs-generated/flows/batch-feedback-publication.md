---
service: "mls-yang"
title: "Batch Feedback Publication"
generated: "2026-03-03"
type: flow
flow_name: "batch-feedback-publication"
flow_type: event-driven
trigger: "Scheduled batch job completion"
participants:
  - "smaBatch_importWorkers"
  - "smaBatch_feedbackEmitter"
  - "messageBus"
architecture_ref: "dynamic-yang-batch-import-flow"
---

# Batch Feedback Publication

## Summary

After each scheduled Quartz batch job completes (import, retention, or backfill), the Yang batch subsystem publishes a feedback command to the shared MLS message bus destination `jms.queue.mls.batchCommands`. This notifies downstream MLS platform services that the job has finished, enabling coordination and monitoring of batch pipeline completion. The feedback command wraps the job-specific payload in the standard MLS `Command` envelope with a context origin prefixed `FEEDBACK:`.

## Trigger

- **Type**: event (triggered by batch job completion)
- **Source**: Any Quartz job in the Yang Batch Scheduler — import executors, retention manager, partition manager, inventory importer, risk importer, or backfill jobs
- **Frequency**: After each job execution instance (aligns with cron schedule of the parent job)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Import / Retention Worker | Executes the batch job and triggers feedback emission on completion | `smaBatch_importWorkers` |
| Batch Feedback Emitter (`FeedbackCommandEmitter`) | Constructs the `Command` envelope and publishes to the message bus | `smaBatch_feedbackEmitter` |
| Groupon Message Bus (`jms.queue.mls.batchCommands`) | Receives and delivers the feedback command to downstream consumers | `messageBus` |

## Steps

1. **Batch job completes**: A Quartz job (e.g. `JanusDealSharesImportExecutor`, `CloRetentionManager`, `InventoryProductImportExecutor`) finishes its execution cycle.
   - From: `smaBatch_quartzScheduler`
   - To: `smaBatch_importWorkers`
   - Protocol: In-process (Quartz job lifecycle)

2. **Build feedback payload**: The job constructs a job-specific feedback payload object reflecting the outcome of the completed job.
   - From: `smaBatch_importWorkers`
   - To: `smaBatch_feedbackEmitter`
   - Protocol: In-process

3. **Construct Command envelope**: `FeedbackCommandEmitter.writeCommand(payload, origin)` creates a new MLS `Command` with:
   - A random UUID command ID
   - Context origin set to `FEEDBACK:<job_name>`
   - `createdAt` and `updatedAt` set to `now()`
   - From: `smaBatch_feedbackEmitter`
   - To: `smaBatch_feedbackEmitter` (internal)
   - Protocol: In-process

4. **Emit steno log**: Before publishing, `CommandOut` event is written to steno logging for audit and monitoring.
   - From: `smaBatch_feedbackEmitter`
   - To: logging (steno)
   - Protocol: In-process

5. **Publish to message bus**: `ProducerImpl.sendSafe` publishes the command as a JSON string message to `jms.queue.mls.batchCommands` using the configured JMS destination.
   - From: `smaBatch_feedbackEmitter`
   - To: `messageBus` (`jms.queue.mls.batchCommands`)
   - Protocol: JMS (Message Bus)
   - Host (production): `mbus-prod-na.us-central1.mbus.prod.gcp.groupondev.com`
   - Durable (production): `true`

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Message bus unavailable | `MessageBusException` thrown from `ProducerImpl.sendSafe` | Feedback command lost for this job run; parent job continues; downstream consumers see no completion signal |
| `FeedbackCommandEmitter` not started | `writer == null` guard in `start()`; `writeCommand` throws NPE if called before `start` | Pod restart initialises the emitter via Dropwizard lifecycle management |
| Producer connection failure | Exception propagates from `sendSafe` | Logged by calling job; no retry mechanism at emitter level |

## Sequence Diagram

```
QuartzJob -> FeedbackCommandEmitter: writeCommand(payload, "JanusDealSharesImport")
FeedbackCommandEmitter -> FeedbackCommandEmitter: buildCommand(UUID, "FEEDBACK:JanusDealSharesImport", now())
FeedbackCommandEmitter -> StenoLogger: writeEvent("CommandOut", command)
FeedbackCommandEmitter -> ProducerImpl: sendSafe(JsonStringMessage(command))
ProducerImpl -> MessageBus(jms.queue.mls.batchCommands): publish
MessageBus --> ProducerImpl: ACK
ProducerImpl --> FeedbackCommandEmitter: done
```

## Related

- Architecture dynamic view: `dynamic-yang-batch-import-flow`
- Related flows: [Deal Metrics Batch Import](deal-metrics-batch-import.md)
- Events documentation: [Events](../events.md)
- Configuration: `feedbackDestination` (subscriptionId, name, host, durable flag)
