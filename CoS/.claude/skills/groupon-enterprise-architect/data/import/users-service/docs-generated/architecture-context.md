---
service: "users-service"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumUsersService"
    - "continuumUsersResqueWorkers"
    - "continuumUsersMessageBusConsumer"
    - "continuumUsersDb"
    - "continuumUsersRedis"
    - "continuumUsersMessageBusBroker"
    - "continuumUsersMailService"
    - "continuumUsersIdentityService"
    - "continuumUsersRocketman"
    - "continuumUsersMetricsStore"
    - "continuumUsersFacebookGraphApi"
    - "continuumUsersAppleIdentityApi"
---

# Architecture Context

## System Context

Users Service sits within the Continuum platform (`continuumSystem`) and is the sole authority for Groupon user identity. Web and mobile consumers interact directly with the Users Service API over HTTPS. The service delegates social identity verification to Google OAuth, Facebook Graph API, and Apple Identity API; delivers OTP codes through Rocketman; sends transactional email through Mailman; and publishes account lifecycle events to the GBus/ActiveMQ Message Bus Broker for consumption by downstream Continuum services.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| Users Service API | `continuumUsersService` | Backend API | Ruby 2.7, Sinatra, ActiveRecord | Sinatra HTTP API serving account lifecycle, authentication, and identity endpoints |
| Users Resque Workers | `continuumUsersResqueWorkers` | Background worker | Ruby, Resque | Async worker pool for message bus publishing, notifications, and batch remediation |
| Users Message Bus Consumer | `continuumUsersMessageBusConsumer` | Event consumer | Ruby, GBus, Rake | GBus/STOMP consumer processing identity and account topics |
| Users DB | `continuumUsersDb` | Database | MySQL 5.6 | Primary relational store for accounts, authentication events, and audit data |
| Users Redis | `continuumUsersRedis` | Cache / Queue | Redis 6 | Resque queue backing store, cache, and lightweight feature flags |
| Message Bus Broker | `continuumUsersMessageBusBroker` | Message broker | ActiveMQ, GBus | GBus/STOMP broker for account and identity event topics |
| Mail Delivery Service | `continuumUsersMailService` | External integration | SMTP, Mailman | Transactional email pipeline for verification, reset, and notification emails |
| Identity Service | `continuumUsersIdentityService` | Internal service | HTTP/JSON | External identity provider for authoritative account creation and validation |
| Rocketman Commercial Service | `continuumUsersRocketman` | Internal service | HTTP/JSON | OTP delivery for multi-factor authentication |
| Metrics Store | `continuumUsersMetricsStore` | Observability | InfluxDB, Sonoma | Metrics sink for application and job telemetry |
| Facebook Graph API | `continuumUsersFacebookGraphApi` | External | HTTPS API | Facebook identity token validation and profile lookup |
| Apple Identity API | `continuumUsersAppleIdentityApi` | External | HTTPS API | Apple Sign In token exchange and key discovery |

## Components by Container

### Users Service API (`continuumUsersService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Accounts Controller | REST endpoints for account CRUD, 2FA enrollment, and GDPR erasure | Sinatra |
| Authentication Controller | Authenticates via password, OTP, Apple/Google/Facebook/OIDC; issues tokens | Sinatra |
| Email Verifications Controller | Initiates and completes email verification using nonce workflows | Sinatra |
| Password Resets Controller | Initiates and completes password reset flows with email and locale handling | Sinatra |
| Third-Party Account Links Controller | Manages linking and unlinking of external identities | Sinatra |
| Account Strategies | Service objects for account creation, registration, updates, and legacy fallbacks | Ruby |
| Authentication Strategies | Password, nonce, OTP, Okta SAML, Apple, Facebook, and Google auth flows | Ruby |
| Token Service | Builds and validates JWT-style session, continuation, and 2FA tokens | Ruby |
| Account & Auth Event Publishers | Formats account lifecycle and authentication events for message bus | GBus payloads |
| Async Message Bus Publisher | Persists outbound message payloads and enqueues Resque jobs | Resque, Redis |
| Identity Service Client | HTTP client for account creation and validation against Identity Service | HTTP/JSON |
| Rocketman OTP Client | Sends OTP delivery requests for MFA via Rocketman | HTTP/JSON |
| App Mailer | Delivers transactional emails via Mailman | Mailman |
| Kafka Log Publisher | Writes auth and lookup events to Kafka-aligned log files | File logger |
| Account Repository | ActiveRecord models for accounts, passwords, tokens, and audit entities | ActiveRecord |
| Cache Client | Redis-backed cache and feature flags used across controllers and strategies | Redis |

### Users Resque Workers (`continuumUsersResqueWorkers`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Resque Pool Runner | Manages worker pool and queue assignments from resque-pool.yml | Resque |
| Message Bus Resque Job | Reads pending MessageBusMessage records and publishes to broker with retry/backoff | Ruby |
| Message Bus Publisher | GBus producer sending account/auth events to JMS topics | GBus/STOMP |
| Forced Password Reset Job | Processes compromised password batches and updates account records | Ruby |
| Device Email Notification Job | Detects new device authentications and triggers notification emails | Ruby |
| Sleeper Account Resurrection Job | Audits and reactivates dormant accounts | Ruby |
| UDS Resque Job | UDS fan-out for account registration events | Ruby |
| Worker Mailer | Sends emails for password reset, device notifications, and other jobs | Mailman |
| Worker Repository | ActiveRecord access to accounts, auth events, and message bus messages | ActiveRecord |

### Users Message Bus Consumer (`continuumUsersMessageBusConsumer`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Message Bus Consumer Runner | Bootstraps GBus subscriptions defined in messagebus.yml | GBus/STOMP |
| Message Handler Base | Shared normalization, logging, and error handling for message bus workers | Ruby |
| Forced Password Reset Handler | Processes suspicious behavior events to invalidate tokens and notify users | Ruby |
| Dog Food Event Handler | Marks published MessageBusMessage records as consumed and records timing metrics | Ruby |
| Message Bus Mailer | Sends forced password reset notifications from consumed events | Mailman |
| Account Repository (Consumer) | ActiveRecord access for accounts and message bus message records | ActiveRecord |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumUsersService` | `continuumUsersDb` | Reads and writes accounts, auth events, and audit data | MySQL / ActiveRecord |
| `continuumUsersService` | `continuumUsersRedis` | Resque queues, cache, and feature flags | Redis |
| `continuumUsersService` | `continuumUsersResqueWorkers` | Enqueues background jobs for publishing and notifications | Resque |
| `continuumUsersService` | `continuumUsersIdentityService` | Creates and validates accounts via external identity APIs | HTTP/JSON |
| `continuumUsersService` | `continuumUsersRocketman` | Requests OTP delivery for MFA | HTTP/JSON |
| `continuumUsersService` | `continuumUsersMailService` | Sends verification, reset, and device emails | SMTP/Mailman |
| `continuumUsersService` | `googleOAuth` | Validates Google identity tokens during social login | HTTPS |
| `continuumUsersService` | `continuumUsersFacebookGraphApi` | Validates Facebook tokens and retrieves profile | HTTPS |
| `continuumUsersService` | `continuumUsersAppleIdentityApi` | Exchanges Apple OAuth codes for ID tokens | HTTPS |
| `continuumUsersResqueWorkers` | `continuumUsersMessageBusBroker` | Publishes account and identity events to JMS topics | GBus/STOMP |
| `continuumUsersResqueWorkers` | `continuumUsersDb` | Reads and writes account data and message bus records | ActiveRecord |
| `continuumUsersResqueWorkers` | `continuumUsersRedis` | Consumes jobs from Redis-backed Resque queues | Resque/Redis |
| `continuumUsersResqueWorkers` | `continuumUsersMailService` | Delivers emails triggered by background jobs | SMTP/Mailman |
| `continuumUsersMessageBusConsumer` | `continuumUsersMessageBusBroker` | Consumes identity/account topics | GBus/STOMP |
| `continuumUsersMessageBusConsumer` | `continuumUsersDb` | Updates account and message records from consumed events | ActiveRecord |
| `continuumUsersMessageBusConsumer` | `continuumUsersMailService` | Sends forced password reset notifications | SMTP/Mailman |

## Architecture Diagram References

- System context: `contexts-users-service`
- Container: `containers-users-service`
- Component (API): `components-continuumUsersService`
- Component (Workers): `components-continuumUsersResqueWorkers`
- Component (Consumer): `components-continuumUsersMessageBusConsumer`
- Dynamic (Authentication): `dynamic-users-continuumUsersServiceApi_tokenService-authentication-flow`
