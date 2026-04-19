---
service: "travel-affiliates-api"
title: "Scheduled Hotel Feed Export (Cron)"
generated: "2026-03-03"
type: flow
flow_name: "scheduled-hotel-feed-export"
flow_type: scheduled
trigger: "Kubernetes CronJob schedule: daily at 10:00 UTC (0 10 * * *)"
participants:
  - "continuumTravelAffiliatesCron"
  - "continuumTravelAffiliatesCron_jobRunner"
  - "continuumTravelAffiliatesCron_hotelsFeedJob"
  - "continuumTravelAffiliatesCron_hotelsFeedService"
  - "continuumTravelAffiliatesCron_activeDealsSummaryManager"
  - "continuumTravelAffiliatesCron_dealCatalogApiClient"
  - "continuumTravelAffiliatesCron_getawaysApiClient"
  - "continuumTravelAffiliatesCron_awsFileUploadService"
  - "continuumGetawaysApi"
  - "continuumTravelAffiliatesFeedBucket"
architecture_ref: "dynamic-affiliate-availability-flow"
---

# Scheduled Hotel Feed Export (Cron)

## Summary

The Travel Affiliates Cron container runs as a Kubernetes CronJob once daily at 10:00 UTC. It executes the `JobRunner` CLI entrypoint, which loads `CronConfig` and runs the `HotelsFeedJob`. The job aggregates all active Getaways hotel deals from the Deal Catalog API and Getaways content API, generates hotel feed XML files per region, and uploads them to the configured AWS S3 bucket. This ensures that affiliate partners consuming the S3-hosted feed have up-to-date hotel inventory data each day.

## Trigger

- **Type**: schedule
- **Source**: Kubernetes CronJob (`jobSchedule: "0 10 * * *"`)
- **Frequency**: Daily at 10:00 UTC

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kubernetes CronJob | Schedules and launches the cron container | Kubernetes |
| Job Runner | CLI entrypoint; loads CronConfig; invokes HotelsFeedJob | `continuumTravelAffiliatesCron_jobRunner` |
| Hotels Feed Job | Orchestrates feed generation per region; triggers S3 upload | `continuumTravelAffiliatesCron_hotelsFeedJob` |
| Hotels Feed Service (Cron) | Builds hotel XML feed payloads from aggregated data | `continuumTravelAffiliatesCron_hotelsFeedService` |
| Active Deals Summary Manager (Cron) | Aggregates active deals and hotel details | `continuumTravelAffiliatesCron_activeDealsSummaryManager` |
| Deal Catalog API Client (Cron) | Loads active deal UUIDs from Deal Catalog API | `continuumTravelAffiliatesCron_dealCatalogApiClient` |
| Getaways API Client (Cron) | Loads product sets and hotel details from Getaways API | `continuumTravelAffiliatesCron_getawaysApiClient` |
| AWS File Upload Service (Cron) | Uploads generated feed files to S3 | `continuumTravelAffiliatesCron_awsFileUploadService` |
| Getaways API | Returns product sets and hotel detail data | `continuumGetawaysApi` |
| Travel Affiliates S3 Feed Bucket | Persists generated feed files | `continuumTravelAffiliatesFeedBucket` |

## Steps

1. **CronJob fires**: Kubernetes CronJob launches a new pod from the `travel-affiliates-api--cron` Docker image at 10:00 UTC daily. The container waits 30 seconds before starting execution.
   - From: Kubernetes scheduler
   - To: `continuumTravelAffiliatesCron_jobRunner`
   - Protocol: Container lifecycle

2. **Job Runner initializes**: `JobRunner` loads `CronConfig`, which resolves the active environment from `APP_ENVIRONMENT` and loads classpath properties (`settings.properties`, `{env}-US-settings.properties`). Spring context initializes HTTP connection pool (max 1000 connections, 100 per route).
   - From: `continuumTravelAffiliatesCron_jobRunner`
   - To: `continuumTravelAffiliatesCron_hotelsFeedJob`
   - Protocol: In-process invocation

3. **Feed job begins**: `HotelsFeedJob` invokes `HotelsFeedService` to build hotel feed payloads.
   - From: `continuumTravelAffiliatesCron_hotelsFeedJob`
   - To: `continuumTravelAffiliatesCron_hotelsFeedService`
   - Protocol: In-process call

4. **Aggregates active deals**: Hotels Feed Service invokes Active Deals Summary Manager to fetch all active hotel inventory.
   - From: `continuumTravelAffiliatesCron_hotelsFeedService`
   - To: `continuumTravelAffiliatesCron_activeDealsSummaryManager`
   - Protocol: In-process call

5. **Loads active deal UUIDs**: Active Deals Summary Manager calls Deal Catalog API Client to retrieve active deal UUIDs and regional data.
   - From: `continuumTravelAffiliatesCron_activeDealsSummaryManager`
   - To: `continuumTravelAffiliatesCron_dealCatalogApiClient`
   - Protocol: REST/JSON

6. **Fetches product sets (paginated)**: Active Deals Summary Manager calls Getaways API Client's `getProductSets()`, iterating pages using `offset` until all active products are retrieved.
   - From: `continuumTravelAffiliatesCron_activeDealsSummaryManager`
   - To: `continuumTravelAffiliatesCron_getawaysApiClient`
   - Protocol: In-process call

7. **Queries Getaways product sets**: Getaways API Client GETs product sets endpoint with `limit`, `status_list`, and paginated `offset`.
   - From: `continuumTravelAffiliatesCron_getawaysApiClient`
   - To: `continuumGetawaysApi`
   - Protocol: REST/JSON

8. **Fetches batch hotel details**: Active Deals Summary Manager calls `getHotelDetails()` in batches determined by `getaways.api.content.batchhoteldetail.batchsize`.
   - From: `continuumTravelAffiliatesCron_activeDealsSummaryManager`
   - To: `continuumTravelAffiliatesCron_getawaysApiClient`
   - Protocol: In-process call

9. **Queries hotel detail endpoint**: Getaways API Client GETs the batch hotel detail endpoint with `idList` and `idType=uuid`.
   - From: `continuumTravelAffiliatesCron_getawaysApiClient`
   - To: `continuumGetawaysApi`
   - Protocol: REST/JSON

10. **Generates feed XML per region**: Hotels Feed Service builds hotel feed XML files, one per region, from the aggregated active hotel data.
    - From: `continuumTravelAffiliatesCron_hotelsFeedService`
    - To: `continuumTravelAffiliatesCron_hotelsFeedJob`
    - Protocol: In-process (file generation)

11. **Uploads feed files to S3**: Hotels Feed Job calls AWS File Upload Service to upload each generated XML file to the configured S3 bucket.
    - From: `continuumTravelAffiliatesCron_hotelsFeedJob`
    - To: `continuumTravelAffiliatesCron_awsFileUploadService`
    - Protocol: In-process call

12. **S3 PutObject**: AWS File Upload Service uses AWS SDK v2 to PUT each feed file to the bucket and prefix specified by `GetawaysAwsBucketConfiguration`.
    - From: `continuumTravelAffiliatesCron_awsFileUploadService`
    - To: `continuumTravelAffiliatesFeedBucket`
    - Protocol: AWS SDK v2 (S3)

13. **Container exits**: After job completion, the container sleeps 30 seconds then exits. Kubernetes marks the job as `Complete`. On failure, Kubernetes applies `restartPolicy: OnFailure` (backoff limit: 0 — no automatic retry).
    - From: `continuumTravelAffiliatesCron_jobRunner`
    - To: Kubernetes
    - Protocol: Container exit code

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Getaways API unavailable during feed generation | Batch detail calls return empty results; logged at ERROR | Feed generated with incomplete data; uploaded to S3 with gaps |
| Deal Catalog API unavailable | Exception propagates through Active Deals Summary Manager | Job fails; no feed uploaded; pod exits with non-zero code |
| S3 upload failure | AWS SDK exception logged; no retry | Feed file not uploaded; stale data remains in S3 |
| OOM or container kill | Pod exits with non-zero code | Kubernetes marks job as failed; no automatic retry (backoffLimit: 0) |
| Container startup failure | Kubernetes marks pod as failed | Alert via cluster monitoring; manual intervention required |

## Sequence Diagram

```
KubernetesCronJob -> JobRunner: Launch container (daily 10:00 UTC)
JobRunner -> JobRunner: Sleep 30s; load CronConfig; detect APP_ENVIRONMENT
JobRunner -> HotelsFeedJob: execute()
HotelsFeedJob -> HotelsFeedService: buildFeed()
HotelsFeedService -> ActiveDealsSummaryManager: getActiveHotels()
ActiveDealsSummaryManager -> DealCatalogApiClient: GET active deal UUIDs
DealCatalogApiClient --> ActiveDealsSummaryManager: deal UUID list
ActiveDealsSummaryManager -> GetawaysApiClient (Cron): getProductSets() [paginated]
GetawaysApiClient (Cron) -> GetawaysApi: GET product sets [repeated per page]
GetawaysApi --> GetawaysApiClient (Cron): ProductSetResponse
GetawaysApiClient (Cron) --> ActiveDealsSummaryManager: List<ProductSet>
ActiveDealsSummaryManager -> GetawaysApiClient (Cron): getHotelDetails(uuids) [batched]
GetawaysApiClient (Cron) -> GetawaysApi: GET batch hotel details [repeated per batch]
GetawaysApi --> GetawaysApiClient (Cron): HotelBatchDetails
GetawaysApiClient (Cron) --> ActiveDealsSummaryManager: hotel metadata
ActiveDealsSummaryManager --> HotelsFeedService: aggregated hotel data
HotelsFeedService --> HotelsFeedJob: feed XML payload (per region)
HotelsFeedJob -> AwsFileUploadService (Cron): upload(feedFile, region)
AwsFileUploadService (Cron) -> S3FeedBucket: PutObject (AWS SDK v2)
S3FeedBucket --> AwsFileUploadService (Cron): success
HotelsFeedJob -> JobRunner: complete
JobRunner -> JobRunner: sleep 30s; exit
```

## Related

- Architecture dynamic view: `dynamic-affiliate-availability-flow`
- Related flows: [Hotel List Feed Generation (On-Demand)](hotel-list-feed-on-demand.md), [Affiliate Hotel Availability Request](affiliate-hotel-availability.md)
