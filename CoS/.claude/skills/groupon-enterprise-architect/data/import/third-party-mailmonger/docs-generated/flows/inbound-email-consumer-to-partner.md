---
service: "third-party-mailmonger"
title: "Inbound Email Relay — Consumer to Partner"
generated: "2026-03-03"
type: flow
flow_name: "inbound-email-consumer-to-partner"
flow_type: asynchronous
trigger: "Consumer replies to a masked partner address; SparkPost relay webhook fires"
participants:
  - "Consumer (User)"
  - "sparkpost"
  - "continuumThirdPartyMailmongerService"
  - "messageBus"
  - "daasPostgres"
architecture_ref: "dynamic-third-party-mailmonger"
---

# Inbound Email Relay — Consumer to Partner

## Summary

When a consumer replies to an email from a partner, the consumer sees a masked partner address as the sender and sends their reply to that masked address. SparkPost intercepts this reply via its relay webhook and forwards it to Mailmonger. Mailmonger logs the email, validates the sender, masks the consumer's real email address in the From header, and relays the email to the partner's real address. The partner never learns the consumer's real email address.

## Trigger

- **Type**: event (SparkPost relay webhook)
- **Source**: Consumer sends SMTP email to `{masked-partner}@{sparkpost-relay-domain}` (the masked partner address the consumer received in previous partner emails)
- **Frequency**: On-demand (whenever a consumer replies to a masked partner email)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (User) | Initiator — sends SMTP reply to masked partner address | External |
| SparkPost | Relay gateway — intercepts SMTP, forwards via webhook | `sparkpost` |
| Third Party Mailmonger | Orchestrator — receives webhook, masks consumer identity, relays to partner | `continuumThirdPartyMailmongerService` |
| MessageBus | Async queue — decouples receipt from processing | `messageBus` |
| PostgreSQL (DaaS) | Stores email content, masked email mappings, and partner email records | `daasPostgres` |

## Steps

1. **Consumer sends reply**: Consumer sends an SMTP email reply to the masked partner address on the SparkPost relay domain.
   - From: `Consumer`
   - To: `sparkpost`
   - Protocol: SMTP

2. **SparkPost delivers relay webhook**: SparkPost fires the relay webhook and POSTs the relay message to Mailmonger's callback endpoint.
   - From: `sparkpost`
   - To: `continuumThirdPartyMailmongerService` (`POST /mailmonger/v1/sparkpost-callback`)
   - Protocol: HTTPS

3. **Saves raw email and publishes event**: The API Resource saves the raw relay message to `sparkpost_raw_emails` and `email_content` (status: `Pending`), then publishes `MailmongerEmailMessage` to `jms.queue.3pip.mailmonger`.
   - From: `thirdPartyMailmonger_apiResources` → `emailServices` → `emailDaos`
   - To: `daasPostgres` and `messageBus`
   - Protocol: JDBC and Mbus

4. **MessageBus consumer picks up event**: Consumer dequeues the event and retrieves the full `EmailContent` from PostgreSQL.
   - From: `thirdPartyMailmonger_messageBusConsumer`
   - To: `emailDaos` → `daasPostgres`
   - Protocol: JDBC

5. **Resolves masked sender and partner email**: The service looks up the masked sender address from `masked_emails` and resolves the real partner email from `partner_emails` by partner ID.
   - From: `emailServices`
   - To: `emailDaos` → `daasPostgres`
   - Protocol: JDBC

6. **Runs filter pipeline**: Same ordered filter pipeline as partner-to-consumer flow (SpamFilter, DailyEmailCountByPartnerFilter, RfcBase64Filter, WhiteListUrlFilter, UnauthorizedPartnerEmailFilter).
   - From: `emailServices`
   - To: In-process filter rules
   - Protocol: Direct

7. **Transforms email addresses**: Email headers are rewritten so that `From` contains the masked consumer address and `To` contains the real partner email address.
   - From: `emailServices` (`EmailTransformService`)
   - To: (in-process)
   - Protocol: Direct

8. **Sends email to partner**: Re-addressed email is sent via SparkPost API (or MTA) with masked consumer identity as sender.
   - From: `emailServices` → `sparkpostClient` (or `mtaClient`)
   - To: `sparkpost` (or `mta`)
   - Protocol: HTTPS (SparkPost SDK) or SMTP (Jakarta Mail)

9. **SparkPost delivers to partner**: SparkPost delivers the email to the partner's real address.
   - From: `sparkpost`
   - To: Partner email inbox
   - Protocol: SMTP

10. **Updates delivery status**: Status updated to `Delivered` (or failure status) and `sent_count` incremented.
    - From: `emailServices`
    - To: `emailDaos` → `daasPostgres`
    - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Filter rejects email | Status set to `FilterFailure`; message acked | Email not delivered to partner |
| Masked partner address unknown | Email bounce returned to consumer via SparkPost | Consumer receives bounce; logged |
| SparkPost or MTA failure | Status set to `SparkpostFailure` or `MtaFailure`; retry applies | Retried up to MAX_SEND_LIMIT (3) |
| Partner email not registered | `UnauthorizedPartnerEmailFilter` blocks send | Status set to `FilterFailure` |

## Sequence Diagram

```
Consumer    -> SparkPost    : SMTP sendEmail(toMaskedPartnerEmail, fromConsumerEmail)
SparkPost   -> 3PM          : POST /mailmonger/v1/sparkpost-callback (relay message JSON)
3PM         -> PostgreSQL   : INSERT sparkpost_raw_emails, email_content (status=Pending)
3PM         -> MessageBus   : publish MailmongerEmailMessage(emailContentId)
3PM         --> SparkPost   : HTTP 200 (acknowledged)
MessageBus  -> 3PM          : consume MailmongerEmailMessage
3PM         -> PostgreSQL   : SELECT email_content, masked_emails, partner_emails
3PM         -> 3PM          : Run filter pipeline
3PM         -> 3PM          : Transform: From=maskedConsumerEmail, To=realPartnerEmail
3PM         -> SparkPost    : sendEmail(toRealPartnerEmail, fromMaskedConsumerEmail)
SparkPost   -> Partner      : SMTP deliverEmail
3PM         -> PostgreSQL   : UPDATE email_content SET status=Delivered, sent_count++
```

## Related

- Architecture dynamic view: `dynamic-third-party-mailmonger`
- Related flows: [Inbound Email Relay — Partner to Consumer](inbound-email-partner-to-consumer.md), [Email Filter Pipeline](email-filter-pipeline.md), [Masked Email Provisioning](masked-email-provisioning.md)
