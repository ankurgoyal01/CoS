---
service: "third-party-mailmonger"
title: "Inbound Email Relay — Partner to Consumer"
generated: "2026-03-03"
type: flow
flow_name: "inbound-email-partner-to-consumer"
flow_type: asynchronous
trigger: "Partner sends SMTP email to masked consumer address; SparkPost relay webhook fires"
participants:
  - "Partner"
  - "sparkpost"
  - "continuumThirdPartyMailmongerService"
  - "messageBus"
  - "continuumUsersService"
  - "daasPostgres"
architecture_ref: "dynamic-third-party-mailmonger"
---

# Inbound Email Relay — Partner to Consumer

## Summary

When a partner sends an email to a masked consumer address (obtained during deal reservation), SparkPost intercepts the SMTP message via its relay webhook configuration and forwards it as an HTTP POST to Mailmonger. Mailmonger logs the raw email, publishes an async processing event to the MessageBus, then runs the full filter pipeline. If the email passes all filters, Mailmonger re-sends it to the real consumer email address (retrieved from users-service) with the masked partner address as the From header, preserving anonymity on both sides.

## Trigger

- **Type**: event (SparkPost relay webhook)
- **Source**: Partner sends SMTP email to `{masked-consumer}@{sparkpost-relay-domain}`
- **Frequency**: On-demand (whenever a partner sends an email to a masked consumer address)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Partner | Initiator — sends SMTP email to masked consumer address | External |
| SparkPost | Relay gateway — receives SMTP, forwards via webhook | `sparkpost` |
| Third Party Mailmonger | Orchestrator — receives webhook, filters, transforms, sends | `continuumThirdPartyMailmongerService` |
| MessageBus | Async queue — decouples webhook receipt from email processing | `messageBus` |
| users-service | Provides real consumer email address by consumer UUID | `continuumUsersService` |
| PostgreSQL (DaaS) | Stores raw email content and delivery status | `daasPostgres` |

## Steps

1. **Partner sends SMTP email**: Partner SMTP client sends email to masked consumer address on SparkPost-managed relay domain.
   - From: `Partner`
   - To: `sparkpost`
   - Protocol: SMTP

2. **SparkPost delivers relay webhook**: SparkPost relay webhook fires and POSTs the relay message (JSON with `msys.relay_message` structure containing `content`, `msg_from`, `rcpt_to`, `friendly_from`, `customer_id`, `webhook_id`) to Mailmonger.
   - From: `sparkpost`
   - To: `continuumThirdPartyMailmongerService` (`POST /mailmonger/v1/sparkpost-callback`)
   - Protocol: HTTPS

3. **Saves raw email and publishes event**: API Resources (`thirdPartyMailmonger_apiResources`) saves the raw SparkPost relay message to `sparkpost_raw_emails` and `email_content` tables (status: `Pending`), then publishes a `MailmongerEmailMessage` (containing the `emailContentId` UUID) to the MessageBus queue `jms.queue.3pip.mailmonger`.
   - From: `thirdPartyMailmonger_apiResources` → `emailServices` → `emailDaos`
   - To: `daasPostgres` and `messageBus`
   - Protocol: JDBC and Mbus

4. **MessageBus consumer picks up event**: The `MessageBus Consumer` component dequeues the `MailmongerEmailMessage`, resolves the full `EmailContent` from PostgreSQL by the UUID.
   - From: `thirdPartyMailmonger_messageBusConsumer`
   - To: `emailDaos` → `daasPostgres`
   - Protocol: JDBC

5. **Resolves sender email ID**: If `sender_email_id` is missing from the stored `email_content`, the `EmailTransformService` reassigns it by looking up the masked email in the database.
   - From: `emailServices`
   - To: `emailDaos` → `daasPostgres`
   - Protocol: JDBC

6. **Runs filter pipeline**: `EmailFilterService` applies rules in order: SpamFilter, DailyEmailCountByPartnerFilter (max 100 per partner per day), RfcBase64Filter (blocks Base64-encoded bodies), WhiteListUrlFilter (validates all URLs against configured whitelist), UnauthorizedPartnerEmailFilter (verifies sender is authorized for target consumer), optional BlackHoleRule.
   - From: `emailServices`
   - To: (in-process filter rules using `emailDaos` for count checks)
   - Protocol: Direct

7. **Fetches real consumer email**: `EmailSenderService` calls users-service to resolve the real consumer email address from the consumer UUID stored in the masked email mapping.
   - From: `thirdPartyMailmonger_userServiceClient`
   - To: `continuumUsersService`
   - Protocol: HTTP (Retrofit)

8. **Sends email to real consumer**: Email is re-sent via SparkPost API (or MTA fallback) with `To: {real consumer email}` and `From: {masked partner address}`. The consumer receives the email without seeing the partner's real email or being aware of the relay.
   - From: `emailServices` → `sparkpostClient` (or `mtaClient`)
   - To: `sparkpost` (or `mta`)
   - Protocol: HTTPS (SparkPost SDK) or SMTP (Jakarta Mail)

9. **SparkPost delivers to consumer**: SparkPost delivers the email to the real consumer via SMTP.
   - From: `sparkpost`
   - To: Consumer email inbox
   - Protocol: SMTP

10. **Updates delivery status**: `emailContentDAO.updateEmail()` records the final status (`Delivered`, `SparkpostFailure`, `MtaFailure`, or `FilterFailure`) and increments `sent_count`.
    - From: `emailServices`
    - To: `emailDaos` → `daasPostgres`
    - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Filter rule rejects email | Status set to `FilterFailure`; message acked | Email not delivered; logged in DB |
| SparkPost send failure | Status set to `SparkpostFailure`; retry on next message bus attempt (up to 3) | Retried until MAX_SEND_LIMIT; then terminal |
| MTA send failure | Status set to `MtaFailure`; retry logic applies | Retried until MAX_SEND_LIMIT; then terminal |
| Parse error (IOException) | Status set to `NonRetriable`; message nacked | Email not retried automatically |
| users-service unavailable | Email send fails; retry applies | Retried up to MAX_SEND_LIMIT |
| Unknown masked email (bounce) | Bounce forwarded back to partner | Partner receives SMTP bounce notification |

## Sequence Diagram

```
Partner     -> SparkPost    : SMTP sendEmail(toMaskedConsumerEmail, fromPartnerEmail)
SparkPost   -> 3PM          : POST /mailmonger/v1/sparkpost-callback (relay message JSON)
3PM         -> PostgreSQL   : INSERT sparkpost_raw_emails, email_content (status=Pending)
3PM         -> MessageBus   : publish MailmongerEmailMessage(emailContentId)
3PM         --> SparkPost   : HTTP 200 (acknowledged)
MessageBus  -> 3PM          : consume MailmongerEmailMessage
3PM         -> PostgreSQL   : SELECT email_content WHERE id = emailContentId
3PM         -> 3PM          : Run filter pipeline (SpamFilter, DailyLimit, Base64, Whitelist, UnauthorizedPartner)
3PM         -> UsersService : GET /users/v1/accounts (resolve real consumer email)
UsersService --> 3PM        : real consumer email address
3PM         -> SparkPost    : sendEmail(toRealConsumerEmail, fromMaskedPartnerEmail)
SparkPost   -> Consumer     : SMTP deliverEmail
3PM         -> PostgreSQL   : UPDATE email_content SET status=Delivered, sent_count++
```

## Related

- Architecture dynamic view: `dynamic-third-party-mailmonger`
- Related flows: [Masked Email Provisioning](masked-email-provisioning.md), [Inbound Email Relay — Consumer to Partner](inbound-email-consumer-to-partner.md), [Email Filter Pipeline](email-filter-pipeline.md), [Email Retry and Scheduled Send](email-retry-scheduled.md)
