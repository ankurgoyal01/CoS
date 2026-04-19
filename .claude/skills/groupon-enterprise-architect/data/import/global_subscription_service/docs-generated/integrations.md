---
service: "global_subscription_service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 4
---

# Integrations

## Overview

The Global Subscription Service maintains seven downstream integrations: four via HTTP (Retrofit/OkHttp), two via async messaging (MBus and Kafka), and one via Cassandra client. Internal Groupon services are called for user identity resolution and regulatory consent synchronization. Three external-pattern services — Rocketman SMS, EDS (email delivery), and Geo Services — are referenced in the architecture model as stub-only (not yet federated). The service is a declared dependency in the service portal of `rocketman`, `users-service`, and `regulatory-consent-log`.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Rocketman SMS Service | REST | Sends SMS messages after consent is granted | yes | `rocketmanSmsService_unknown_1a2b` (stub) |
| EDS (Email Delivery Service) | REST | Sends email messages after email subscription is created | yes | `edsService_unknown_4c1d` (stub) |
| Geo Services | REST | Resolves geographic divisions and locales for subscription list scoping | no | `geoServices_unknown_9a2c` (stub) |

### Rocketman SMS Service Detail

- **Protocol**: REST / HTTP
- **Base URL / SDK**: Configured via `rm_service` key in JTier run config (`RetrofitConfiguration`)
- **Auth**: Internal service authentication (JTier mTLS or internal network)
- **Purpose**: Sends SMS messages triggered by subscription events; not called directly by consent APIs — delegates via event publish
- **Failure mode**: Subscription event is published to MBus; Rocketman consumes asynchronously — direct failure impact is limited
- **Circuit breaker**: Managed by JTier OkHttp client configuration

### EDS (Email Delivery Service) Detail

- **Protocol**: REST / HTTP
- **Base URL / SDK**: Configured via `eds_service` key in JTier run config (`RetrofitConfiguration`)
- **Auth**: Internal service authentication
- **Purpose**: Sends confirmation or notification emails for subscription state changes
- **Failure mode**: Subscription event published to MBus; EDS consumes asynchronously
- **Circuit breaker**: Managed by JTier OkHttp client configuration

### Geo Services Detail

- **Protocol**: REST / HTTP
- **Base URL / SDK**: Configured via `geoServicesClientConfiguration` key in JTier run config (`RetrofitConfiguration`)
- **Auth**: Internal service authentication
- **Purpose**: Resolves division UUIDs and locale information for push subscription and email list scoping
- **Failure mode**: Division fill endpoint may return empty; subscription creation may fail for unresolvable locales
- **Circuit breaker**: Managed by JTier OkHttp client configuration

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| User Service (`continuumUserService`) | REST | Fetches consumer account data and resolves consumer UUID for consent operations | `continuumUserService` |
| Consent Service (`continuumConsentService`) | REST | Synchronizes regulatory consent information and propagates consent decisions | `continuumConsentService` |
| MBus | MBus protocol | Publishes subscription and GDPR events; consumes traveller, auto-sub, location-sub, RTF, and data migration events | `messageBus` |
| Kafka cluster | Kafka TLS | Publishes push token create/update events; consumes push token system (PTS) events | `kafkaCluster_unknown_2f91` (stub) |

### User Service Detail

- **Protocol**: REST / HTTP via Retrofit
- **Base URL / SDK**: Configured via `user_service` key in JTier run config
- **Auth**: Internal mTLS / JTier
- **Purpose**: Resolves consumer identity (UUID) from session or browser cookie; validates consumer existence before consent write
- **Failure mode**: Consent creation fails with 404 if user cannot be resolved
- **Circuit breaker**: JTier OkHttp timeout and retry settings

### Consent Service Detail

- **Protocol**: REST / HTTP via Retrofit
- **Base URL / SDK**: Configured via `consent_service` key in JTier run config
- **Auth**: Internal mTLS / JTier
- **Purpose**: Synchronizes consent decisions with the regulatory consent log (regulatory-consent-log service) for GDPR compliance audit trail
- **Failure mode**: Consent is recorded locally; regulatory sync failure is logged for retry
- **Circuit breaker**: JTier OkHttp timeout and retry settings

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known callers based on service portal dependencies and README references:

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Rocketman (SMS sending platform) | REST | Checks SMS consent before sending messages |
| Mobile apps / web frontend | REST | Manages consumer notification preferences |
| Internal marketing systems | REST | Reads subscription list state for campaign targeting |
| Regulatory consent log service | MBus | Receives consent change events for audit compliance |

## Dependency Health

JTier OkHttp clients use configurable timeouts and retry policies via `RetrofitConfiguration`. MBus consumer health is toggled via the `messageBusConsumersEnabled` configuration property. The service exposes `/grpn/healthcheck` for Kubernetes probes but does not expose a structured dependency health endpoint. Kafka connectivity requires TLS setup executed via `kafka-tls-v2.sh` at container startup.
