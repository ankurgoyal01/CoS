---
service: "calcom"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 1
---

# Integrations

## Overview

Calcom has one external integration (Gmail SMTP for transactional email) and one internal integration (the Cal.com Worker Service via an internal job queue). Both the primary web/API container and the worker container send emails via Gmail SMTP. The Groupon deployment does not expose integration points into other Groupon Continuum microservices; it operates as a self-contained scheduling platform.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Gmail SMTP (`smtp.gmail.com`) | SMTP/TLS | Sends scheduling confirmations, reminders, and transactional notifications | yes | `gmailSmtpService` |

### Gmail SMTP Detail

- **Protocol**: SMTP over TLS
- **Base URL / SDK**: `smtp.gmail.com` port `465`
- **Auth**: Credentials stored in the secrets repository (`calcom-secrets`); referenced via Kubernetes secrets
- **Purpose**: Delivers booking confirmation emails from `calcom@groupon.com` (production) and `calcomstaging@groupon.com` (staging) to meeting attendees and organizers. Both `continuumCalcomService` (confirmation emails) and `continuumCalcomWorkerService` (reminder and follow-up emails) use this integration.
- **Failure mode**: Email delivery failures would cause booking confirmations and reminders to not be received; the booking itself remains persisted in the database.
- **Circuit breaker**: No evidence found in codebase.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Cal.com Worker Service | Internal job queue (PostgreSQL-backed) | Offloads asynchronous scheduling and reminder workflows | `continuumCalcomWorkerService` |
| Cal.com PostgreSQL | PostgreSQL | Primary data store for all scheduling and account data | `continuumCalcomPostgres` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| `calcomClientBrowser` | HTTPS | End users schedule and manage meetings via the public booking interface at `https://meet.groupon.com` |
| `calcomAdminBrowser` | HTTPS | Administrators configure service settings and manage users via the admin panel |

> Upstream consumers are tracked in the central architecture model. The `calcomClientBrowser` and `calcomAdminBrowser` stubs are defined in `architecture/stubs.dsl` as they are not part of the federated model.

## Dependency Health

- **Gmail SMTP**: No dedicated health check configured at the Groupon deployment layer. SMTP connectivity issues would surface in application logs as email delivery errors.
- **PostgreSQL**: Kubernetes readiness and liveness probes on port `3000` (path `/`) validate application startup, which implicitly depends on database connectivity. The GDS team monitors and alerts on database availability.
- **Retry / circuit breaker**: No evidence of custom retry or circuit breaker logic in the Groupon wrapper layer. Behavior is inherited from the upstream Cal.com application.
