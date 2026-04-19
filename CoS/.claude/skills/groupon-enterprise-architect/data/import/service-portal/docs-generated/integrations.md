---
service: "service-portal"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 4
internal_count: 0
---

# Integrations

## Overview

Service Portal integrates with four external systems: GitHub Enterprise (primary data source via webhooks and REST API), Google Chat (outbound notifications), Google Directory (team and ownership identity lookups), and Jira Cloud (ORR issue tracking, currently a stub). There are no internal Groupon service-to-service dependencies — Service Portal operates as a standalone governance platform. It is consumed by engineering teams and CI pipelines directly via its REST API.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GitHub Enterprise | REST + webhook | Repository metadata sync and inbound push/PR event processing | yes | `continuumServicePortalWeb` → GitHub Enterprise |
| Google Chat | REST (SDK) | Send governance alerts and ORR notifications to team spaces | no | `continuumServicePortalWorker` → Google Chat |
| Google Directory (Admin SDK) | REST (SDK) | Look up team ownership, group membership, and engineer identity | yes | `continuumServicePortalWorker` → Google Directory |
| Jira Cloud | REST | ORR issue creation and tracking (stub — not fully integrated) | no | `continuumServicePortalWorker` → Jira Cloud |

### GitHub Enterprise Detail

- **Protocol**: HTTPS REST API (outbound, via Faraday 2.0.1); HTTPS webhook (inbound, received at `/processor`)
- **Base URL / SDK**: GitHub Enterprise base URL configured via environment variable; Faraday HTTP client used for outbound calls
- **Auth**: Inbound webhooks authenticated via HMAC-SHA256 signature (`X-Hub-Signature-256`); outbound REST calls authenticated via GitHub personal access token or app token (environment-configured)
- **Purpose**: Receives push and pull_request webhook events to trigger repository metadata sync; fetches repository details, branch protection, CI status, and contributor data via REST API
- **Failure mode**: Inbound webhooks failing HMAC verification are rejected (HTTP 401). Outbound GitHub API failures cause Sidekiq job failure; Sidekiq retries with exponential backoff. Extended outages result in stale repository metadata in `continuumServicePortalDb`
- **Circuit breaker**: No evidence of a circuit breaker; Sidekiq retry exhaustion is the fallback

### Google Chat Detail

- **Protocol**: HTTPS REST via `google-apis-chat_v1` SDK
- **Base URL / SDK**: `google-apis-chat_v1` gem; credentials configured via environment variables
- **Auth**: Google service account credentials (environment-configured)
- **Purpose**: Sends notifications to team Google Chat spaces when governance checks fail, cost thresholds are exceeded, or ORR milestones occur
- **Failure mode**: Notification failures are non-critical; failed Sidekiq notification jobs are retried. Governance logic continues regardless of notification delivery
- **Circuit breaker**: No evidence of a circuit breaker

### Google Directory (Admin Directory API) Detail

- **Protocol**: HTTPS REST via `google-apis-admin_directory_v1` SDK
- **Base URL / SDK**: `google-apis-admin_directory_v1` gem; credentials configured via environment variables
- **Auth**: Google service account credentials with domain-wide delegation
- **Purpose**: Resolves team ownership of services by looking up Google Group membership; used during service registration and governance checks
- **Failure mode**: Ownership lookup failures may cause check results to be incomplete; Sidekiq retry on worker failure
- **Circuit breaker**: No evidence of a circuit breaker

### Jira Cloud Detail

- **Protocol**: HTTPS REST via Faraday
- **Base URL / SDK**: Jira Cloud REST API; base URL and credentials environment-configured
- **Auth**: Jira API token (environment-configured)
- **Purpose**: Creates and tracks Jira issues for Operational Readiness Review workflows (currently a stub — integration not fully implemented)
- **Failure mode**: Stub status means failures have minimal impact; ORR workflows may fall back to manual tracking
- **Circuit breaker**: No evidence of a circuit breaker

## Internal Dependencies

> Not applicable. Service Portal has no internal Groupon service-to-service dependencies. It consumes only external SaaS and infrastructure systems.

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known consumers include engineering teams accessing the service catalog UI and API, and CI pipelines using the `/validation/service.yml/validate` endpoint.

## Dependency Health

- GitHub Enterprise is the most critical dependency; unavailability causes webhook processing failures and stale sync state. Sidekiq retry provides resilience for transient outages.
- Google Directory unavailability may cause incomplete ownership data in governance checks.
- Google Chat and Jira Cloud are non-critical; their unavailability does not affect core catalog functionality.
- No centralized health-check or circuit-breaker framework is in evidence. Faraday timeouts and Sidekiq retry are the primary resilience mechanisms.
