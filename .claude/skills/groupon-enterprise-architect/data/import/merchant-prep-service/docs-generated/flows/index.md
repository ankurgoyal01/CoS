---
service: "merchant-prep-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for the Merchant Preparation Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Merchant Self-Prep Step Completion](merchant-self-prep-step-completion.md) | synchronous | Merchant submits a prep step via Merchant Center | Merchant completes a deal prep step (tax, payment, billing, etc.); service validates, persists state, updates Salesforce, and records audit trail |
| [Payment Information Update](payment-info-update.md) | synchronous | Merchant submits new banking/payment information | Service receives payment details, validates them (TIN, IBAN, routing), updates Salesforce, publishes MBUS event, and enforces payment hold rules |
| [Onboarding Checklist Progression](onboarding-checklist-progression.md) | synchronous | Merchant opens or progresses through the onboarding checklist | Service retrieves or updates merchant onboarding step status from local DB and Salesforce |
| [Merchant Verification Code Flow](merchant-verification-code.md) | synchronous | Merchant requests or submits an identity verification code | Service generates and validates verification codes as part of identity verification during prep |
| [Last Login Sync Job](last-login-sync-job.md) | scheduled | Quartz scheduler (periodic) | Scheduled job reads last-login timestamps from local DB and writes them back to Salesforce merchant records |
| [Monthly Survey Dispatch Job](monthly-survey-dispatch-job.md) | scheduled | Quartz scheduler (monthly) | Scheduled job identifies eligible merchants and triggers NOTS to send survey notification emails |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- The **Payment Information Update** flow crosses into `salesForce`, `continuumAccountingService`, and publishes to `messageBus`. It is the most integration-heavy synchronous flow.
- The **Last Login Sync Job** crosses into `salesForce` — it is purely a scheduled write-back.
- The **Monthly Survey Dispatch Job** crosses into `notsService` to trigger email dispatch.
- All self-prep flows that result in data changes cross into `salesForce` as the system of record for merchant accounts and opportunities.
