---
service: "ai-reporting"
title: "Merchant Wallet Top-up and Spend"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "merchant-wallet-topup-and-spend"
flow_type: asynchronous
trigger: "Merchant initiates wallet top-up via REST API, or Salesforce opportunity JMS event triggers automated wallet credit"
participants:
  - "continuumAiReportingService_restApi"
  - "continuumAiReportingService_merchantPaymentsService"
  - "continuumAiReportingService_ordersApiClient"
  - "continuumAiReportingService_citrusAdApiClient"
  - "continuumAiReportingService_salesforceClient"
  - "continuumAiReportingService_messageBusConsumers"
  - "continuumAiReportingService_mysqlRepositories"
  - "continuumAiReportingService_notificationsService"
  - "continuumAiReportingService_citrusAdReportsImportService"
  - "continuumAiReportingMySql"
  - "continuumAiReportingMessageBus"
  - "citrusAd"
  - "continuumOrdersService"
  - "salesForce"
architecture_ref: "dynamic-merchant-wallet-topup-and-spend"
---

# Merchant Wallet Top-up and Spend

## Summary

This flow handles the full merchant wallet lifecycle: topping up credit via the REST API (backed by Orders service for payment processing), receiving wallet credits triggered by Salesforce opportunity events via JMS, syncing wallet balances to CitrusAd for ad-spend authorization, and deducting spend through the periodic CitrusAd billing reconciliation cycle. Wallet state is the source of truth in MySQL, with CitrusAd wallet kept in eventual sync.

## Trigger

- **Type**: api-call (top-up initiated by merchant) or event (Salesforce JMS opportunity event)
- **Source**: POST `/merchants/{id}/wallet` from merchant dashboard, or `SalesforceOpportunityEvent` on `continuumAiReportingMessageBus`
- **Frequency**: On-demand (merchant-initiated); event-driven (Salesforce opportunity posted)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| REST API Layer | Receives merchant top-up requests | `continuumAiReportingService_restApi` |
| Merchant Payments Service | Orchestrates wallet balance, top-up, and refund operations | `continuumAiReportingService_merchantPaymentsService` |
| Orders API Client | Submits wallet top-up as an order via Groupon Orders service | `continuumAiReportingService_ordersApiClient` |
| CitrusAd API Client | Syncs wallet balance to CitrusAd | `continuumAiReportingService_citrusAdApiClient` |
| Salesforce Client | Reflects wallet state changes in Salesforce | `continuumAiReportingService_salesforceClient` |
| Message Bus Consumers | Receives Salesforce opportunity JMS events | `continuumAiReportingService_messageBusConsumers` |
| MySQL JDBI Repositories | Persists wallet ledger and transaction records | `continuumAiReportingService_mysqlRepositories` |
| Notifications Service | Sends wallet alerts and confirmations | `continuumAiReportingService_notificationsService` |
| CitrusAd Reports Import Service | Reconciles CitrusAd spend against wallet ledger | `continuumAiReportingService_citrusAdReportsImportService` |
| AI Reporting MySQL | Wallet ledger transactional store | `continuumAiReportingMySql` |
| JTier Message Bus | Carries Salesforce opportunity events | `continuumAiReportingMessageBus` |
| CitrusAd | Ad-serving platform; authorizes spend against wallet balance | `citrusAd` |
| Orders Service | Processes wallet top-up payment | `continuumOrdersService` |
| Salesforce | CRM; source of wallet credit opportunities | `salesForce` |

## Steps

### Path A: Merchant-initiated top-up via REST API

1. **Receives top-up request**: Merchant dashboard submits POST `/merchants/{id}/wallet` with top-up amount
   - From: `Merchant Dashboard`
   - To: `continuumAiReportingService_restApi`
   - Protocol: REST (HTTPS/JSON)

2. **Creates wallet order**: Merchant Payments Service submits a wallet top-up order via Orders service to process payment
   - From: `continuumAiReportingService_merchantPaymentsService`
   - To: `continuumOrdersService` via `continuumAiReportingService_ordersApiClient`
   - Protocol: HTTPS/JSON

3. **Persists wallet credit to MySQL**: Records the top-up transaction in the wallet ledger
   - From: `continuumAiReportingService_merchantPaymentsService`
   - To: `continuumAiReportingMySql` via `continuumAiReportingService_mysqlRepositories`
   - Protocol: JDBI

4. **Syncs wallet balance to CitrusAd**: Updates CitrusAd wallet with the new available balance
   - From: `continuumAiReportingService_merchantPaymentsService`
   - To: `citrusAd` via `continuumAiReportingService_citrusAdApiClient`
   - Protocol: HTTPS/JSON

5. **Sends wallet confirmation notification**: Notifies merchant of successful top-up
   - From: `continuumAiReportingService_merchantPaymentsService`
   - To: `notsService` via `continuumAiReportingService_notificationsService`
   - Protocol: HTTPS/JSON

### Path B: Salesforce opportunity event

1. **Receives Salesforce opportunity event**: JMS consumer receives `SalesforceOpportunityEvent` from Message Bus
   - From: `continuumAiReportingMessageBus`
   - To: `continuumAiReportingService_messageBusConsumers`
   - Protocol: JTier MessageBus / JMS

2. **Routes to Merchant Payments Service**: Message bus consumer delegates wallet credit to Merchant Payments Service
   - From: `continuumAiReportingService_messageBusConsumers`
   - To: `continuumAiReportingService_merchantPaymentsService`
   - Protocol: direct (in-process)

3. **Persists wallet credit and syncs CitrusAd**: Same as Path A steps 3 and 4

### Spend reconciliation (scheduled)

1. **Scheduler triggers reconciliation**: Quartz job triggers `continuumAiReportingService_citrusAdReportsImportService`
   - From: `continuumAiReportingService_scheduler`
   - To: `continuumAiReportingService_citrusAdReportsImportService`
   - Protocol: direct (in-process)

2. **Downloads CitrusAd billing report**: Fetches report file from GCS
   - From: `continuumAiReportingService_citrusAdReportsImportService`
   - To: `continuumAiReportingGcs` via `continuumAiReportingService_gcsClient`
   - Protocol: GCS SDK

3. **Reconciles spend against wallet ledger**: Compares CitrusAd billed spend with MySQL wallet balance; computes delta
   - From: `continuumAiReportingService_citrusAdReportsImportService`
   - To: `continuumAiReportingMySql` via `continuumAiReportingService_mysqlRepositories`
   - Protocol: JDBI

4. **Adjusts wallet balance**: Applies spend deduction to MySQL wallet ledger and syncs to CitrusAd
   - From: `continuumAiReportingService_citrusAdReportsImportService`
   - To: `continuumAiReportingService_merchantPaymentsService`
   - Protocol: direct (in-process)

5. **Loads reconciled metrics to BigQuery**: Stores reconciliation results for analytics
   - From: `continuumAiReportingService_citrusAdReportsImportService`
   - To: `continuumAiReportingBigQuery` via `continuumAiReportingService_bigQueryClient`
   - Protocol: BigQuery SDK

6. **Sends reconciliation alert on anomaly**: Fires Slack alert if billing delta exceeds threshold
   - From: `continuumAiReportingService_citrusAdReportsImportService`
   - To: `slack` via `continuumAiReportingService_notificationsService`
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Orders service unavailable during top-up | Top-up request rejected; no wallet credit issued | Merchant sees error; no charge made |
| CitrusAd wallet sync fails after MySQL write | MySQL balance updated; CitrusAd sync retried by Quartz job | Temporary wallet divergence; eventually consistent |
| Salesforce JMS event processing failure | JTier MBus retry per broker policy | Event reprocessed; idempotency check prevents duplicate credit |
| Reconciliation delta exceeds threshold | Slack alert fired; exception record written to MySQL | Finance and Ads Engineering notified for manual review |
| BigQuery load failure during reconciliation | Logged; reconciliation continues without analytics write | MySQL wallet state correct; BigQuery analytics may lag |

## Sequence Diagram

```
MerchantDashboard -> restApi: POST /merchants/{id}/wallet (amount)
restApi -> merchantPaymentsService: topUpWallet(merchantId, amount)
merchantPaymentsService -> ordersApiClient: createWalletOrder(amount)
ordersApiClient -> continuumOrdersService: HTTPS POST /orders
continuumOrdersService --> ordersApiClient: orderId
merchantPaymentsService -> mysqlRepositories: insertWalletTransaction(credit, orderId)
mysqlRepositories -> continuumAiReportingMySql: SQL INSERT
merchantPaymentsService -> citrusAdApiClient: updateWalletBalance(merchantId, newBalance)
citrusAdApiClient -> citrusAd: HTTPS PUT /wallet
citrusAd --> citrusAdApiClient: ok
merchantPaymentsService -> notificationsService: sendTopUpConfirmation(merchantId)
notificationsService -> notsService: HTTPS POST
restApi --> MerchantDashboard: 200 OK (wallet balance)

Note over continuumAiReportingMessageBus: Async path — Salesforce opportunity
continuumAiReportingMessageBus -> messageBusConsumers: SalesforceOpportunityEvent
messageBusConsumers -> merchantPaymentsService: creditWallet(merchantId, amount)
merchantPaymentsService -> mysqlRepositories: insertWalletTransaction(credit)
merchantPaymentsService -> citrusAdApiClient: updateWalletBalance(merchantId, newBalance)
```

## Related

- Architecture dynamic view: `dynamic-merchant-wallet-topup-and-spend`
- Related flows: [Sponsored Campaign Lifecycle](sponsored-campaign-lifecycle.md), [Ads Reporting Aggregation](ads-reporting-aggregation.md)
