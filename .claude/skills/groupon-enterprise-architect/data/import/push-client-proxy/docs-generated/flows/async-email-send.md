---
service: "push-client-proxy"
title: "Async Email Send"
generated: "2026-03-03"
type: flow
flow_name: "async-email-send"
flow_type: asynchronous
trigger: "email-send-topic Kafka message"
participants:
  - "continuumKafkaBroker"
  - "continuumPushClientProxyService"
  - "continuumPushClientProxyPostgresMainDb"
  - "smtpRelay"
architecture_ref: "dynamic-email-request-flow"
---

# Async Email Send

## Summary

Email send requests that cannot be processed synchronously, or that failed during a previous attempt and qualify for retry, are queued on the `email-send-topic` Kafka topic. push-client-proxy consumes these in batches of up to 250, validates subscription state for non-US recipients, sends each email via SMTP concurrently using a 100-thread executor, persists the send outcomes to PostgreSQL, and republishes retryable failures back to the same topic.

## Trigger

- **Type**: event
- **Source**: `continuumKafkaBroker` publishing to `email-send-topic`; also triggered by `SendEmailMessagePublisher` when a synchronous send fails
- **Frequency**: Continuous (asynchronous consumer), per retry cycle for failed sends

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kafka Broker | Event source — delivers `email-send-topic` JSON messages | `continuumKafkaBroker` |
| push-client-proxy service | Consumer — validates, sends, persists, retries | `continuumPushClientProxyService` |
| SMTP relay | Delivery target — receives injected emails | `smtpRelay` |
| Main PostgreSQL database | Persistence — stores `EmailSend` outcomes | `continuumPushClientProxyPostgresMainDb` |

## Steps

1. **Receives batch of email send messages**: `EmailSendMessageListener.listenToEmailSendMessages` receives a batch of up to 250 JSON-serialized `EmailMessage` objects from `email-send-topic` using the `emailBatchKafkaListenerContainerFactory` (batch listener, 250 records per poll, manual acknowledgment).
   - From: `continuumKafkaBroker`
   - To: `continuumPushClientProxyService` (`pcpKafkaEmailSendListener`)
   - Protocol: Kafka (SSL/TLS), consumer group `email-send-processor-group`

2. **Deserializes messages and resolves mail senders**: For each message, deserializes the JSON to `EmailMessage`, calls `EmailInjectorService.getMailSenderKey(emailMessage)` to determine the routing key, retrieves the matching `DefaultMailSender`, and creates a `MimeMessage` using `MimeMessageHelper`.
   - From: `pcpKafkaEmailSendListener`
   - To: (internal `EmailInjectorService`, `MimeMessageHelper`)
   - Protocol: direct

3. **Checks subscription state (non-US recipients)**: For each email, extracts the country code from `customHeaders`. If country is not US, calls `SubscriptionService.hasActiveSubscriptions(userId)`. If no active subscriptions found, the email is dropped (not sent).
   - From: `pcpKafkaEmailSendListener` (via `pcpSubscriptionService`)
   - To: (internal subscription check)
   - Protocol: direct

4. **Sends emails concurrently**: Submits all email send tasks to a fixed 100-thread `ExecutorService` as `CompletableFuture` tasks. Each task calls `DefaultMailSender.sendMessage(mimeMessage)`.
   - From: `pcpKafkaEmailSendListener` (via executor)
   - To: `smtpRelay`
   - Protocol: SMTP

5. **Republishes retryable failures**: If a send fails and `EmailSendRequest.canRetry()` returns true, `SendEmailMessagePublisher.publishMessage(emailSendRequest)` serializes and publishes the request back to `email-send-topic` with `requestId` as the Kafka message key.
   - From: `pcpSendEmailPublisher`
   - To: `continuumKafkaBroker` (back to `email-send-topic`)
   - Protocol: Kafka (SSL/TLS)

6. **Waits for batch completion (with timeout)**: `CompletableFuture.allOf(...).orTimeout(30000, MILLISECONDS).join()` blocks until all tasks complete or the 30-second timeout is reached. On timeout, a `RuntimeException` is thrown.
   - From: `pcpKafkaEmailSendListener`
   - To: (all futures)
   - Protocol: direct

7. **Persists batch send outcomes**: After all futures complete, batch-inserts collected `EmailSend` records to PostgreSQL via `EmailSendRepository.saveAll()`.
   - From: `pcpEmailSendRepositoryComponent`
   - To: `continuumPushClientProxyPostgresMainDb`
   - Protocol: JPA/JDBC

8. **Acknowledges Kafka batch**: Calls `acknowledgment.acknowledge()` to commit offsets for the entire batch.
   - From: `pcpKafkaEmailSendListener`
   - To: `continuumKafkaBroker`
   - Protocol: Kafka

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `JsonProcessingException` (malformed message) | Acknowledged immediately; logged as error | Message dropped; not retried |
| `EmailSendingException` on individual send | Logged; if `canRetry()` is true, republished to `email-send-topic` | Message retried up to max retry count |
| Unknown exception on individual send | Logged; message dropped | Send outcome not persisted |
| Batch timeout (30 seconds) | `RuntimeException` thrown from `orTimeout`; caught by outer catch; `acknowledgment.acknowledge()` still called | Batch acknowledged; timed-out tasks may have completed partially |
| Unexpected exception on batch level | Acknowledged (current implementation acknowledges on unknown exceptions); logged | Batch not retried; possible message loss |

## Sequence Diagram

```
KafkaBroker -> EmailSendMessageListener: email-send-topic batch (JSON EmailMessage[])
EmailSendMessageListener -> EmailInjectorService: getMailSenderKey(emailMessage) x N
EmailInjectorService --> EmailSendMessageListener: mailSenderKey x N
EmailSendMessageListener -> MimeMessageHelper: createMimeMessage(emailMessage, session) x N
EmailSendMessageListener -> SubscriptionService: hasActiveSubscriptions(userId) [non-US]
SubscriptionService --> EmailSendMessageListener: boolean
EmailSendMessageListener -> ExecutorService: submit sendMessage tasks (parallel, 100 threads)
ExecutorService -> SmtpRelay: sendMessage(mimeMessage) x N (concurrent)
SmtpRelay --> ExecutorService: sent / error
ExecutorService -> SendEmailPublisher: publishMessage(retryRequest) [on failure with retry budget]
SendEmailPublisher -> KafkaBroker: produce to email-send-topic
CompletableFuture.allOf -> EmailSendMessageListener: all done (or timeout)
EmailSendMessageListener -> EmailSendRepository: saveAll(batchPersistenceList)
EmailSendRepository -> PostgresMainDb: INSERT EmailSend records
PostgresMainDb --> EmailSendRepository: saved
EmailSendMessageListener -> KafkaBroker: acknowledge()
```

## Related

- Architecture dynamic view: `dynamic-email-request-flow`
- Related flows: [Email Send Request](email-send-request.md), [Delivery Status Callback](delivery-status-callback.md)
