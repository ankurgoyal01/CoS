---
service: "getaways-payment-reconciliation"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 2
---

# Integrations

## Overview

The service has four external integrations (Accounting Service, Maris Inventory, Gmail IMAP/SMTP, and Groupon SMTP) and two internal infrastructure integrations (MBus topic and MySQL). All outbound HTTP calls use the lightweight `javalite-common` Http client. Gmail access uses Python's `imaplib`/`smtplib` with Google OAuth2 token refresh.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Accounting Service API | REST/HTTP | Creates vendor invoices in the finance system after reconciliation | yes | `accountingServiceApi_unk_3a9f` |
| Maris Inventory API | REST/HTTP | Fetches inventory unit details for a given unit UUID to populate reservation records | yes | `marisInventoryApi_unk_61b2` |
| Gmail (IMAP) | IMAP/SSL (port 993) | Downloads EAN invoice email attachments from inbox | yes | `gmailImap_unk_7e3a` |
| Gmail (SMTP) | SMTP/STARTTLS (port 587) | Sends invoice import success/failure status email | no | `gmailSmtp_unk_7e3a` |
| Groupon SMTP Server | SMTP | Sends reconciliation notifications to the operations team | no | `grouponSmtpServer_unk_2f8c` |

### Accounting Service API Detail

- **Protocol**: HTTP POST (javalite `Http.post`)
- **Base URL**: Configured via `accountingServiceClient.invoiceCreateUrl` (JTIER config YAML; format string including vendor ID)
- **Auth**: `as_api_token` header (secret; value from config)
- **Purpose**: Creates a vendor invoice record in the finance system for each reconciled EAN invoice; maps to vendor IDs per currency (USD → `vendorExpediaUSD`, EUR → `vendorExpediaEUR`, GBP → `vendorExpediaGBP`)
- **Failure mode**: Throws `RuntimeException` on HTTP response code >= 300; controlled by `isAccountingServiceEnabled` feature flag
- **Circuit breaker**: No evidence found

### Maris Inventory API Detail

- **Protocol**: HTTP GET (javalite `Http.get`)
- **Base URL**: Configured via `marisMessageBusConsumer.marisUrl` (JTIER config YAML; format string with unit UUID)
- **Auth**: `X-Request-Id` header (correlation ID only; no authentication token visible)
- **Purpose**: Retrieves `UnitResponse` (inventory unit details) for a given UUID after receiving an inventory-units-updated MBus event
- **Failure mode**: Exception propagates from `RestClient`; no retry mechanism visible
- **Circuit breaker**: No evidence found

### Gmail IMAP Detail

- **Protocol**: IMAP4 over SSL, `imap.gmail.com:993`
- **Auth**: Google OAuth2 XOAUTH2 (client_id, client_secret, refresh_token from config YAML secret)
- **Purpose**: Searches the Gmail inbox for unprocessed emails matching `email_filter_message`, downloads attachments matching `attachment_regex`, labels processed emails with `label_process`
- **Failure mode**: Script exits with failure status and reports to `invoice_importer_status` table
- **Circuit breaker**: No evidence found; egress network policy explicitly opens port 993

### Gmail SMTP Detail

- **Protocol**: SMTP with STARTTLS, `smtp.gmail.com:587`
- **Auth**: Google OAuth2 XOAUTH2 (same credentials as IMAP)
- **Purpose**: Sends import outcome (SUCCESS/FAILURE) email to `gmail.to_email` after each invoice import run
- **Failure mode**: Non-critical; import status still recorded in DB
- **Circuit breaker**: No evidence found; egress network policy explicitly opens port 587

### Groupon SMTP Server Detail

- **Protocol**: SMTP
- **Base URL / SDK**: Configured via `notificationConfig` (JTIER config YAML)
- **Auth**: No evidence found of SMTP auth configuration
- **Purpose**: `reconciliationWorker` calls `notificationService` to send status notifications after scheduled reconciliation runs
- **Failure mode**: Non-critical path; reconciliation continues
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| MBus inventory-units-updated topic | JMS | Consume inventory update events to persist reservation records | `messageBusInventoryUnitsUpdatedTopic_unk_4c1d` |
| MySQL (DaaS) | JDBC | Primary data store for all reconciliation entities | `continuumGetawaysPaymentReconciliationDb` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. The service is accessed by internal finance staff via the web UI and REST API at `http://getaways-payment-reconciliation-vip.snc1`.

## Dependency Health

No automated circuit breaker or health-check probes are configured for upstream HTTP dependencies in the codebase. Kubernetes readiness and liveness probes (60 s initial delay, 5/15 s period) gate traffic to the app pod. APM via Elastic APM agent is enabled in all environments for distributed tracing.
