---
service: "ingestion-service"
title: "Failed Ticket Retry Job"
generated: "2026-03-03"
type: flow
flow_name: "failed-ticket-retry"
flow_type: scheduled
trigger: "Quartz scheduler — internal schedule"
participants:
  - "continuumIngestionService"
  - "continuumIngestionServiceMysql"
  - "salesForce"
architecture_ref: "dynamic-ticketEscalationFlow"
---

# Failed Ticket Retry Job

## Summary

The `SfCreateTicketFailuresJob` is a Quartz scheduled job that runs periodically inside the ingestion-service to retry Salesforce ticket creation requests that previously failed. When a synchronous Salesforce case creation request fails (e.g., Salesforce unavailable), the request payload is persisted to MySQL. This job reads one pending failed request at a time, determines whether it is a standard ticket or an escalation ticket, and attempts to resubmit it to Salesforce.

## Trigger

- **Type**: Schedule (Quartz job)
- **Source**: Internal Quartz scheduler (`jtier-quartz-bundle`)
- **Frequency**: Configured via `quartz` YAML block in service configuration (exact cron schedule managed in environment-specific config)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Ingestion Service (Background Jobs) | Executes the retry job; reads from MySQL; calls Salesforce | `continuumIngestionService` (`ingestionService_backgroundJobs`) |
| Ingestion Service MySQL | Source of failed ticket job queue; Salesforce token cache | `continuumIngestionServiceMysql` |
| Salesforce | Receives the retry ticket creation request | `salesForce` |

## Steps

1. **Job fires on schedule**: The Quartz scheduler triggers `SfCreateTicketFailuresJob.execute()` according to the configured cron expression.
   - From: Quartz scheduler (in-process)
   - To: `ingestionService_backgroundJobs`
   - Protocol: Quartz (in-process)

2. **Fetches one failed request**: The job calls `SfTicketCreationJobDBI.fetchOneFailedRequest()` to read one pending record from the MySQL job queue.
   - From: `ingestionService_backgroundJobs`
   - To: `continuumIngestionServiceMysql`
   - Protocol: JDBI/MySQL

3. **Checks for pending requests**: If no failed requests exist, the job logs "No requests present" and exits gracefully.

4. **Classifies ticket type**: Inspects the `requestData` JSON to determine if the record is a standard ticket (missing `caseRecordType_id`) or an escalation ticket (containing `caseRecordType_id`). Routes to the appropriate service:
   - Standard ticket: `SFTicketingService.processCreateTicketRequests()`
   - Escalation ticket: `SFEscalatingTicketService.processEscalateCreateTicketRequests()`

5. **Retries Salesforce ticket creation**: Calls Salesforce via `ingestionService_integrationClients` to create the case. Reads the SF OAuth token from MySQL before the call.
   - From: `continuumIngestionService`
   - To: `salesForce`
   - Protocol: HTTPS/REST (Salesforce Composite API)

6. **Updates job queue on result**: On success, removes or marks the record as completed in MySQL. On failure, logs the error and throws `JobExecutionException` — Quartz will retry on next schedule firing.
   - From: `ingestionService_backgroundJobs`
   - To: `continuumIngestionServiceMysql`
   - Protocol: JDBI/MySQL

7. **Logs outcome**: Logs `started`, `completed`, or `failed` status with event name `SALESFORCE_TICKET_CREATION_FAILURE_JOB` for observability.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No pending failed requests | Log "No requests present" and exit | Job completes normally; no action taken |
| Salesforce API error on retry | `InternalServerErrorException` caught; `JobExecutionException` thrown | Quartz records failure; retry on next fire |
| MySQL read error | Exception propagated | Job fails; Quartz records failure; alert fired |

## Sequence Diagram

```
QuartzScheduler -> SfCreateTicketFailuresJob: execute()
SfCreateTicketFailuresJob -> MySQL: fetchOneFailedRequest()
MySQL --> SfCreateTicketFailuresJob: SfTicketCreationRequest (or null)
SfCreateTicketFailuresJob -> SfCreateTicketFailuresJob: Check if null (exit if no requests)
SfCreateTicketFailuresJob -> SfCreateTicketFailuresJob: Classify ticket type (escalation vs standard)
SfCreateTicketFailuresJob -> SFTicketingService/SFEscalatingTicketService: processCreateTicketRequests(request)
SFTicketingService -> MySQL: Read SF OAuth token
SFTicketingService -> Salesforce: Create case (Composite API)
Salesforce --> SFTicketingService: 200 OK (success) or error
SFTicketingService -> MySQL: Update/remove job record
SFTicketingService --> SfCreateTicketFailuresJob: Response message
SfCreateTicketFailuresJob -> Logger: Log COMPLETED or FAILED
```

## Related

- Related flows: [Ticket Escalation](ticket-escalation.md)
- Architecture dynamic view: `dynamic-ticketEscalationFlow`
- See also: [Data Stores](../data-stores.md) — SF ticket creation job queue table
- Manual trigger: `GET /odis/api/v1/salesforce/ticket/triggerJob?id={id}`
