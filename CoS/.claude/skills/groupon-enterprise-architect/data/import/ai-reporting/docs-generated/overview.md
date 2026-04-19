---
service: "ai-reporting"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Ads / Sponsored Listings"
platform: "Continuum"
team: "Ads Engineering (ads-eng@groupon.com)"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard / JTier"
  framework_version: "5.14.1"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# AI Reporting Overview

## Purpose

AI Reporting (`ai-reporting`) is the Groupon Ads platform backend that manages the full lifecycle of Sponsored Listing campaigns: onboarding merchant campaigns into CitrusAd, handling merchant wallet top-ups and spend, transporting customer/order/team data feeds to CitrusAd, and aggregating multi-vendor ads performance reports (CitrusAd, LiveIntent, Rokt, Google Ad Manager) into a unified dashboard. It acts as the integration hub between Groupon's commerce systems and its ad-tech partners, ensuring campaign state, billing, and audience data remain consistent across all parties.

## Scope

### In scope

- Sponsored Listing campaign creation, editing, pausing, and deactivation
- Merchant wallet management: top-ups, spend tracking, refunds, and free credits
- CitrusAd feed transport: customer, order, and team feeds uploaded to GCS for CitrusAd ingestion
- CitrusAd report download, reconciliation, and billing adjustment
- Search terms feed processing and CPC override management
- Multi-vendor ads reporting dashboard (`/api/v1/reports`): LiveIntent, Rokt, Google Ad Manager
- Audience management synchronization with `continuumAudienceManagementService`
- Salesforce account and wallet data synchronization
- Deal pause cascade on deal catalog pause/inactive events

### Out of scope

- Consumer-facing deal browsing and purchase (owned by MBNXT / commerce services)
- Merchant identity and authentication (delegated to `continuumUniversalMerchantApi` / Lazlo)
- Deal catalog data ownership (owned by `continuumDealCatalogService`)
- Order processing (owned by `continuumOrdersService`)
- Coupon inventory management (owned by `continuumCouponsInventoryService`)

## Domain Context

- **Business domain**: Ads / Sponsored Listings
- **Platform**: Continuum
- **Upstream consumers**: Merchant-facing dashboards, Salesforce (via callbacks), CitrusAd (via GCS feeds and webhooks)
- **Downstream dependencies**: CitrusAd, Salesforce, `continuumDealCatalogService`, `continuumOrdersService`, `continuumMarketingDealService`, `continuumCouponsInventoryService`, `continuumAudienceManagementService`, `merchantAdvisorService`, `continuumApiLazloService`, `continuumM3MerchantService`, LiveIntent, Rokt, `googleAdManager`, `notsService`, `slack`, `continuumUniversalMerchantApi`, `continuumVoucherInventoryService`, `continuumBhuvanService`

## Stakeholders

| Role | Description |
|------|-------------|
| Ads Engineering | Owns and operates the service (ads-eng@groupon.com) |
| Merchant Partners | Create and manage Sponsored Listing campaigns via the dashboard |
| Ads Sales / Salesforce Ops | Manage wallet top-ups and account sync via Salesforce integration |
| Finance / Billing | Rely on wallet reconciliation and CitrusAd billing adjustments |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | DSL: `continuum-ai-reporting-service-components.dsl` |
| Framework | Dropwizard / JTier | 5.14.1 | DSL: `continuum-ai-reporting-service-components.dsl` |
| Runtime | JVM | 11 | DSL: `continuum-ai-reporting-service-components.dsl` |
| Build tool | Maven | — | Inventory |
| Package manager | Maven | — | Inventory |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| JDBI | — | db-client | SQL access layer for MySQL (campaigns, payments, feeds, audiences) |
| JTier Quartz | 5.14.1 | scheduling | Scheduled jobs: feed transport, report downloads, wallet sync, audience refresh |
| JTier Message Bus | 5.14.1 | message-client | JMS consumer for Salesforce opportunity and deal pause events |
| Google Cloud Storage | 1.25.0 | storage-client | Upload/download CitrusAd feeds and report artifacts from GCS |
| BigQuery | 2.19.1 | db-client | Load and query CitrusAd analytics datasets for reconciliation and dashboards |
| Google Ads | 5.6.0 | integration | Google Ad Manager report ingestion |
| Jackson | 2.12.1 | serialization | JSON serialization/deserialization across REST and messaging layers |
| OkHttp | — | http-framework | HTTP client used for external API calls (CitrusAd, Salesforce, internal services) |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
