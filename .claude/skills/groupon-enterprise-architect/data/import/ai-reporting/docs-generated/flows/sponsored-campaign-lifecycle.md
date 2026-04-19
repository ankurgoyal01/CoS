---
service: "ai-reporting"
title: "Sponsored Campaign Lifecycle"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "sponsored-campaign-lifecycle"
flow_type: synchronous
trigger: "Merchant submits campaign create/edit/pause/deactivate request via REST API"
participants:
  - "continuumAiReportingService_restApi"
  - "continuumAiReportingService_sponsoredCampaignService"
  - "continuumAiReportingService_citrusAdCampaignService"
  - "continuumAiReportingService_citrusAdApiClient"
  - "continuumAiReportingService_dealCatalogClient"
  - "continuumAiReportingService_lazloClient"
  - "continuumAiReportingService_salesforceClient"
  - "continuumAiReportingService_mysqlRepositories"
  - "continuumAiReportingService_notificationsService"
  - "continuumAiReportingMySql"
  - "citrusAd"
  - "continuumDealCatalogService"
  - "continuumApiLazloService"
  - "salesForce"
architecture_ref: "dynamic-sponsored-campaign-lifecycle"
---

# Sponsored Campaign Lifecycle

## Summary

This flow covers the full lifecycle of a Sponsored Listing campaign from merchant-initiated creation through active management (budget edits, search term updates, status changes) and final deactivation or pause. The service orchestrates state changes across MySQL for transactional persistence and CitrusAd for the live ad-serving platform, ensuring both systems remain in sync at every lifecycle stage.

## Trigger

- **Type**: api-call
- **Source**: Merchant dashboard submits POST/PUT/DELETE to `/campaigns` or `/citrusad/campaigns`
- **Frequency**: On-demand (per merchant action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| REST API Layer | Receives and validates the campaign request | `continuumAiReportingService_restApi` |
| Sponsored Campaign Service | Orchestrates campaign lifecycle business rules | `continuumAiReportingService_sponsoredCampaignService` |
| CitrusAd Campaign Service | Executes CitrusAd-specific campaign operations | `continuumAiReportingService_citrusAdCampaignService` |
| CitrusAd API Client | HTTP calls to CitrusAd campaign, wallet, and team APIs | `continuumAiReportingService_citrusAdApiClient` |
| Deal Catalog Client | Resolves and validates deal metadata | `continuumAiReportingService_dealCatalogClient` |
| Lazlo Client | Evaluates feature flags and merchant identity | `continuumAiReportingService_lazloClient` |
| Salesforce Client | Syncs campaign state to Salesforce CRM | `continuumAiReportingService_salesforceClient` |
| MySQL JDBI Repositories | Persists and reads campaign state | `continuumAiReportingService_mysqlRepositories` |
| Notifications Service | Sends campaign lifecycle notifications | `continuumAiReportingService_notificationsService` |
| AI Reporting MySQL | Transactional campaign state store | `continuumAiReportingMySql` |
| CitrusAd | Live ad-serving platform | `citrusAd` |
| Deal Catalog Service | Source of truth for deal metadata | `continuumDealCatalogService` |
| Lazlo / Feature Flags | Identity and feature flag service | `continuumApiLazloService` |
| Salesforce | CRM for merchant account and campaign tracking | `salesForce` |

## Steps

1. **Receives campaign request**: Merchant dashboard sends POST `/campaigns` (create), PUT `/campaigns/{id}` (edit), or DELETE `/campaigns/{id}` (pause/deactivate)
   - From: `Merchant Dashboard`
   - To: `continuumAiReportingService_restApi`
   - Protocol: REST (HTTPS/JSON)

2. **Validates merchant identity and feature flags**: REST API layer calls Lazlo to confirm merchant identity and evaluate any campaign-type feature flags
   - From: `continuumAiReportingService_sponsoredCampaignService`
   - To: `continuumApiLazloService` via `continuumAiReportingService_lazloClient`
   - Protocol: HTTPS/JSON

3. **Resolves deal metadata**: Fetches deal data from Deal Catalog to validate deal eligibility and populate campaign parameters
   - From: `continuumAiReportingService_sponsoredCampaignService`
   - To: `continuumDealCatalogService` via `continuumAiReportingService_dealCatalogClient`
   - Protocol: HTTPS/JSON

4. **Applies campaign business rules**: Sponsored Campaign Service enforces budget constraints, subtype rules, and status transition validity
   - From: `continuumAiReportingService_restApi`
   - To: `continuumAiReportingService_sponsoredCampaignService`
   - Protocol: direct (in-process)

5. **Persists campaign state to MySQL**: Writes the new or updated campaign record to MySQL via JDBI repositories
   - From: `continuumAiReportingService_sponsoredCampaignService`
   - To: `continuumAiReportingMySql` via `continuumAiReportingService_mysqlRepositories`
   - Protocol: JDBI (JDBC)

6. **Syncs campaign to CitrusAd**: Delegates to CitrusAd Campaign Service to create, update, or pause the campaign in CitrusAd via the API client
   - From: `continuumAiReportingService_sponsoredCampaignService`
   - To: `citrusAd` via `continuumAiReportingService_citrusAdCampaignService` and `continuumAiReportingService_citrusAdApiClient`
   - Protocol: HTTPS/JSON

7. **Syncs state to Salesforce**: Pushes updated campaign and wallet state to Salesforce CRM
   - From: `continuumAiReportingService_sponsoredCampaignService`
   - To: `salesForce` via `continuumAiReportingService_salesforceClient`
   - Protocol: HTTPS/JSON

8. **Sends campaign notification**: Emits lifecycle notification (confirmation, pause alert, deactivation notice) via NOTS or email
   - From: `continuumAiReportingService_sponsoredCampaignService`
   - To: `notsService` via `continuumAiReportingService_notificationsService`
   - Protocol: HTTPS/JSON

9. **Returns response**: REST API returns campaign state to the dashboard
   - From: `continuumAiReportingService_restApi`
   - To: `Merchant Dashboard`
   - Protocol: REST (HTTPS/JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| CitrusAd API unavailable | MySQL write succeeds; CitrusAd sync deferred to Quartz retry job | Campaign state saved locally; CitrusAd sync eventually consistent |
| Deal Catalog returns invalid deal | Reject request with 400 error before any writes | No campaign created; error returned to merchant |
| Salesforce sync failure | Logged; non-blocking for campaign creation; retry on next sync cycle | Campaign active; Salesforce may be temporarily stale |
| MySQL write failure | Transaction rolled back; no campaign created | 500 error returned to merchant; no partial state |
| Lazlo unavailable | Configurable: fail-open (allow) or fail-closed (block) based on JTier feature flag config | Depends on flag configuration |

## Sequence Diagram

```
MerchantDashboard -> restApi: POST /campaigns (campaign params)
restApi -> sponsoredCampaignService: createCampaign(params)
sponsoredCampaignService -> lazloClient: evaluateFlags(merchantId)
lazloClient -> continuumApiLazloService: GET feature flags
continuumApiLazloService --> lazloClient: flags
sponsoredCampaignService -> dealCatalogClient: getDeal(dealId)
dealCatalogClient -> continuumDealCatalogService: GET /deals/{id}
continuumDealCatalogService --> dealCatalogClient: deal metadata
sponsoredCampaignService -> mysqlRepositories: insertCampaign(campaign)
mysqlRepositories -> continuumAiReportingMySql: SQL INSERT
continuumAiReportingMySql --> mysqlRepositories: ok
sponsoredCampaignService -> citrusAdCampaignService: syncCampaign(campaign)
citrusAdCampaignService -> citrusAdApiClient: POST /campaigns (CitrusAd)
citrusAdApiClient -> citrusAd: HTTPS POST
citrusAd --> citrusAdApiClient: CitrusAd campaign ID
sponsoredCampaignService -> salesforceClient: syncCampaignState(campaign)
salesforceClient -> salesForce: HTTPS POST
salesForce --> salesforceClient: ok
sponsoredCampaignService -> notificationsService: sendCampaignCreated(campaign)
notificationsService -> notsService: HTTPS POST
restApi --> MerchantDashboard: 201 Created (campaign)
```

## Related

- Architecture dynamic view: `dynamic-sponsored-campaign-lifecycle`
- Related flows: [Merchant Wallet Top-up and Spend](merchant-wallet-topup-and-spend.md), [CitrusAd Feed Transport and Sync](citrusad-feed-transport-and-sync.md), [Deal Pause Cascade](deal-pause-cascade.md)
