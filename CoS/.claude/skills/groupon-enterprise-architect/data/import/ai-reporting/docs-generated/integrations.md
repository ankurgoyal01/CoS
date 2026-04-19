---
service: "ai-reporting"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 7
internal_count: 12
---

# Integrations

## Overview

AI Reporting integrates with 7 external ad-tech and CRM systems and 12 internal Continuum platform services. External integrations cover the full ads partner ecosystem (CitrusAd, Salesforce, LiveIntent, Rokt, Google Ad Manager) plus operational tooling (Slack, NOTS). Internal integrations span merchant identity, deal metadata, orders, commerce inventory, audience management, and geo services. All integrations use HTTPS/JSON over REST with OkHttp as the underlying HTTP client.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| CitrusAd | HTTPS/JSON | Campaign sync, wallet management, team feeds, report retrieval | yes | `citrusAd` |
| Salesforce | HTTPS/JSON + JMS | Account and wallet data sync; inbound opportunity notifications | yes | `salesForce` |
| LiveIntent | HTTPS/JSON | Retrieve LiveIntent campaign performance for ads reporting dashboard | no | `liveIntent` |
| Rokt | HTTPS/JSON | Retrieve Rokt campaign performance and billing data | no | `rokt` |
| Google Ad Manager | HTTPS/JSON | Ingest ad inventory and performance reports | no | `googleAdManager` |
| NOTS (Notification Orchestration) | HTTPS/JSON | Send outbound merchant notifications (email, push) | no | `notsService` |
| Slack | HTTPS/JSON | Send operational and reconciliation alerts to Slack channels | no | `slack` |

### CitrusAd Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: CitrusAd platform API; OAuth token managed by `continuumAiReportingService_citrusAdApiClient`
- **Auth**: OAuth 2.0 client credentials; token cached in-service
- **Purpose**: Full campaign lifecycle management in CitrusAd — create, update, pause, sync campaigns; manage wallet balances and teams; retrieve performance reports
- **Failure mode**: Campaign sync failures are queued for retry by the Quartz scheduler; wallet sync failures trigger Slack alerts; report download failures generate reconciliation exceptions in MySQL
- **Circuit breaker**: No evidence found

### Salesforce Detail

- **Protocol**: HTTPS/JSON (outbound API) + JTier MessageBus/JMS (inbound events)
- **Base URL / SDK**: Salesforce REST API; OAuth token cached by `continuumAiReportingService_salesforceClient`
- **Auth**: OAuth 2.0; token cache maintained per session
- **Purpose**: Push campaign state and wallet changes to Salesforce CRM; receive inbound opportunity events that trigger wallet ledger updates
- **Failure mode**: Sync failures are retried; persistent failures logged and alerted via Slack
- **Circuit breaker**: No evidence found

### LiveIntent Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: LiveIntent API via `continuumAiReportingService_liveIntentClient`
- **Auth**: API key (inferred from ad-tech API patterns; not confirmed in DSL)
- **Purpose**: Retrieve LiveIntent ad performance metrics for aggregated reporting dashboard
- **Failure mode**: Missing LiveIntent data returns partial dashboard response; no blocking impact on campaigns
- **Circuit breaker**: No evidence found

### Rokt Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: Rokt API via `continuumAiReportingService_roktClient`
- **Auth**: API key (inferred; not confirmed in DSL)
- **Purpose**: Retrieve Rokt ad performance and billing data for reporting dashboard
- **Failure mode**: Missing Rokt data returns partial dashboard response
- **Circuit breaker**: No evidence found

### Google Ad Manager Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: Google Ads SDK 5.6.0 via `continuumAiReportingService_reportsService`
- **Auth**: Google service account / OAuth 2.0
- **Purpose**: Ingest ad inventory and performance reports for inclusion in unified ads reporting dashboard
- **Failure mode**: Missing GAM data returns partial report; no blocking campaign impact
- **Circuit breaker**: No evidence found

### NOTS Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: Internal NOTS service via `continuumAiReportingService_notsClient`
- **Auth**: Internal service auth (JTier)
- **Purpose**: Deliver merchant-facing notifications (email/push) for campaign events, wallet alerts, and free credit issuances
- **Failure mode**: Notification failures are logged; campaign operations continue without notification
- **Circuit breaker**: No evidence found

### Slack Detail

- **Protocol**: HTTPS/JSON (Slack Incoming Webhook)
- **Base URL / SDK**: Slack webhook URL via `continuumAiReportingService_slackNotifier`
- **Auth**: Webhook URL secret
- **Purpose**: Operational alerts to Ads Engineering Slack channels for reconciliation anomalies, sync failures, and wallet exceptions
- **Failure mode**: Slack alert failure is non-blocking; primary operation proceeds regardless
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `continuumDealCatalogService` | HTTPS/JSON | Fetch and update deal metadata and categories for campaigns | `continuumDealCatalogService` |
| `merchantAdvisorService` | HTTPS/JSON | Import merchant advice and deal insight recommendations | `merchantAdvisorService` |
| `continuumApiLazloService` | HTTPS/JSON | Evaluate identity and feature flags during campaign operations | `continuumApiLazloService` |
| `continuumM3MerchantService` | HTTPS/JSON | Lookup merchant account details | `continuumM3MerchantService` |
| `continuumAudienceManagementService` | HTTPS/JSON | Sync audience membership for campaign targeting | `continuumAudienceManagementService` |
| `continuumUniversalMerchantApi` | HTTPS/JSON | Authenticate and lookup merchant users (UMAPI) | `continuumUniversalMerchantApi` |
| `continuumVoucherInventoryService` | HTTPS/JSON | Interact with voucher/inventory flows for Sponsored Listings | `continuumVoucherInventoryService` |
| `continuumOrdersService` | HTTPS/JSON | Read order data and submit wallet order reversals | `continuumOrdersService` |
| `continuumMarketingDealService` | HTTPS/JSON | Read and update deal metadata for Sponsored Listings | `continuumMarketingDealService` |
| `continuumCouponsInventoryService` | HTTPS/JSON | Read coupon inventory deal data | `continuumCouponsInventoryService` |
| `continuumBhuvanService` | HTTPS/JSON | Read geo divisions for campaign targeting | `continuumBhuvanService` |
| `notsService` | HTTPS/JSON | Notification orchestration service | `notsService` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known consumers include merchant-facing Sponsored Listings dashboards and Salesforce CRM (via JMS callback events).

## Dependency Health

> Operational procedures to be defined by service owner. No explicit health check, retry, or circuit breaker configuration was discovered in the available DSL inventory. Retry logic is embedded in the Quartz scheduler job framework for async operations. Contact ads-eng@groupon.com for production runbook details.
