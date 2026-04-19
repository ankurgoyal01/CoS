---
service: "users-service"
title: "Authentication Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "authentication"
flow_type: synchronous
trigger: "POST /v1/authentication"
participants:
  - "consumer"
  - "continuumUsersService"
  - "googleOAuth"
  - "continuumUsersFacebookGraphApi"
  - "continuumUsersAppleIdentityApi"
  - "continuumUsersIdentityService"
  - "continuumUsersRocketman"
  - "continuumUsersDb"
  - "continuumUsersRedis"
  - "continuumUsersResqueWorkers"
  - "continuumUsersMessageBusBroker"
  - "continuumUsersMailService"
architecture_ref: "dynamic-users-continuumUsersServiceApi_tokenService-authentication-flow"
---

# Authentication Flow

## Summary

The authentication flow handles credential validation and session token issuance via `POST /v1/authentication`. The Authentication Controller selects the appropriate strategy (password, OTP, Google, Facebook, or Apple OAuth) based on the request payload, validates credentials against external providers or local state, persists the authentication event to MySQL, issues a JWT-style session token, and asynchronously publishes an `authentication.completed` event. This is the highest-traffic flow in the service and the primary entry point for Groupon consumers.

## Trigger

- **Type**: api-call
- **Source**: Web or mobile client submitting login credentials or OAuth tokens
- **Frequency**: On-demand per login attempt

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (client) | Submits credentials or OAuth token | `consumer` |
| Users Service API | Receives request; delegates to Authentication Strategies | `continuumUsersService` |
| Google OAuth | Validates Google identity token (social login path only) | `googleOAuth` |
| Facebook Graph API | Validates Facebook access token (social login path only) | `continuumUsersFacebookGraphApi` |
| Apple Identity API | Exchanges Apple OAuth code for ID token (social login path only) | `continuumUsersAppleIdentityApi` |
| Identity Service | Validates OIDC tokens when Identity Service integration is enabled | `continuumUsersIdentityService` |
| Rocketman Commercial Service | Delivers OTP for 2FA challenge | `continuumUsersRocketman` |
| Users DB | Reads account and auth event data; persists new auth event | `continuumUsersDb` |
| Users Redis | Cache reads; Resque job enqueue | `continuumUsersRedis` |
| Users Resque Workers | Publishes authentication.completed event asynchronously | `continuumUsersResqueWorkers` |
| Message Bus Broker | Receives authentication event | `continuumUsersMessageBusBroker` |
| Mail Delivery Service | Sends device notification email (async, if new device) | `continuumUsersMailService` |

## Steps

1. **Receive authentication request**: Client sends `POST /v1/authentication` with strategy indicator and credentials (password + email, or OAuth token).
   - From: `consumer`
   - To: `continuumUsersService`
   - Protocol: HTTPS / REST

2. **Select authentication strategy**: Authentication Controller identifies the strategy (password, OTP, nonce, Google, Facebook, Apple, Okta SAML) from the request payload and invokes the appropriate Authentication Strategy.
   - From: `continuumUsersServiceApi_authenticationController`
   - To: `continuumUsersServiceApi_authenticationStrategies`
   - Protocol: Ruby (in-process)

3. **Validate credentials against external provider (social login paths)**:
   - Google: Authentication Strategies calls `googleOAuth` to validate the token.
   - Facebook: Authentication Strategies calls `continuumUsersFacebookGraphApi` to validate token and retrieve profile.
   - Apple: Authentication Strategies calls `continuumUsersAppleIdentityApi` to exchange code for ID token.
   - From: `continuumUsersServiceApi_authenticationStrategies`
   - To: `googleOAuth` / `continuumUsersFacebookGraphApi` / `continuumUsersAppleIdentityApi`
   - Protocol: HTTPS

4. **Load account from database**: Authentication Strategies reads the account record from `continuumUsersDb` via Account Repository.
   - From: `continuumUsersServiceApi_authenticationStrategies`
   - To: `continuumUsersDb` (via `continuumUsersServiceApi_repository`)
   - Protocol: MySQL / ActiveRecord

5. **Issue OTP challenge (2FA path, if required)**: For accounts with 2FA enrolled, Authentication Strategies calls Rocketman OTP Client to send an OTP code.
   - From: `continuumUsersServiceApi_authenticationStrategies`
   - To: `continuumUsersRocketman` (via `continuumUsersServiceApi_rocketmanClient`)
   - Protocol: HTTP/JSON

6. **Build session or continuation token**: Token Service creates a JWT-style token for the authenticated session or a continuation token for mid-flow state (e.g., awaiting 2FA).
   - From: `continuumUsersServiceApi_authenticationController`
   - To: `continuumUsersServiceApi_tokenService`
   - Protocol: Ruby (in-process)

7. **Persist authentication event**: Token Service and strategies write auth event and token records to `continuumUsersDb`.
   - From: `continuumUsersServiceApi_tokenService`
   - To: `continuumUsersDb`
   - Protocol: MySQL / ActiveRecord

8. **Queue event publishing**: Account & Auth Event Publishers queues an `authentication.completed` event via the outbox pattern.
   - From: `continuumUsersServiceApi_eventPublishers`
   - To: `continuumUsersDb` (outbox) + `continuumUsersRedis` (Resque)
   - Protocol: ActiveRecord + Redis

9. **Log authentication result**: Kafka Log Publisher writes authentication result to a Kafka-aligned log file.
   - From: `continuumUsersServiceApi_kafkaPublisher`
   - To: log file (file logger)
   - Protocol: File I/O

10. **Return token response**: API returns session token (HTTP 200) or continuation token (HTTP 202 if 2FA pending) to caller.
    - From: `continuumUsersService`
    - To: `consumer`
    - Protocol: HTTPS / REST

11. **Publish authentication.completed event (async)**: Resque worker reads outbox and publishes to Message Bus Broker.
    - From: `continuumUsersResqueWorkers`
    - To: `continuumUsersMessageBusBroker`
    - Protocol: GBus/STOMP

12. **Detect new device and notify (async)**: Device Email Notification Job checks authentication events for new device; sends notification email if detected.
    - From: `continuumUsersResqueWorkers`
    - To: `continuumUsersMailService`
    - Protocol: SMTP/Mailman

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid password | Authentication Strategies returns failure | 401 Unauthorized |
| OAuth provider unreachable | HTTP error from OAuth client | 503 or 401 depending on strategy |
| Account not found | Repository returns nil | 401 Unauthorized (no enumeration) |
| Account locked / deactivated | Strategy checks account status | 403 Forbidden |
| Rocketman OTP delivery fails | HTTP error from Rocketman client | 503; authentication blocked for 2FA path |
| Token build failure | Exception in Token Service | 500; auth event not persisted |
| Resque job failure (event) | Resque retries with backoff | Event delayed; auth succeeds |

## Sequence Diagram

```
Consumer                -> UsersServiceAPI          : POST /v1/authentication
UsersServiceAPI         -> AuthStrategies            : authenticate(strategy, credentials)
AuthStrategies          -> GoogleOAuth               : validate_token [Google path]
AuthStrategies          -> FacebookGraphApi          : validate_token [Facebook path]
AuthStrategies          -> AppleIdentityApi          : exchange_code [Apple path]
AuthStrategies          -> AccountRepository         : find_account(email/external_id)
AccountRepository       --> AuthStrategies           : account record
AuthStrategies          -> RocketmanClient           : send_otp [2FA path]
RocketmanClient         -> Rocketman                 : POST /otp
AuthStrategies          -> TokenService              : build_token(account)
TokenService            -> AccountRepository         : persist token + auth event
EventPublishers         -> AsyncMBPublisher          : queue authentication.completed
AsyncMBPublisher        -> UsersDb                   : INSERT message_bus_messages
AsyncMBPublisher        -> UsersRedis                : RPUSH resque:queue
UsersServiceAPI         --> Consumer                 : 200 OK (session token)
[async]
ResqueWorker            -> MessageBusBroker          : PUBLISH authentication.completed
ResqueWorker            -> MailService               : send device notification [if new device]
```

## Related

- Architecture dynamic view: `dynamic-users-continuumUsersServiceApi_tokenService-authentication-flow`
- Related flows: [Account Creation](account-creation.md), [Password Reset](password-reset.md), [Third-Party Linking](third-party-linking.md), [Device Notification Batch](device-notification-batch.md)
