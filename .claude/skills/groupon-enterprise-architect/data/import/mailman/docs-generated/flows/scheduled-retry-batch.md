---
service: "mailman"
title: "Scheduled Retry Batch"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "scheduled-retry-batch"
flow_type: scheduled
trigger: "Quartz 2.2.1 job trigger fires on configured schedule"
participants:
  - "continuumMailmanWorkflowEngine"
  - "continuumMailmanOutboundClients"
  - "continuumMailmanMessageBusIntegration"
  - "mailmanPostgres"
  - "messageBus"
architecture_ref: "dynamic-mail-processing-flow"
---

# Scheduled Retry Batch

## Summary

This flow is triggered automatically by the Quartz 2.2.1 scheduler running within the Mailman JVM. At scheduled intervals, Quartz reads pending retry payloads from `mailmanPostgres`, re-submits each failed request through the workflow engine for fresh domain context enrichment, and publishes the enriched `TransactionalEmailRequest` payloads to MBus. This provides automated recovery from transient downstream failures without requiring operator intervention.

## Trigger

- **Type**: schedule
- **Source**: Quartz 2.2.1 job trigger (JDBC-backed, configured in `mailmanPostgres`)
- **Frequency**: Configured schedule (interval not discoverable from architecture model — confirm in `quartz.properties`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Quartz Scheduler (internal) | Fires the scheduled batch job | `continuumMailmanService` |
| `continuumMailmanWorkflowEngine` | Processes each retry payload; coordinates context enrichment | `continuumMailmanWorkflowEngine` |
| `continuumMailmanOutboundClients` | Fetches fresh domain context for each retried request | `continuumMailmanOutboundClients` |
| `continuumMailmanMessageBusIntegration` | Publishes enriched payloads to MBus | `continuumMailmanMessageBusIntegration` |
| `mailmanPostgres` | Source of pending retry records; updated after each attempt | `mailmanPostgres` |
| `messageBus` | Receives enriched `TransactionalEmailRequest` for Rocketman | `messageBus` |

## Steps

1. **Quartz job fires**: Quartz scheduler reads the job trigger from `mailmanPostgres` (`QRTZ_TRIGGERS` table) and executes the retry batch job.
   - From: Quartz Scheduler
   - To: Retry batch job (internal)
   - Protocol: In-process (Quartz job execution)

2. **Queries pending retry records**: Batch job reads all eligible pending retry payloads from the retry table in `mailmanPostgres`.
   - From: Quartz batch job
   - To: `mailmanPostgres`
   - Protocol: JDBC

3. **Iterates over retry records**: For each pending retry record:

4. **Re-submits to workflow engine**: Each payload is submitted to `continuumMailmanWorkflowEngine` for re-processing.
   - From: Quartz batch job
   - To: `continuumMailmanWorkflowEngine`
   - Protocol: In-process call

5. **Fetches fresh domain context**: Workflow engine calls outbound clients to retrieve current context from applicable downstream services.
   - From: `continuumMailmanWorkflowEngine`
   - To: `continuumMailmanOutboundClients`
   - Protocol: In-process call

6. **Calls downstream context services**: Outbound clients make HTTP/JSON calls to applicable Continuum services.
   - From: `continuumMailmanOutboundClients`
   - To: Applicable context services (Orders, Users, Deal Catalog, Merchant, etc.)
   - Protocol: HTTP/JSON (Retrofit)

7. **Publishes enriched payload to MBus**: Enriched `TransactionalEmailRequest` published to MBus for Rocketman.
   - From: `continuumMailmanMessageBusIntegration`
   - To: `messageBus`
   - Protocol: MBus/JMS

8. **Updates retry record state**: Retry record in `mailmanPostgres` updated to published/resolved (or failed attempt count incremented on failure).
   - From: `continuumMailmanWorkflowEngine`
   - To: `mailmanPostgres`
   - Protocol: JDBC

9. **Quartz updates trigger for next fire**: After job completion, Quartz updates the trigger's next fire time in `mailmanPostgres`.
   - From: Quartz Scheduler
   - To: `mailmanPostgres`
   - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Context service unavailable during retry | Outbound client call fails | Retry attempt count incremented in `mailmanPostgres`; record remains eligible for next batch cycle |
| MBus publish fails | Publish call throws exception | Retry record remains in pending state; next Quartz cycle will attempt again |
| `mailmanPostgres` unavailable at job start | JDBC query fails | Quartz job fails; Quartz misfire policy applies (job rescheduled on next trigger) |
| Quartz trigger misfired | Quartz detects missed fire time | Quartz applies configured misfire instruction (typically re-fires immediately on next available thread) |

## Sequence Diagram

```
Quartz Scheduler -> mailmanPostgres: Read pending retry records
mailmanPostgres --> Quartz Scheduler: Return retry payload list
Quartz Scheduler -> continuumMailmanWorkflowEngine: Submit retry payload (per record)
continuumMailmanWorkflowEngine -> continuumMailmanOutboundClients: Fetch fresh domain context
continuumMailmanOutboundClients -> continuumOrdersService: Load order context
continuumMailmanOutboundClients -> continuumUsersService: Load user context
continuumMailmanOutboundClients --> continuumMailmanWorkflowEngine: Return enriched context
continuumMailmanWorkflowEngine -> continuumMailmanMessageBusIntegration: Publish enriched payload
continuumMailmanMessageBusIntegration -> messageBus: Publish TransactionalEmailRequest
continuumMailmanWorkflowEngine -> mailmanPostgres: Update retry record to resolved
Quartz Scheduler -> mailmanPostgres: Update trigger next fire time
```

## Related

- Architecture dynamic view: `dynamic-mail-processing-flow`
- Related flows: [Manual Retry](manual-retry.md), [MBus Message Consumption](mbus-message-consumption.md), [Submit Transactional Email](submit-transactional-email.md)
