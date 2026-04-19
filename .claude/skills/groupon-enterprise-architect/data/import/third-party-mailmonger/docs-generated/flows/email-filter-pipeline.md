---
service: "third-party-mailmonger"
title: "Email Filter Pipeline"
generated: "2026-03-03"
type: flow
flow_name: "email-filter-pipeline"
flow_type: synchronous
trigger: "MessageBus email processing — called during every inbound email relay attempt"
participants:
  - "continuumThirdPartyMailmongerService"
  - "daasPostgres"
architecture_ref: "dynamic-third-party-mailmonger"
---

# Email Filter Pipeline

## Summary

Before Mailmonger sends any relayed email, it passes the email content through an ordered chain of filter rules. Each rule evaluates a specific aspect of the email or the sending partner's behaviour. If any rule fails, the email is rejected with status `FilterFailure` and is not delivered. The filter pipeline runs synchronously inside the MessageBus consumer thread during email processing.

## Trigger

- **Type**: api-call (internal)
- **Source**: `EmailProcessor.process()` — called by the MessageBus consumer for every dequeued `MailmongerEmailMessage`
- **Frequency**: Once per email processing attempt (up to MAX_SEND_LIMIT = 3 times per email)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Email Services (`emailServices`) | Runs `EmailFilterService.check()` with all configured rules | `continuumThirdPartyMailmongerService` |
| Email DAOs (`emailDaos`) | Provides count data for rate-limit checks | `continuumThirdPartyMailmongerService` |
| PostgreSQL (DaaS) | Source of email count data and masked email records | `daasPostgres` |

## Filter Rules (Applied in Order)

| Order | Rule Class | Purpose | Failure Action |
|-------|-----------|---------|----------------|
| 1 | `SpamFilter` | Basic spam detection on email content | Reject with `FilterFailure` |
| 2 | `DailyEmailCountByPartnerFilter` | Enforces max 100 emails per partner per day | Reject with `FilterFailure` |
| 3 | `RfcBase64Filter` | Blocks emails with Base64-encoded RFC822 bodies (`email_rfc822_is_base64 = true`) | Reject with `FilterFailure` |
| 4 | `WhiteListUrlFilter` | Validates all URLs in HTML and plain-text email bodies against a configured whitelist; active when `filter.whitelistFilter = true` | Reject with `FilterFailure` |
| 5 | `UnauthorizedPartnerEmailFilter` | Verifies that the sending partner is not attempting to email a consumer outside their authorized scope | Reject with `FilterFailure` |
| 6 (optional) | `BlackHoleRule` | Unconditionally drops all emails when `filter.blackHole = true` (used for emergency suppression) | Reject with `FilterFailure` |

## Steps

1. **Retrieves email content wrapper**: `EmailProcessor` loads the `EmailContentWrapper` from the stored `EmailContent` record and resolves the `senderEmailId`.
   - From: `emailServices`
   - To: `emailDaos` → `daasPostgres`
   - Protocol: JDBC

2. **Retrieves masked sender**: Loads the `MaskedEmail` object for the sender via `maskedEmailDAO.getMaskedEmailObjectById(senderEmailId)` to determine the masked email domain (used for brand routing).
   - From: `emailServices`
   - To: `emailDaos` → `daasPostgres`
   - Protocol: JDBC

3. **Applies spam filter**: `SpamFilter` evaluates the email content for basic spam signals.
   - From: `EmailFilterService`
   - To: (in-process)
   - Protocol: Direct

4. **Applies daily rate limit filter**: `DailyEmailCountByPartnerFilter` queries `email_content` to count emails sent by this partner today; rejects if count exceeds 100.
   - From: `EmailFilterService`
   - To: `emailDaos` → `daasPostgres`
   - Protocol: JDBC

5. **Applies Base64 filter**: `RfcBase64Filter` checks the `email_rfc822_is_base64` flag from the SparkPost relay content. If true, the email is rejected.
   - From: `EmailFilterService`
   - To: (in-process)
   - Protocol: Direct

6. **Applies URL whitelist filter** (if enabled): `WhiteListUrlFilter` uses `jsoup` and `autolink` to extract all URLs from HTML and plain-text bodies, then validates each URL against the configured brand whitelist domains.
   - From: `EmailFilterService`
   - To: (in-process)
   - Protocol: Direct

7. **Applies unauthorized partner filter**: `UnauthorizedPartnerEmailFilter` verifies the sender is an authorized partner for the target consumer context.
   - From: `EmailFilterService`
   - To: `emailDaos` → `daasPostgres` (partner email domain lookup)
   - Protocol: JDBC

8. **Applies blackhole rule** (if enabled): `BlackHoleRule` unconditionally fails — used as an emergency suppress switch.
   - From: `EmailFilterService`
   - To: (in-process)
   - Protocol: Direct

9. **Returns filter result**: `FilterResult.isSuccessful()` determines whether processing continues. On failure, all applied filter names and error messages are logged and the status is set to `FilterFailure`.
   - From: `EmailFilterService`
   - To: `EmailProcessor`
   - Protocol: Direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Any filter rule returns failure | Processing stops; email not sent | `FilterFailure` status written to `email_content`; message acked |
| All filter rules pass | Email proceeds to `EmailSenderService.sendEmail()` | Email sent; status updated to `Delivered` on success |

## Sequence Diagram

```
EmailProcessor -> EmailFilterService   : check(emailContentWrapper, brand)
EmailFilterService -> SpamFilter       : check(emailContentWrapper)
SpamFilter     --> EmailFilterService  : pass/fail
EmailFilterService -> DailyRateFilter  : check(emailContentWrapper) [queries DB]
DailyRateFilter --> EmailFilterService : pass/fail
EmailFilterService -> Base64Filter     : check(emailContentWrapper)
Base64Filter   --> EmailFilterService  : pass/fail
EmailFilterService -> WhitelistFilter  : check(emailContentWrapper) [if enabled]
WhitelistFilter --> EmailFilterService : pass/fail
EmailFilterService -> PartnerAuthFilter: check(emailContentWrapper) [queries DB]
PartnerAuthFilter --> EmailFilterService: pass/fail
EmailFilterService -> BlackHoleRule    : check(emailContentWrapper) [if enabled]
BlackHoleRule  --> EmailFilterService  : pass/fail
EmailFilterService --> EmailProcessor  : FilterResult(isSuccessful, appliedFilters, errorMessages)
```

## Related

- Architecture dynamic view: `dynamic-third-party-mailmonger`
- Related flows: [Inbound Email Relay — Partner to Consumer](inbound-email-partner-to-consumer.md), [Inbound Email Relay — Consumer to Partner](inbound-email-consumer-to-partner.md)
- Filter rules source: `src/main/java/com/groupon/engage/mailmonger/core/filters/rules/`
