---
service: "users-service"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Identity / User Accounts"
platform: "Continuum"
team: "Users Team (dredmond)"
status: active
tech_stack:
  language: "Ruby"
  language_version: "2.7.5"
  framework: "Sinatra"
  framework_version: ""
  runtime: "Puma"
  runtime_version: "5.x"
  build_tool: "Bundler"
  package_manager: "Bundler / RubyGems"
---

# Users Service Overview

## Purpose

Users Service is the authoritative system for user account lifecycle, authentication, and identity management within the Groupon Continuum platform. It provides REST APIs for account creation and management, credential-based and social authentication, email verification, password reset, and third-party identity linking. The service enforces security policies including 2FA, GDPR erasure, and compromised-credential remediation.

## Scope

### In scope

- Account creation, registration, lookup, update, and deactivation
- Credential authentication: password, OTP/2FA, nonce-based continuation tokens
- Social login via Google, Facebook, and Apple OAuth
- Email verification workflows
- Password reset (self-service and forced/batch)
- Third-party account linking and unlinking
- GDPR erasure requests (`/erasure` endpoint)
- Account event publishing (`account.created`, `account.registered`, `account.deactivated`, `account.reactivated`, `authentication.completed`, `email_verification.completed`)
- Consuming security signals (`bemod.suspiciousBehavior`) to trigger forced password resets
- Device notification emails for new device authentications
- Sleeper account resurrection

### Out of scope

- Authorization / permission checks (handled by downstream services)
- Order or commerce data
- Session management beyond token issuance
- Identity provider administration (delegated to Identity Service)

## Domain Context

- **Business domain**: Identity / User Accounts
- **Platform**: Continuum
- **Upstream consumers**: Web and mobile clients (consumers), internal Continuum services via Message Bus
- **Downstream dependencies**: Identity Service, Rocketman (OTP), Mailman (email), Google OAuth, Facebook Graph API, Apple Identity API, Message Bus Broker (GBus/ActiveMQ)

## Stakeholders

| Role | Description |
|------|-------------|
| Users Team (dredmond) | Service owner; responsible for development, operations, and on-call |
| Security / Trust & Safety | Consumes security events; triggers forced password resets via `bemod.suspiciousBehavior` |
| Continuum Platform | Downstream services consuming account lifecycle events from Message Bus |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 2.7.5 | Gemfile / .ruby-version |
| Framework | Sinatra | — | Gemfile (`sinatra`) |
| App server | Puma | 5.x | Gemfile (`puma ~> 5`) |
| ORM | ActiveRecord | 6.0.3.5 | Gemfile (`activerecord 6.0.3.5`) |
| Build tool | Bundler | — | Gemfile.lock |
| Package manager | RubyGems / Bundler | — | Gemfile |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| activerecord | 6.0.3.5 | orm | MySQL persistence; account, auth, and event models |
| mysql2 | 0.5.3 | db-client | MySQL database adapter |
| redis | 4.7.1 | db-client | Resque queue backing store and cache |
| resque | 2.4.0 | scheduling | Background job processing (message bus publishing, notifications, batch jobs) |
| messagebus | 0.3.6 | message-client | Internal message bus client for event publishing |
| g-bus | 0.0.1 | message-client | GBus/STOMP producer and consumer for JMS topics |
| jwt | 2.2.1 | auth | JWT token creation and validation for sessions and continuation tokens |
| bcrypt | — | auth | Password hashing |
| attr_encrypted | 3.1.0 | auth | Attribute-level encryption for sensitive fields |
| elastic-apm | — | logging | Distributed tracing via Elastic APM |
| sonoma-metrics | — | metrics | Application metrics emission to InfluxDB |
| puma | 5.x | http-framework | Multi-threaded HTTP app server |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
