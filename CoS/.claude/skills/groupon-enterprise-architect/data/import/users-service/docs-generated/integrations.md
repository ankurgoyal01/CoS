---
service: "users-service"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 4
internal_count: 5
---

# Integrations

## Overview

Users Service integrates with four external identity providers (Google OAuth, Facebook Graph API, Apple Identity API, and an internal Identity Service) and five internal Continuum platform dependencies (Rocketman for OTP, Mailman for email, GBus/ActiveMQ Message Bus Broker, Resque/Redis for async jobs, and the observability stack). External OAuth providers are called synchronously during authentication. All event publishing is asynchronous through the Resque/GBus pipeline.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google OAuth | HTTPS | Validates and exchanges Google identity tokens during social login | yes | `googleOAuth` |
| Facebook Graph API | HTTPS | Retrieves Facebook identity attributes and validates tokens | yes | `continuumUsersFacebookGraphApi` |
| Apple Identity API | HTTPS | Fetches Apple keys and exchanges OAuth codes for ID tokens | yes | `continuumUsersAppleIdentityApi` |
| Identity Service | HTTP/JSON | Authoritative account creation and validation; OIDC/token exchange | yes | `continuumUsersIdentityService` |

### Google OAuth Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: Google token validation endpoint (standard Google OAuth v2)
- **Auth**: OAuth 2.0 bearer token passed from client
- **Purpose**: Validates Google identity tokens submitted during `POST /v1/authentication`; used to resolve or create a linked account
- **Failure mode**: Social login via Google is unavailable; password/OTP auth paths remain functional
- **Circuit breaker**: No evidence found

### Facebook Graph API Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: Facebook Graph API (`graph.facebook.com`)
- **Auth**: Facebook access token passed from client
- **Purpose**: Validates Facebook tokens and retrieves profile attributes during social login
- **Failure mode**: Social login via Facebook is unavailable; other auth paths remain functional
- **Circuit breaker**: No evidence found

### Apple Identity API Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: Apple identity endpoints (`appleid.apple.com`)
- **Auth**: Apple OAuth code exchange; Apple JWK key discovery
- **Purpose**: Exchanges Apple OAuth authorization codes for ID tokens and validates Sign in with Apple flows
- **Failure mode**: Sign in with Apple is unavailable; other auth paths remain functional
- **Circuit breaker**: No evidence found

### Identity Service Detail

- **Protocol**: HTTP/JSON
- **Base URL / SDK**: Internal service endpoint (configured via environment variable)
- **Auth**: Service-to-service credential
- **Purpose**: Used by Account Strategies and Authentication Strategies for authoritative account operations and token validation when Identity Service integration is enabled
- **Failure mode**: Account creation and certain validation flows degrade; fallback to local account handling may apply
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Rocketman Commercial Service | HTTP/JSON | OTP delivery for multi-factor authentication | `continuumUsersRocketman` |
| Mail Delivery Service (Mailman) | SMTP/Mailman | Transactional email delivery | `continuumUsersMailService` |
| Message Bus Broker (GBus/ActiveMQ) | GBus/STOMP | Account and identity event publishing and consumption | `continuumUsersMessageBusBroker` |
| Users Redis | Redis | Resque queue backing store, cache, feature flags | `continuumUsersRedis` |
| Metrics Store (Sonoma/InfluxDB) | Sonoma/InfluxDB | Application, request, and job metrics emission | `continuumUsersMetricsStore` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known consumers include:

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Web and mobile clients (consumer) | HTTPS | Account management, authentication, and identity operations |
| Internal Continuum services | Message Bus (GBus) | Consume account lifecycle and authentication events |

## Dependency Health

- **Identity Service**: Called synchronously during account creation and authentication. No circuit breaker configuration discoverable; failures likely result in HTTP 5xx responses to callers.
- **Google / Facebook / Apple OAuth**: Called synchronously during social login. Failures in individual providers do not affect other authentication strategies.
- **Rocketman**: Called synchronously when OTP delivery is required for MFA. Failure blocks MFA completion.
- **Mailman**: Called for transactional emails. Some calls are synchronous (direct controller invocation); others are dispatched through Resque workers. Worker failures result in Resque retry with backoff.
- **Message Bus Broker**: Event publishing is fully asynchronous via the outbox pattern (MySQL + Resque). Broker unavailability causes job retry; the service continues to serve HTTP traffic.
- **Redis**: Resque queue backing store. Unavailability prevents background job processing but does not immediately impact synchronous API responses.
