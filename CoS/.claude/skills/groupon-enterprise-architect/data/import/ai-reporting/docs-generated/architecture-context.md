---
service: "ai-reporting"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumAiReportingService, continuumAiReportingMySql, continuumAiReportingHive, continuumAiReportingBigQuery, continuumAiReportingGcs, continuumAiReportingMessageBus]
---

# Architecture Context

## System Context

AI Reporting is a backend service within the `continuumSystem` (Continuum Platform). It sits at the intersection of Groupon's commerce data (deals, orders, merchants) and its ad-tech partners (CitrusAd, LiveIntent, Rokt, Google Ad Manager). Merchant-facing dashboards and Salesforce CRM drive inbound requests; the service pushes data outbound to CitrusAd feeds and pulls performance analytics back for reporting. It integrates with over 15 internal Continuum services for identity, deal data, orders, and audience management.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| AI Reporting Service | `continuumAiReportingService` | Backend | Java 11, Dropwizard, JTier | 5.14.1 | Primary service: campaign lifecycle, wallet/payments, feed transport, reporting |
| AI Reporting MySQL | `continuumAiReportingMySql` | Database | MySQL | 5.6 | Transactional store for campaigns, payments, configs, audiences, and reporting metadata |
| AI Reporting Hive | `continuumAiReportingHive` | Database | Hive on Hadoop | — | Analytics warehouse for audience and advisor feeds |
| AI Reporting BigQuery | `continuumAiReportingBigQuery` | Database | GCP BigQuery | — | Analytical dataset for CitrusAd reporting and wallet analytics |
| AI Reporting GCS | `continuumAiReportingGcs` | Storage | Google Cloud Storage | — | Bucket storage for CitrusAd feeds, search term files, and downloaded reports |
| JTier Message Bus | `continuumAiReportingMessageBus` | Messaging | JTier MessageBus / JMS | — | JMS topics/queues for Salesforce and deal state events |

## Components by Container

### AI Reporting Service (`continuumAiReportingService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| REST API Layer (`continuumAiReportingService_restApi`) | Jersey resources for Sponsored Campaigns, Wallet/Payments, Reports, Salesforce callbacks, and event endpoints | Dropwizard Jersey |
| Quartz Scheduler & Jobs (`continuumAiReportingService_scheduler`) | Scheduled feed transport, campaign sync, reporting downloads, wallet updates, and audience refresh | Quartz |
| Message Bus Consumers (`continuumAiReportingService_messageBusConsumers`) | Consumes Salesforce opportunity and deal pause/inactive JMS events | JTier MessageBus |
| Sponsored Campaign Service (`continuumAiReportingService_sponsoredCampaignService`) | Campaign lifecycle coordination: create, edit, pause, deactivate, budgets, subtype rules | Java |
| CitrusAd Campaign Service (`continuumAiReportingService_citrusAdCampaignService`) | CitrusAd campaign operations: search terms, CPC overrides, sync, validation | Java |
| Merchant Payments Service (`continuumAiReportingService_merchantPaymentsService`) | Wallet balances, top-ups, refunds, and ledger integration | Java |
| CitrusAd Reports Import Service (`continuumAiReportingService_citrusAdReportsImportService`) | Downloads CitrusAd analytics from GCS, reconciles billing, updates wallets, raises alerts | Java, GCS, BigQuery |
| CitrusAd Feed Service (`continuumAiReportingService_citrusAdFeedService`) | Generates and uploads customer/order/team feeds for CitrusAd ingestion | Java, GCS |
| Free Credits Service (`continuumAiReportingService_freeCreditsService`) | Issues, tracks, and notifies free credit promotions for merchants | Java |
| Audience Service (`continuumAiReportingService_audienceService`) | Manages audience tables and synchronization with Audience Management System | Java |
| Search Terms Feed Service (`continuumAiReportingService_searchTermsFeedService`) | Processes search term feeds, CPC overrides, and search term analytics files | Java, GCS |
| Ads Reports Service (`continuumAiReportingService_reportsService`) | Aggregates vendor reports (LiveIntent, Rokt, GAM) and exposes dashboard data | Java |
| Notifications Service (`continuumAiReportingService_notificationsService`) | Composes and sends notifications via NOTS, email templates, and Slack alerts | Java |
| MySQL JDBI Repositories (`continuumAiReportingService_mysqlRepositories`) | JDBI DAOs for campaigns, payments, clicks, audiences, configs, and metrics | JDBI, MySQL |
| Hive Analytics Executor (`continuumAiReportingService_hiveAnalytics`) | Hive JDBC executor and table creator for advisor/audience jobs | Hive JDBC |
| BigQuery Client (`continuumAiReportingService_bigQueryClient`) | Client for CitrusAd analytics datasets used in reconciliation and dashboards | GCP BigQuery |
| GCS Client (`continuumAiReportingService_gcsClient`) | GCP Storage client for uploading/downloading feeds and report artifacts | GCP Storage |
| CitrusAd API Client (`continuumAiReportingService_citrusAdApiClient`) | HTTP client wrappers for CitrusAd OAuth, campaign, wallet, and team APIs | HTTP/JSON |
| Salesforce Client (`continuumAiReportingService_salesforceClient`) | Manages Salesforce OAuth cache and account/wallet synchronization | HTTP/JSON |
| Orders API Client (`continuumAiReportingService_ordersApiClient`) | Invokes Groupon Orders APIs for wallet orders, refunds, and redemptions | HTTP/JSON |
| Merchant Advisor Client (`continuumAiReportingService_merchantAdvisorClient`) | Integrates with Merchant Advisor for deal insight feeds | HTTP/JSON |
| Deal Catalog Client (`continuumAiReportingService_dealCatalogClient`) | Retrieves deal metadata and updates deal categories | HTTP/JSON |
| Lazlo Client (`continuumAiReportingService_lazloClient`) | Feature flag and identity client used during campaign operations | HTTP/JSON |
| M3 Client (`continuumAiReportingService_m3Client`) | Merchant account service integration | HTTP/JSON |
| LiveIntent Client (`continuumAiReportingService_liveIntentClient`) | Retrieves LiveIntent ad performance data | HTTP/JSON |
| Rokt Client (`continuumAiReportingService_roktClient`) | Retrieves Rokt ad performance and billing data | HTTP/JSON |
| NOTS Client (`continuumAiReportingService_notsClient`) | Notification orchestration service client | HTTP/JSON |
| Slack Notifier (`continuumAiReportingService_slackNotifier`) | Sends operational alerts to Slack channels | HTTP/JSON |
| Audience Management Client (`continuumAiReportingService_audienceManagementClient`) | AudienceManagementService client for audience sync | HTTP/JSON |
| UMAPI Client (`continuumAiReportingService_umapiClient`) | User management API client for auth lookups | HTTP/JSON |
| VIS Client (`continuumAiReportingService_visClient`) | Voucher/Inventory service client for Sponsored Listings | HTTP/JSON |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumAiReportingService` | `continuumAiReportingMySql` | Read/write campaigns, payments, feeds, and configuration | JDBI |
| `continuumAiReportingService` | `continuumAiReportingHive` | Query audience and advisor datasets | Hive JDBC |
| `continuumAiReportingService` | `continuumAiReportingBigQuery` | Load and query CitrusAd analytics | BigQuery SDK |
| `continuumAiReportingService` | `continuumAiReportingGcs` | Store and retrieve CitrusAd feeds and reports | GCS SDK |
| `continuumAiReportingService` | `continuumAiReportingMessageBus` | Consume Salesforce and deal state topics | JTier MessageBus |
| `continuumAiReportingService` | `citrusAd` | Sync campaigns, wallets, teams, and pull reports | HTTPS/JSON |
| `continuumAiReportingService` | `salesForce` | Sync account and wallet data; receive JMS notifications | HTTPS/JSON |
| `continuumAiReportingService` | `continuumDealCatalogService` | Fetch and update deal metadata | HTTPS/JSON |
| `continuumAiReportingService` | `merchantAdvisorService` | Import merchant advice and recommendations | HTTPS/JSON |
| `continuumAiReportingService` | `continuumApiLazloService` | Evaluate identity and feature flags | HTTPS/JSON |
| `continuumAiReportingService` | `continuumM3MerchantService` | Lookup merchant account details | HTTPS/JSON |
| `continuumAiReportingService` | `liveIntent` | Retrieve LiveIntent campaign performance | HTTPS/JSON |
| `continuumAiReportingService` | `rokt` | Retrieve Rokt campaign performance | HTTPS/JSON |
| `continuumAiReportingService` | `notsService` | Send outbound notifications | HTTPS/JSON |
| `continuumAiReportingService` | `slack` | Send operational Slack alerts | HTTPS/JSON |
| `continuumAiReportingService` | `continuumAudienceManagementService` | Sync audience membership | HTTPS/JSON |
| `continuumAiReportingService` | `continuumUniversalMerchantApi` | Authenticate or lookup users | HTTPS/JSON |
| `continuumAiReportingService` | `continuumVoucherInventoryService` | Interact with voucher/inventory flows | HTTPS/JSON |
| `continuumAiReportingService` | `continuumOrdersService` | Read order data and submit reversals | HTTPS/JSON |
| `continuumAiReportingService` | `continuumMarketingDealService` | Read and update deal metadata for sponsored listings | HTTPS/JSON |
| `continuumAiReportingService` | `continuumCouponsInventoryService` | Read coupon inventory deal data | HTTPS/JSON |
| `continuumAiReportingService` | `continuumBhuvanService` | Read geo divisions | HTTPS/JSON |
| `continuumAiReportingService` | `googleAdManager` | Ingest ad inventory and performance reports | HTTPS/JSON |

## Architecture Diagram References

- System context: `contexts-continuum-ai-reporting`
- Container: `containers-continuum-ai-reporting`
- Component: `components-continuum-ai-reporting-continuumAiReportingService_sponsoredCampaignService`
