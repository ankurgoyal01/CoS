---
service: "third-party-mailmonger"
title: "Email Retry and Scheduled Send"
generated: "2026-03-03"
type: flow
flow_name: "email-retry-scheduled"
flow_type: scheduled
trigger: "Quartz scheduler job fires on configured schedule; or manual POST /v1/email/{emailContentId}/retry"
participants:
  - "continuumThirdPartyMailmongerService"
  - "messageBus"
  - "daasPostgres"
architecture_ref: "dynamic-third-party-mailmonger"
---

# Email Retry and Scheduled Send

## Summary

Emails that fail delivery (status: `SparkpostFailure`, `MtaFailure`, or `Failed`) are eligible for retry, up to a maximum of MAX_SEND_LIMIT (3) total send attempts. Retry is driven by two mechanisms: a Quartz scheduler job (`EmailSchedulerJob`) that periodically queries for retriable emails and re-publishes them to the MessageBus, and a manual HTTP endpoint (`POST /v1/email/{emailContentId}/retry`) that allows operators to immediately retry a specific email. Both mechanisms re-submit the email content ID through the standard MessageBus processing pipeline.

## Trigger

- **Type**: schedule (Quartz) and manual (API call)
- **Source**: `EmailSchedulerJob` (Quartz, backed by PostgreSQL job store); or `POST /v1/email/{emailContentId}/retry` called by operator
- **Frequency**: Quartz schedule configured in JTier YAML `quartz` section; manual as needed

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Scheduler Jobs (`thirdPartyMailmonger_schedulerJobs`) | Quartz `EmailSchedulerJob` — finds retriable emails and triggers processing | `continuumThirdPartyMailmongerService` |
| Email Services (`emailServices`) | `EmailRetryService` and `EmailSchedulerTriggerService` — orchestrate retry logic | `continuumThirdPartyMailmongerService` |
| Email DAOs (`emailDaos`) | `EmailSchedulerDAO`, `EmailContentDAO` — query retriable emails; update status | `continuumThirdPartyMailmongerService` |
| MessageBus | Receives re-published email messages for re-processing | `messageBus` |
| PostgreSQL (DaaS) | Stores Quartz job state, email content, and scheduler records | `daasPostgres` |

## Steps

### Scheduled Retry Path

1. **Quartz job fires**: `EmailSchedulerJob` is triggered by its Quartz cron schedule. The Quartz job state is persisted in PostgreSQL via `jtier-quartz-postgres-migrations`.
   - From: `thirdPartyMailmonger_schedulerJobs`
   - To: `emailServices` (`EmailSchedulerTriggerService`)
   - Protocol: Direct (Quartz job execution)

2. **Queries retriable emails in batches**: `EmailSchedulerDAO` queries the database for email content IDs with retriable statuses (not `NonRetriable`, `Delivered`, or `FilterFailure`) and `sent_count < MAX_SEND_LIMIT`. Results are fetched in batches of `emailContentIdsBatchSize`.
   - From: `emailServices`
   - To: `emailDaos` → `daasPostgres`
   - Protocol: JDBC

3. **Re-publishes each email to MessageBus**: For each retriable email content ID, a new `MailmongerEmailMessage` event is published to `jms.queue.3pip.mailmonger`. The standard `EmailProcessor` (MessageBus consumer) then picks it up and processes it through the filter and send pipeline.
   - From: `emailServices` (via `EmailSchedulerTriggerService`)
   - To: `messageBus`
   - Protocol: Mbus

4. **MessageBus processing runs**: Standard email processing flow executes (filter pipeline, user lookup, send, status update). See [Inbound Email Relay — Partner to Consumer](inbound-email-partner-to-consumer.md) for the detailed processing steps.
   - From: `thirdPartyMailmonger_messageBusConsumer`
   - To: full processing pipeline
   - Protocol: Direct / JDBC / HTTP / HTTPS

### Manual Retry Path

1. **Operator calls retry endpoint**: Operator or automated tooling calls `POST /v1/email/{emailContentId}/retry`.
   - From: Operator
   - To: `continuumThirdPartyMailmongerService` (`thirdPartyMailmonger_apiResources`)
   - Protocol: REST / HTTP

2. **Validates emailContentId format**: API validates that `emailContentId` is a valid UUID; returns HTTP 400 if not.
   - From: `thirdPartyMailmonger_apiResources`
   - To: (in-process)
   - Protocol: Direct

3. **Delegates to EmailRetryService**: `EmailRetryService` is invoked with the email content ID.
   - From: `thirdPartyMailmonger_apiResources`
   - To: `emailServices`
   - Protocol: Direct

4. **Re-publishes to MessageBus**: Publishes a `MailmongerEmailMessage` for the given ID to `jms.queue.3pip.mailmonger`.
   - From: `emailServices`
   - To: `messageBus`
   - Protocol: Mbus

5. **Standard processing pipeline executes**: Same as step 4 of the scheduled path.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Email has `NonRetriable` status | Skipped by scheduler; retry endpoint still publishes but processor will ack without sending | Email remains terminal |
| `sent_count >= MAX_SEND_LIMIT` | Not queried by scheduler (below threshold check) | Email not retried automatically |
| Invalid UUID on retry endpoint | HTTP 400 returned | No message published |
| PostgreSQL unavailable during scheduler run | Quartz job fails; retried on next schedule tick | No emails re-queued until DB available |
| MessageBus unavailable | Publish fails; re-queuing not completed | Email remains in current status until next scheduler run |

## Sequence Diagram

```
QuartzScheduler -> EmailSchedulerJob     : fire (on schedule)
EmailSchedulerJob -> EmailSchedulerDAO   : SELECT email_content_ids WHERE status IN (retriable) AND sent_count < 3 LIMIT batchSize
EmailSchedulerDAO --> EmailSchedulerJob  : [emailContentId1, emailContentId2, ...]
EmailSchedulerJob -> MessageBus          : publish MailmongerEmailMessage(emailContentId) [for each]
MessageBus -> EmailProcessor             : consume MailmongerEmailMessage
EmailProcessor -> EmailContentDAO        : SELECT email_content WHERE id = emailContentId
EmailProcessor -> EmailFilterService     : run filter pipeline
EmailProcessor -> EmailSenderService     : sendEmail(emailContentWrapper)
EmailSenderService -> SparkPost          : send email
EmailProcessor -> EmailContentDAO        : UPDATE status=Delivered/Failure, sent_count++

-- Manual retry path --
Operator    -> 3PM                       : POST /v1/email/{emailContentId}/retry
3PM         -> EmailRetryService         : retry(emailContentId)
EmailRetryService -> MessageBus          : publish MailmongerEmailMessage(emailContentId)
MessageBus  -> EmailProcessor            : consume MailmongerEmailMessage (same pipeline)
```

## Related

- Architecture dynamic view: `dynamic-third-party-mailmonger`
- Related flows: [Inbound Email Relay — Partner to Consumer](inbound-email-partner-to-consumer.md), [Email Filter Pipeline](email-filter-pipeline.md)
- Retry endpoint: `POST /v1/email/{emailContentId}/retry` — see [API Surface](../api-surface.md)
