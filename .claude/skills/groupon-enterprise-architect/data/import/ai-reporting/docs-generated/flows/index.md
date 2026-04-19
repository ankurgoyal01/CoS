---
service: "ai-reporting"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for AI Reporting.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Sponsored Campaign Lifecycle](sponsored-campaign-lifecycle.md) | synchronous + event-driven | API call or JMS deal pause event | End-to-end lifecycle of a Sponsored Listing campaign from creation through pause/deactivation, including CitrusAd sync |
| [Merchant Wallet Top-up and Spend](merchant-wallet-topup-and-spend.md) | synchronous + asynchronous | API call or Salesforce opportunity event | Merchant initiates wallet top-up via API or Salesforce; spend deducted via CitrusAd reconciliation |
| [CitrusAd Feed Transport and Sync](citrusad-feed-transport-and-sync.md) | scheduled | Quartz scheduler | Generates customer/order/team feed files, uploads to GCS, and notifies CitrusAd for ingestion |
| [Ads Reporting Aggregation](ads-reporting-aggregation.md) | synchronous + scheduled | API call (dashboard request) or Quartz report download job | Aggregates vendor reports from CitrusAd, LiveIntent, Rokt, and Google Ad Manager into unified dashboard |
| [Audience Management Sync](audience-management-sync.md) | scheduled | Quartz scheduler | Reads audience data from Hive, computes deltas, persists to MySQL, and syncs to Audience Management Service |
| [Deal Pause Cascade](deal-pause-cascade.md) | event-driven | JMS DealPauseEvent from Deal Catalog | Receives deal pause/inactive event and propagates pause to all associated Sponsored Listing campaigns in CitrusAd |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 3 |

## Cross-Service Flows

- **Sponsored Campaign Lifecycle** spans `continuumAiReportingService`, `citrusAd`, `continuumDealCatalogService`, `salesForce`, and `continuumAiReportingMySql` — see [Sponsored Campaign Lifecycle](sponsored-campaign-lifecycle.md)
- **Merchant Wallet Top-up and Spend** spans `continuumAiReportingService`, `continuumOrdersService`, `citrusAd`, `salesForce`, and `continuumAiReportingMySql` — see [Merchant Wallet Top-up and Spend](merchant-wallet-topup-and-spend.md)
- **CitrusAd Feed Transport and Sync** spans `continuumAiReportingService`, `continuumAiReportingGcs`, and `citrusAd` — see [CitrusAd Feed Transport and Sync](citrusad-feed-transport-and-sync.md)
- **Ads Reporting Aggregation** spans `continuumAiReportingService`, `citrusAd`, `liveIntent`, `rokt`, `googleAdManager`, and `continuumAiReportingBigQuery` — see [Ads Reporting Aggregation](ads-reporting-aggregation.md)
- **Audience Management Sync** spans `continuumAiReportingService`, `continuumAiReportingHive`, `continuumAudienceManagementService`, and `continuumAiReportingMySql` — see [Audience Management Sync](audience-management-sync.md)
- **Deal Pause Cascade** spans `continuumDealCatalogService`, `continuumAiReportingMessageBus`, `continuumAiReportingService`, and `citrusAd` — see [Deal Pause Cascade](deal-pause-cascade.md)
