---
service: "third-party-mailmonger"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Third Party Mailmonger.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Masked Email Provisioning](masked-email-provisioning.md) | synchronous | API call from TPIS during deal reservation | Creates or retrieves a unique masked email address for a consumer/partner pair |
| [Inbound Email Relay — Partner to Consumer](inbound-email-partner-to-consumer.md) | asynchronous | SparkPost relay webhook from partner SMTP send | Receives, filters, transforms, and delivers partner emails to real consumer address |
| [Inbound Email Relay — Consumer to Partner](inbound-email-consumer-to-partner.md) | asynchronous | SparkPost relay webhook from consumer SMTP reply | Receives, masks consumer identity, and delivers consumer reply to real partner address |
| [Email Filter Pipeline](email-filter-pipeline.md) | synchronous | MessageBus email processing | Applies ordered filter rules to determine if an email is permitted for delivery |
| [Email Retry and Scheduled Send](email-retry-scheduled.md) | scheduled | Quartz scheduler job | Retries emails in non-terminal failure states up to MAX_SEND_LIMIT attempts |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

The masked email provisioning flow spans `continuumThirdPartyMailmongerService` and `continuumUsersService` (for partner metadata validation) and is initiated by TPIS/Spaceman during order checkout. The inbound email relay flows span `sparkpost`, `continuumThirdPartyMailmongerService`, and `continuumUsersService` (for user email lookup). These flows are documented in the central architecture model under dynamic views for the Continuum platform.
