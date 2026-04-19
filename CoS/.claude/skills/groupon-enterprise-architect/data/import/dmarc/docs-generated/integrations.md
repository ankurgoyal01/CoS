---
service: "dmarc"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 0
---

# Integrations

## Overview

The DMARC service has two external dependencies and no internal Continuum service dependencies. It calls the Google Gmail API to source DMARC RUA report emails, and it ships its output to Elastic/ELK via the Filebeat log-shipping sidecar. All integration with Gmail is outbound HTTPS using OAuth2; the ELK integration is file-based via a co-deployed Filebeat container.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google Gmail API | HTTPS / OAuth2 | Fetch unread DMARC RUA email messages and their XML attachments from `svc_dmarc@groupon.com` | yes | `unknownGmailApi_9d0a8f3b` (stub) |
| Elastic Logging (ELK) | Filebeat / HTTPS | Receive structured JSON log records from the application log file and index them in Elasticsearch | yes | `unknownElasticLogging_1c2b3d4e` (stub) |

### Google Gmail API Detail

- **Protocol**: HTTPS (REST)
- **Base URL / SDK**: `google.golang.org/api v0.169.0` (`google.golang.org/api/gmail/v1`)
- **Auth**: OAuth2 with offline refresh token; credentials stored at `credentials/credentials.json`, token at `token/token.json` (mounted from secrets volume); scope `gmail.MailGoogleComScope`
- **Purpose**: Lists unread messages matching the configured query (`label: rua is:unread`), fetches full message payloads, retrieves gzip/zip attachments, and removes the UNREAD label from processed messages
- **Failure mode**: Fatal at startup if the client cannot be created. Recoverable per-message errors (HTTP 4xx) are logged and skipped. Pagination errors close the message queue and signal the poller to finish.
- **Circuit breaker**: No evidence found in codebase.

### Elastic Logging (ELK) Detail

- **Protocol**: Filebeat agent reads `/app/logs/dmarc_log.log` and ships to ELK cluster via HTTPS
- **Base URL / SDK**: Filebeat sidecar (configured via `logConfig` in `common.yml`; `sourceType: mta_dmarc`, `isJsonFormat: true`)
- **Auth**: Filebeat sidecar handles ELK authentication (credentials not visible in this repository)
- **Purpose**: Provides long-term storage, search, and dashboarding of parsed DMARC records for email authentication monitoring
- **Dashboard**: `https://logging-us.groupondev.com/goto/a69682a0-eaa1-11ee-873b-8d61e2168108`
- **Failure mode**: Log lines accumulate on disk (lumberjack rotation up to 200 MB × 10 backups) if Filebeat is unavailable; no back-pressure to the DMARC parser.
- **Circuit breaker**: Not applicable (file-based coupling).

## Internal Dependencies

> No evidence found in codebase. The DMARC service does not call any other Continuum or Encore internal service.

## Consumed By

> Upstream consumers are tracked in the central architecture model. No internal service is known to call the DMARC service's HTTP endpoints; the health check endpoint is consumed only by Kubernetes.

## Dependency Health

- Gmail API connectivity is implicitly checked at each poll cycle. Errors are logged; the poller waits for the next tick before retrying.
- ELK/Filebeat health is not checked by the application itself; monitoring of Filebeat connectivity is an infrastructure concern.
- No explicit retry policies, circuit breakers, or fallback strategies are implemented beyond per-message error logging and continuation.
