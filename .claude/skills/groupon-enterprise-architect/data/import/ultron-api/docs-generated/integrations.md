---
service: "ultron-api"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 1
internal_count: 2
---

# Integrations

## Overview

ultron-api has three downstream dependencies: two owned relational databases and one external SMTP email service. The SMTP dependency is stub-only in the federated model. The service is consumed by job runner clients that call its HTTP API to register runs. All database access is mediated by the Slick-based Repository Layer component.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| SMTP Email Service | SMTP | Sends watchdog alert emails when jobs are overdue | no | `smtpEmailService_2d1e` |

### SMTP Email Service Detail

- **Protocol**: SMTP
- **Base URL / SDK**: Standard Java Mail / SMTP client — evidence from `emailManager` component in `architecture/models/components/ultronApi.dsl`
- **Auth**: SMTP credentials (host, port, user, password — stored as secrets)
- **Purpose**: Composes and delivers watchdog alert emails to job owners and on-call stakeholders when scheduled jobs fail to run within their expected intervals
- **Failure mode**: Alert email not delivered; watchdog state is still recorded in `continuumUltronDatabase`
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Ultron Database | JDBC / Slick | Reads and writes all job orchestration metadata | `continuumUltronDatabase` |
| Quartz Scheduler DB | JDBC | Persists Quartz scheduler trigger and execution state | `continuumQuartzSchedulerDb` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Job Runner Clients (`jobRunnerClients_4c7b`) | HTTP/REST | Register job runs and watermarks via the Ultron API |

> `jobRunnerClients_4c7b` is a stub-only reference in the federated model. The exact set of upstream job runner clients is tracked in the central architecture model.

## Dependency Health

> No evidence found in codebase for explicit circuit breaker or retry configurations. Database connectivity failures will surface as Slick/JDBC exceptions. SMTP failures are handled within the `emailManager` component. Operational procedures to be defined by service owner.

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumUltronDatabase` | Play evolutions endpoint (`/evolutions`) and service health check | Service unavailable; all API operations fail |
| `continuumQuartzSchedulerDb` | Quartz startup connectivity check | Scheduler fails to start; watchdog jobs do not fire |
| `smtpEmailService_2d1e` | No explicit health check evident | Watchdog alert not sent; state recorded but no notification |
