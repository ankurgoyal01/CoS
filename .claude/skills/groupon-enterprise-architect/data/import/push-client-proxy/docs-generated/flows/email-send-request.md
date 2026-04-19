---
service: "push-client-proxy"
title: "Email Send Request"
generated: "2026-03-03"
type: flow
flow_name: "email-send-request"
flow_type: synchronous
trigger: "POST /email/send-email from Bloomreach"
participants:
  - "bloomreach"
  - "continuumPushClientProxyService"
  - "continuumPushClientProxyMySqlUsersDb"
  - "continuumPushClientProxyPostgresExclusionsDb"
  - "continuumPushClientProxyRedisPrimary"
  - "smtpRelay"
  - "influxDb"
architecture_ref: "dynamic-email-request-flow"
---

# Email Send Request

## Summary

Bloomreach POSTs an email message to `POST /email/send-email`. push-client-proxy applies rate limiting, user account validation, and denylist checks before injecting the email into the SMTP relay. The service returns a synchronous response to Bloomreach and emits request metrics to InfluxDB. Email metadata is stored in Redis to enable later delivery-status correlation.

## Trigger

- **Type**: api-call
- **Source**: Bloomreach (external email platform)
- **Frequency**: Per-request (on-demand for each email send)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Bloomreach | Caller — sends email message payload | `bloomreach` |
| push-client-proxy service | Orchestrator — validates, routes, and responds | `continuumPushClientProxyService` |
| Users lookup database | Validator — confirms user account exists | `continuumPushClientProxyMySqlUsersDb` |
| Rocketman exclusions database | Validator — checks recipient denylist | `continuumPushClientProxyPostgresExclusionsDb` |
| Primary Redis cache | Cache — stores email metadata; backs rate limiter | `continuumPushClientProxyRedisPrimary` |
| SMTP relay | Delivery — receives injected email | `smtpRelay` |
| InfluxDB | Observability — receives request metrics | `influxDb` |

## Steps

1. **Receives email send request**: Bloomreach sends `POST /email/send-email` with an `EmailMessage` JSON body including `requestId`, `userId`, `to`, `from`, `subject`, and optional `customHeaders`.
   - From: `bloomreach`
   - To: `continuumPushClientProxyService` (`pcpEmailApiController`)
   - Protocol: HTTPS

2. **Resolves userId from custom headers**: If `userId` is missing from the body, the controller attempts to extract it from `customHeaders` using the `USER_ID_HEADER` constant.
   - From: `pcpEmailApiController`
   - To: (internal)
   - Protocol: direct

3. **Checks rate limit**: Calls `RateLimiterService.checkEmailSendRateLimit()` which consults a Bucket4j token bucket backed by primary Redis. If the limit is exceeded, returns `HTTP 429` with `X-Rate-Limit-Retry-After-Seconds` header immediately.
   - From: `pcpEmailApiController`
   - To: `continuumPushClientProxyRedisPrimary` (via `pcpRateLimiterService`)
   - Protocol: Redis

4. **Validates user account existence**: Calls `UserAccountService.doesUserAccountExist(userId)` which queries the MySQL users lookup database. If no account is found, returns `HTTP 200` and emits a `user_account_not_exists` drop metric.
   - From: `pcpUserAccountService`
   - To: `continuumPushClientProxyMySqlUsersDb`
   - Protocol: JPA/JDBC

5. **Checks exclusion denylist**: Calls `EmailExclusionService.isEmailExcluded(emailAddress)` which queries the exclusions PostgreSQL database for exact or wildcard matches on the recipient address. If excluded, returns `HTTP 200` and emits a `denylist` drop metric.
   - From: `pcpEmailExclusionService`
   - To: `continuumPushClientProxyPostgresExclusionsDb`
   - Protocol: JPA/JDBC

6. **Stores email metadata in Redis**: `EmailInjectorService` stores `from`, `to`, `customData`, and `requestId` in primary Redis keyed by `userId`+`sendId` to enable later delivery-status callback correlation.
   - From: `pcpEmailInjectorService`
   - To: `continuumPushClientProxyRedisPrimary` (via `pcpRedisUtil`)
   - Protocol: Redis

7. **Injects email via SMTP**: `EmailInjectorService` resolves the appropriate `DefaultMailSender` by sender routing key and calls `mailSender.sendMessage(mimeMessage)`.
   - From: `pcpEmailInjectorService`
   - To: `smtpRelay`
   - Protocol: SMTP

8. **Emits request metrics**: `MetricsProvider` records `email.send.request.duration` (timer) and `NEW_EMAIL_SEND_REQUEST_COUNT` (counter) with `status_code=2xx` and `endpoint=send-email` tags.
   - From: `pcpMetricsProvider`
   - To: `influxDb`
   - Protocol: HTTP

9. **Returns success response**: Returns `HTTP 200` with `EmailResponse` JSON body (containing `requestId`) and `X-Rate-Limit-Remaining` header.
   - From: `continuumPushClientProxyService`
   - To: `bloomreach`
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Rate limit exceeded | Return `HTTP 429` with `X-Rate-Limit-Retry-After-Seconds` header; emit `rate_limit` drop metric | Bloomreach retries after the specified delay |
| User account not found in MySQL | Return `HTTP 200` (silent drop); emit `user_account_not_exists` drop metric | Email not sent; Bloomreach receives success signal |
| Recipient on exclusion denylist | Return `HTTP 200` (silent drop); emit `denylist` drop metric | Email not sent; Bloomreach receives success signal |
| SMTP send failure (`EmailSendingException`) | Return `HTTP 400` with `EmailResponse`; emit `4xx` metric | Bloomreach retries |
| Unexpected exception | Return `HTTP 500` with `EmailResponse`; emit `5xx` metric | Bloomreach retries |
| Exclusion check failure | Exception is caught; processing continues to send | Email is sent despite exclusion check failure |

## Sequence Diagram

```
Bloomreach -> EmailController: POST /email/send-email {EmailMessage}
EmailController -> RateLimiterService: checkEmailSendRateLimit()
RateLimiterService -> Redis: token bucket consume
Redis --> RateLimiterService: allowed / denied
RateLimiterService --> EmailController: RateLimitResult
EmailController -> UserAccountService: doesUserAccountExist(userId)
UserAccountService -> MySQLUsersDb: SELECT user by userId
MySQLUsersDb --> UserAccountService: exists / not found
UserAccountService --> EmailController: boolean
EmailController -> EmailExclusionService: isEmailExcluded(emailAddress)
EmailExclusionService -> PostgresExclusionsDb: SELECT exclusion by address
PostgresExclusionsDb --> EmailExclusionService: match / no match
EmailExclusionService --> EmailController: boolean
EmailController -> EmailInjectorService: sendEmail(emailMessage)
EmailInjectorService -> Redis: store email metadata (userId+sendId key)
EmailInjectorService -> SmtpRelay: sendMessage(mimeMessage)
SmtpRelay --> EmailInjectorService: sent
EmailInjectorService --> EmailController: success
EmailController -> MetricsProvider: timer + counter (2xx)
MetricsProvider -> InfluxDB: write metrics
EmailController --> Bloomreach: 200 OK {EmailResponse}
```

## Related

- Architecture dynamic view: `dynamic-email-request-flow`
- Related flows: [Delivery Status Callback](delivery-status-callback.md), [Async Email Send](async-email-send.md)
