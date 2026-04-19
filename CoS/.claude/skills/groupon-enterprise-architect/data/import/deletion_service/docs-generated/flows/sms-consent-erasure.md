---
service: "deletion_service"
title: "SMS Consent Erasure (Attentive)"
generated: "2026-03-03"
type: flow
flow_name: "sms-consent-erasure"
flow_type: event-driven
trigger: "MBUS message on jms.topic.scs.subscription.erasure OR POST /customer with option=ATTENTIVE"
participants:
  - "continuumDeletionServiceApp"
  - "continuumDeletionServiceDb"
  - "rocketmanTransactionalApi"
  - "mbusGdprAccountErasedCompleteQueue"
architecture_ref: "dynamic-erase-request-flow"
---

# SMS Consent Erasure (Attentive)

## Summary

The SMS Consent Erasure flow handles the deletion of a customer's SMS subscription consent data from the Attentive platform. It can be triggered either by an MBUS event on the `jms.topic.scs.subscription.erasure` topic (consumed by a dedicated Erase Message Worker configured with `EraseOption.ATTENTIVE`) or manually via `POST /customer?option=ATTENTIVE`. The Deletion Service calls the Rocketman transactional email API at `POST /transactional/sendmessage` with a templated Attentive deletion request. On success, the Rocketman `sendId` is stored in the Deletion Service database and a per-service completion event is published to MBUS. This flow is active only for NA region; the EMEA service map for `ATTENTIVE` is empty.

## Trigger

- **Type**: event or api-call
- **Source**:
  - MBUS topic `jms.topic.scs.subscription.erasure` (automatic, event-driven)
  - `POST /customer?option=ATTENTIVE` (manual, admin REST API)
- **Frequency**: On-demand — triggered per user SMS consent erasure request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MBUS `jms.topic.scs.subscription.erasure` | Event source (automated path) | `mbusScsSubscriptionErasureTopic` |
| Customer Resource (`customerResource`) | API entry point (manual path) | `continuumDeletionServiceApp` |
| Erase Message Worker (`eraseMessageWorker`) | Consumes the SMS consent erase event | `continuumDeletionServiceApp` |
| Create Customer Service (`createCustomerService`) | Creates erase request with `SMS_CONSENT_SERVICE` task | `continuumDeletionServiceApp` |
| Erase Request Action (`eraseRequestAction`) | Orchestrates erasure; invokes SMS Consent Integration | `continuumDeletionServiceApp` |
| SMS Consent Integration (`smsConsentIntegration`) | Sends Attentive deletion request via Rocketman | `continuumDeletionServiceApp` |
| Rocketman Client (`rocketmanClient`) | Retrofit HTTP client for `POST /transactional/sendmessage` | `continuumDeletionServiceApp` |
| Rocketman Transactional API | External email gateway that triggers Attentive consent deletion | `rocketmanTransactionalApi` |
| Deletion Service DB | Persists erase request, service task status, and Rocketman send ID | `continuumDeletionServiceDb` |
| Message Publisher | Publishes completion event to MBUS | `continuumDeletionServiceApp` |
| MBUS `jms.queue.gdpr.account.v1.erased.complete` | Receives the per-service completion event | `mbusGdprAccountErasedCompleteQueue` |

## Steps

1. **Receive SMS consent erasure trigger**: Either the MBUS consumer receives an `EraseMessage` from `jms.topic.scs.subscription.erasure`, or an admin submits `POST /customer?option=ATTENTIVE&customerId={id}`.
   - From: MBUS or REST client
   - To: `eraseMessageWorker` or `customerResource`
   - Protocol: MBUS (JMS) or REST

2. **Create erase request and service task**: `CreateCustomerService.createCustomerRequest(message, isEmea, EraseOption.ATTENTIVE)` resolves `EraseServiceType.ERASE_SERVICE_MAP[ATTENTIVE][NA]` = `[SMS_CONSENT_SERVICE]` and writes an erase request row and one `SMS_CONSENT_SERVICE` service task row to `continuumDeletionServiceDb`.
   - From: `createCustomerService`
   - To: `continuumDeletionServiceDb`
   - Protocol: JDBC / PostgreSQL

3. **Scheduler picks up pending task**: The Quartz scheduler (next 30-minute cycle) loads the erase request and finds the `SMS_CONSENT_SERVICE` task unfinished.
   - From: Quartz / `eraseRequestAction`
   - To: `continuumDeletionServiceDb`
   - Protocol: JDBC / PostgreSQL

4. **Skip fulfillment check**: Because `SMS_CONSENT_SERVICE` is in `SERVICES_ORDERS_NOT_REQUIRED`, the fulfillment line item check is bypassed. The integration proceeds regardless of whether the customer has orders.
   - From: `eraseRequestAction`
   - To: `eraseRequestAction` (in-process check)
   - Protocol: direct

5. **Mark task started**: `eraseServiceQuery.updateStartedAt(serviceId)` records the start timestamp.
   - From: `eraseRequestAction`
   - To: `continuumDeletionServiceDb`
   - Protocol: JDBC / PostgreSQL

6. **Build Attentive email request**: `SmsConsentServiceIntegration.erase(customerId)` builds an `AttentiveEmailRequest` with the configured `emailTo`, `carbonCopy`, and `emailType` values.
   - From: `smsConsentIntegration`
   - To: `rocketmanClient` (in-process)
   - Protocol: direct

7. **Send Attentive deletion request**: `RocketmanClient.sendAttentiveBastRequest(emailRequest)` posts to `POST /transactional/sendmessage` on the Rocketman API.
   - From: `rocketmanClient`
   - To: Rocketman Transactional API
   - Protocol: REST / HTTPS

8. **Process Rocketman response**: If `response.getSuccess() == true`, the `sendId` is stored via `smsConsentServiceQuery.saveSendId(consumerId, sendId)`. If `success == false`, `IntegrationFailedException` is thrown.
   - From: `smsConsentIntegration`
   - To: `continuumDeletionServiceDb`
   - Protocol: JDBC / PostgreSQL

9. **Mark task finished and publish completion**: `eraseServiceQuery.updateFinished(serviceId)` updates the task; `MessagePublisher.publishCompleteMessage(EraseServiceType.SMS_CONSENT_SERVICE, eraseRequest)` publishes a completion event with `serviceId = "sms-consent-service"`.
   - From: `eraseRequestAction` and `deletionService_messagePublisher`
   - To: `continuumDeletionServiceDb` and `jms.queue.gdpr.account.v1.erased.complete`
   - Protocol: JDBC / PostgreSQL and MBUS (JMS queue)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Rocketman returns `success=false` | `IntegrationFailedException` thrown; task marked with `UnfinishedServiceError` | Task retried on next scheduler cycle up to `eraseRequestMaxRetries` |
| Rocketman API unreachable / timeout | Exception propagated; `updateFailedEraseService()` records error | Task marked failed; retried on next scheduler cycle |
| `ATTENTIVE` option selected for EMEA region | `ERASE_SERVICE_MAP[ATTENTIVE][EMEA]` is empty; no service tasks created | Erase request created but immediately completable (no tasks) |
| `smsConsentMessageBus` misconfigured | MBUS consumer fails to start; no events consumed | Manual API submission still functions; fix requires config update and redeploy |

## Sequence Diagram

```
MBUS(scs.subscription.erasure) -> EraseMessageWorker: EraseMessage{accountId, option=ATTENTIVE}
EraseMessageWorker -> CreateCustomerService: createCustomerRequest(payload, isEmea=false, ATTENTIVE)
CreateCustomerService -> DeletionServiceDb: INSERT erase_request
CreateCustomerService -> DeletionServiceDb: INSERT erase_service (SMS_CONSENT_SERVICE)
EraseMessageWorker -> MBUS: ACK
...30 min later...
QuartzScheduler -> EraseRequestAction: eraseUnfinishedRequests()
EraseRequestAction -> DeletionServiceDb: SELECT unfinished requests
EraseRequestAction -> DeletionServiceDb: UPDATE erase_service SET started_at (SMS_CONSENT_SERVICE)
EraseRequestAction -> SmsConsentIntegration: erase(customerId)
SmsConsentIntegration -> RocketmanClient: POST /transactional/sendmessage {emailTo, emailType, consumerId}
RocketmanClient -> RocketmanAPI: HTTP POST /transactional/sendmessage
RocketmanAPI --> RocketmanClient: {success: true, sendId: "..."}
RocketmanClient --> SmsConsentIntegration: RocketmanEmailResponse
SmsConsentIntegration -> DeletionServiceDb: INSERT sms_consent_send (consumerId, sendId)
SmsConsentIntegration --> EraseRequestAction: success
EraseRequestAction -> DeletionServiceDb: UPDATE erase_service SET finished_at
EraseRequestAction -> MessagePublisher: publishCompleteMessage("sms-consent-service", request)
MessagePublisher -> MBUS(erased.complete): PublishMessage{serviceId="sms-consent-service"}
```

## Related

- Architecture dynamic view: `dynamic-erase-request-flow`
- Related flows: [GDPR Erase Event Ingestion](erase-event-ingestion.md), [Scheduled Erasure Execution](scheduled-erasure-execution.md)
