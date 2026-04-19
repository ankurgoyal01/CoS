---
service: "ai-reporting"
title: "CitrusAd Feed Transport and Sync"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "citrusad-feed-transport-and-sync"
flow_type: scheduled
trigger: "Quartz scheduler fires feed generation jobs on configured cadence"
participants:
  - "continuumAiReportingService_scheduler"
  - "continuumAiReportingService_citrusAdFeedService"
  - "continuumAiReportingService_citrusAdCampaignService"
  - "continuumAiReportingService_searchTermsFeedService"
  - "continuumAiReportingService_gcsClient"
  - "continuumAiReportingService_citrusAdApiClient"
  - "continuumAiReportingService_mysqlRepositories"
  - "continuumAiReportingMySql"
  - "continuumAiReportingGcs"
  - "citrusAd"
architecture_ref: "dynamic-citrusad-feed-transport-and-sync"
---

# CitrusAd Feed Transport and Sync

## Summary

This flow generates the three core data feeds that CitrusAd requires to operate Groupon's Sponsored Listings: customer profiles, order history, and team/wallet configuration. The Quartz scheduler triggers feed generation on a regular cadence; the Feed Service reads source data from MySQL, writes feed files to GCS, and signals CitrusAd to ingest the new files. A parallel sub-flow handles search term feed processing and CPC override distribution.

## Trigger

- **Type**: schedule
- **Source**: Quartz Scheduler (`continuumAiReportingService_scheduler`) configured in JTier config
- **Frequency**: Scheduled (per-job cadence defined in Quartz config; typically daily for full feeds, more frequent for incremental)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Quartz Scheduler | Fires the feed generation and sync jobs | `continuumAiReportingService_scheduler` |
| CitrusAd Feed Service | Generates customer/order/team feed files and uploads to GCS | `continuumAiReportingService_citrusAdFeedService` |
| CitrusAd Campaign Service | Coordinates search term ingestion and schedules campaign sync | `continuumAiReportingService_citrusAdCampaignService` |
| Search Terms Feed Service | Processes search term feeds and CPC override files | `continuumAiReportingService_searchTermsFeedService` |
| GCS Client | Writes feed files to GCS bucket | `continuumAiReportingService_gcsClient` |
| CitrusAd API Client | Notifies CitrusAd to trigger feed ingestion | `continuumAiReportingService_citrusAdApiClient` |
| MySQL JDBI Repositories | Reads feed configuration, campaign data, and source records | `continuumAiReportingService_mysqlRepositories` |
| AI Reporting MySQL | Source of feed configuration and campaign metadata | `continuumAiReportingMySql` |
| AI Reporting GCS | Storage destination for generated feed files | `continuumAiReportingGcs` |
| CitrusAd | Ad-serving platform; consumes uploaded feeds | `citrusAd` |

## Steps

### Customer and Order Feed

1. **Scheduler fires feed job**: Quartz triggers the customer/order feed generation task
   - From: `continuumAiReportingService_scheduler`
   - To: `continuumAiReportingService_citrusAdFeedService`
   - Protocol: direct (in-process)

2. **Reads feed configuration and source data from MySQL**: Feed Service reads feed run metadata, customer scope, and order date range from MySQL
   - From: `continuumAiReportingService_citrusAdFeedService`
   - To: `continuumAiReportingMySql` via `continuumAiReportingService_mysqlRepositories`
   - Protocol: JDBI

3. **Generates customer feed file**: Compiles customer profile data into CitrusAd-format file
   - From: `continuumAiReportingService_citrusAdFeedService`
   - To: internal file generation
   - Protocol: direct (in-process)

4. **Generates order feed file**: Compiles order history into CitrusAd-format file
   - From: `continuumAiReportingService_citrusAdFeedService`
   - To: internal file generation
   - Protocol: direct (in-process)

5. **Uploads feed files to GCS**: Writes customer and order feed files to the configured GCS bucket path
   - From: `continuumAiReportingService_citrusAdFeedService`
   - To: `continuumAiReportingGcs` via `continuumAiReportingService_gcsClient`
   - Protocol: GCS SDK

6. **Notifies CitrusAd to ingest feeds**: Calls CitrusAd API to signal that new feed files are available in GCS
   - From: `continuumAiReportingService_citrusAdFeedService`
   - To: `citrusAd` via `continuumAiReportingService_citrusAdApiClient`
   - Protocol: HTTPS/JSON

7. **Updates feed run metadata in MySQL**: Records feed generation timestamp, file path, and status
   - From: `continuumAiReportingService_citrusAdFeedService`
   - To: `continuumAiReportingMySql` via `continuumAiReportingService_mysqlRepositories`
   - Protocol: JDBI

### Team Feed

1. **Scheduler fires team feed job**: Quartz triggers team membership feed generation
   - From: `continuumAiReportingService_scheduler`
   - To: `continuumAiReportingService_citrusAdFeedService`
   - Protocol: direct (in-process)

2. **Generates and uploads team feed**: Builds CitrusAd team configuration file and uploads to GCS; triggers CitrusAd ingestion
   - From: `continuumAiReportingService_citrusAdFeedService`
   - To: `continuumAiReportingGcs` via `continuumAiReportingService_gcsClient`, then `citrusAd` via `continuumAiReportingService_citrusAdApiClient`
   - Protocol: GCS SDK, HTTPS/JSON

### Search Terms Feed

1. **Scheduler fires search terms job**: Quartz triggers search terms feed refresh
   - From: `continuumAiReportingService_scheduler`
   - To: `continuumAiReportingService_searchTermsFeedService`
   - Protocol: direct (in-process)

2. **Reads search term rules from MySQL**: Loads active search terms and CPC overrides per campaign
   - From: `continuumAiReportingService_searchTermsFeedService`
   - To: `continuumAiReportingMySql` via `continuumAiReportingService_mysqlRepositories`
   - Protocol: JDBI

3. **Processes search term feed files from GCS**: Downloads CitrusAd-supplied search term analytics files for processing
   - From: `continuumAiReportingService_searchTermsFeedService`
   - To: `continuumAiReportingGcs` via `continuumAiReportingService_gcsClient`
   - Protocol: GCS SDK

4. **Coordinates CPC overrides with CitrusAd Campaign Service**: Passes updated CPC overrides to CitrusAd Campaign Service for application
   - From: `continuumAiReportingService_citrusAdCampaignService`
   - To: `continuumAiReportingService_searchTermsFeedService`
   - Protocol: direct (in-process)

5. **Persists updated search term rules**: Saves updated rules back to MySQL
   - From: `continuumAiReportingService_searchTermsFeedService`
   - To: `continuumAiReportingMySql` via `continuumAiReportingService_mysqlRepositories`
   - Protocol: JDBI

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GCS upload failure | Quartz job marked failed; retry on next scheduled cycle | CitrusAd receives stale feed until next successful upload |
| CitrusAd ingestion notification failure | GCS file is present; re-signal on next cycle | CitrusAd may ingest on its own polling cadence |
| MySQL read failure for feed config | Job fails; Quartz records failure; Slack alert if persistent | No feed generated for that cycle |
| Search term file corrupt or missing in GCS | Logged; CPC overrides not updated for that cycle | Previous search term rules remain active |

## Sequence Diagram

```
scheduler -> citrusAdFeedService: triggerCustomerFeedJob()
citrusAdFeedService -> mysqlRepositories: getFeedConfig()
mysqlRepositories -> continuumAiReportingMySql: SQL SELECT
continuumAiReportingMySql --> mysqlRepositories: config
citrusAdFeedService -> citrusAdFeedService: generateCustomerFeedFile()
citrusAdFeedService -> citrusAdFeedService: generateOrderFeedFile()
citrusAdFeedService -> gcsClient: uploadFile(customerFeed, gcsPath)
gcsClient -> continuumAiReportingGcs: GCS PUT
continuumAiReportingGcs --> gcsClient: ok
citrusAdFeedService -> gcsClient: uploadFile(orderFeed, gcsPath)
gcsClient -> continuumAiReportingGcs: GCS PUT
citrusAdFeedService -> citrusAdApiClient: notifyFeedReady(feedType, gcsPath)
citrusAdApiClient -> citrusAd: HTTPS POST /feeds/ingest
citrusAd --> citrusAdApiClient: accepted
citrusAdFeedService -> mysqlRepositories: updateFeedRunStatus(success, timestamp)

scheduler -> searchTermsFeedService: triggerSearchTermsRefresh()
searchTermsFeedService -> mysqlRepositories: getSearchTermRules()
searchTermsFeedService -> gcsClient: downloadSearchTermFile(gcsPath)
gcsClient -> continuumAiReportingGcs: GCS GET
searchTermsFeedService -> mysqlRepositories: upsertSearchTermRules(rules)
```

## Related

- Architecture dynamic view: `dynamic-citrusad-feed-transport-and-sync`
- Related flows: [Sponsored Campaign Lifecycle](sponsored-campaign-lifecycle.md), [Ads Reporting Aggregation](ads-reporting-aggregation.md)
