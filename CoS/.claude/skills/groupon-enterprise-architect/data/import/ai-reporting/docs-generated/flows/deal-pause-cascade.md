---
service: "ai-reporting"
title: "Deal Pause Cascade"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-pause-cascade"
flow_type: event-driven
trigger: "DealPauseEvent or deal inactive event published by Deal Catalog to JTier Message Bus"
participants:
  - "continuumDealCatalogService"
  - "continuumAiReportingMessageBus"
  - "continuumAiReportingService_messageBusConsumers"
  - "continuumAiReportingService_sponsoredCampaignService"
  - "continuumAiReportingService_citrusAdCampaignService"
  - "continuumAiReportingService_citrusAdApiClient"
  - "continuumAiReportingService_mysqlRepositories"
  - "continuumAiReportingService_notificationsService"
  - "continuumAiReportingMySql"
  - "citrusAd"
  - "notsService"
architecture_ref: "dynamic-deal-pause-cascade"
---

# Deal Pause Cascade

## Summary

When the Deal Catalog service pauses or marks a deal as inactive, AI Reporting must propagate that state change to any Sponsored Listing campaigns associated with that deal. This event-driven flow ensures that merchants are not charged for ad spend on deals that are no longer visible to consumers. The service receives the pause event via JTier Message Bus, identifies all active campaigns linked to the deal, issues pause commands to CitrusAd, updates MySQL campaign state, and notifies the merchant.

## Trigger

- **Type**: event
- **Source**: `continuumDealCatalogService` publishes a deal pause or inactive event to `continuumAiReportingMessageBus`
- **Frequency**: Event-driven (triggered whenever a deal is paused or deactivated in the Deal Catalog)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Catalog Service | Publishes deal pause/inactive event | `continuumDealCatalogService` |
| JTier Message Bus | Carries deal pause events to AI Reporting consumers | `continuumAiReportingMessageBus` |
| Message Bus Consumers | Consumes deal pause/inactive JMS events | `continuumAiReportingService_messageBusConsumers` |
| Sponsored Campaign Service | Identifies affected campaigns and orchestrates pause cascade | `continuumAiReportingService_sponsoredCampaignService` |
| CitrusAd Campaign Service | Executes CitrusAd campaign pause operations | `continuumAiReportingService_citrusAdCampaignService` |
| CitrusAd API Client | Calls CitrusAd API to pause campaigns | `continuumAiReportingService_citrusAdApiClient` |
| MySQL JDBI Repositories | Reads active campaigns for deal; writes updated pause state | `continuumAiReportingService_mysqlRepositories` |
| Notifications Service | Sends pause notification to merchant | `continuumAiReportingService_notificationsService` |
| AI Reporting MySQL | Transactional store for campaign state | `continuumAiReportingMySql` |
| CitrusAd | Ad-serving platform; executes campaign pause | `citrusAd` |
| NOTS Service | Delivers pause notification to merchant | `notsService` |

## Steps

1. **Deal Catalog publishes pause event**: Deal Catalog service publishes a `DealPauseEvent` (or deal inactive event) to the JTier Message Bus topic
   - From: `continuumDealCatalogService`
   - To: `continuumAiReportingMessageBus`
   - Protocol: JTier MessageBus / JMS

2. **Message Bus Consumer receives event**: AI Reporting's JMS consumer picks up the deal pause event from the topic
   - From: `continuumAiReportingMessageBus`
   - To: `continuumAiReportingService_messageBusConsumers`
   - Protocol: JTier MessageBus / JMS

3. **Routes to Sponsored Campaign Service**: Consumer delegates the deal pause event to the Sponsored Campaign Service for business logic handling
   - From: `continuumAiReportingService_messageBusConsumers`
   - To: `continuumAiReportingService_sponsoredCampaignService`
   - Protocol: direct (in-process)

4. **Identifies active campaigns for the deal**: Queries MySQL to find all active or running Sponsored Listing campaigns associated with the paused deal ID
   - From: `continuumAiReportingService_sponsoredCampaignService`
   - To: `continuumAiReportingMySql` via `continuumAiReportingService_mysqlRepositories`
   - Protocol: JDBI

5. **Pauses each campaign in CitrusAd**: For each active campaign, delegates to CitrusAd Campaign Service to issue a pause command via CitrusAd API
   - From: `continuumAiReportingService_sponsoredCampaignService`
   - To: `citrusAd` via `continuumAiReportingService_citrusAdCampaignService` and `continuumAiReportingService_citrusAdApiClient`
   - Protocol: HTTPS/JSON

6. **Updates campaign state in MySQL**: Sets each affected campaign's status to paused in MySQL and records the triggering deal pause event
   - From: `continuumAiReportingService_sponsoredCampaignService`
   - To: `continuumAiReportingMySql` via `continuumAiReportingService_mysqlRepositories`
   - Protocol: JDBI

7. **Sends pause notification to merchant**: Notifies the merchant that their Sponsored Listing campaign was paused due to deal deactivation
   - From: `continuumAiReportingService_sponsoredCampaignService`
   - To: `notsService` via `continuumAiReportingService_notificationsService`
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No active campaigns found for deal | No-op; event acknowledged and discarded | No action taken; deal has no associated Sponsored Listings |
| CitrusAd API unavailable during pause | MySQL campaign state updated to paused; CitrusAd sync retried by Quartz campaign sync job | Campaign paused locally; CitrusAd sync eventually consistent |
| MySQL update failure | JTier MBus retry: event redelivered; idempotency check prevents duplicate pause | Campaign pause retried until MySQL write succeeds |
| Notification delivery failure | Logged; non-blocking — campaign still paused | Merchant not notified immediately; retry via NOTS |
| Duplicate event delivery | Campaign already paused in MySQL; idempotency check returns early | No-op; duplicate event safely ignored |

## Sequence Diagram

```
continuumDealCatalogService -> continuumAiReportingMessageBus: publish DealPauseEvent(dealId)
continuumAiReportingMessageBus -> messageBusConsumers: JMS deliver DealPauseEvent
messageBusConsumers -> sponsoredCampaignService: handleDealPause(dealId)
sponsoredCampaignService -> mysqlRepositories: getActiveCampaignsByDeal(dealId)
mysqlRepositories -> continuumAiReportingMySql: SQL SELECT WHERE deal_id = ? AND status = ACTIVE
continuumAiReportingMySql --> mysqlRepositories: [campaign1, campaign2, ...]
loop for each campaign
    sponsoredCampaignService -> citrusAdCampaignService: pauseCampaign(citrusAdCampaignId)
    citrusAdCampaignService -> citrusAdApiClient: PATCH /campaigns/{id} status=PAUSED
    citrusAdApiClient -> citrusAd: HTTPS PATCH
    citrusAd --> citrusAdApiClient: 200 OK
    sponsoredCampaignService -> mysqlRepositories: updateCampaignStatus(campaignId, PAUSED)
    mysqlRepositories -> continuumAiReportingMySql: SQL UPDATE
end
sponsoredCampaignService -> notificationsService: sendDealPausedNotification(merchantId, dealId)
notificationsService -> notsService: HTTPS POST /notifications
notsService --> notificationsService: 202 Accepted
```

## Related

- Architecture dynamic view: `dynamic-deal-pause-cascade`
- Related flows: [Sponsored Campaign Lifecycle](sponsored-campaign-lifecycle.md), [Merchant Wallet Top-up and Spend](merchant-wallet-topup-and-spend.md)
