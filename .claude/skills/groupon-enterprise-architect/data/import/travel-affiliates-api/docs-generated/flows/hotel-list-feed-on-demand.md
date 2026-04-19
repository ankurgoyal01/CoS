---
service: "travel-affiliates-api"
title: "Hotel List Feed Generation (On-Demand)"
generated: "2026-03-03"
type: flow
flow_name: "hotel-list-feed-on-demand"
flow_type: synchronous
trigger: "HTTPS GET from Google Hotel Ads or internal trigger to /google/hotel_list_feed_json or /getaways/v2/feed"
participants:
  - "continuumGoogleHotelAds"
  - "continuumTravelAffiliatesApi_googleHotelListFeedController"
  - "continuumTravelAffiliatesApi_hotelFeedController"
  - "continuumTravelAffiliatesApi_activeDealsSummaryManager"
  - "continuumTravelAffiliatesApi_dealCatalogApiClient"
  - "continuumTravelAffiliatesApi_getawaysApiClient"
  - "continuumTravelAffiliatesApi_countryNameToISOCodeMapper"
  - "continuumTravelAffiliatesApi_hotelsFeedService"
  - "continuumTravelAffiliatesApi_awsFileUploadService"
  - "continuumTravelAffiliatesApi_getawaysAwsBucketConfiguration"
  - "continuumGetawaysApi"
  - "continuumTravelAffiliatesFeedBucket"
architecture_ref: "dynamic-affiliate-availability-flow"
---

# Hotel List Feed Generation (On-Demand)

## Summary

Google Hotel Ads requires a hotel list feed to know which properties Groupon Getaways offers. This flow is triggered either by Google fetching the JSON feed directly from `/google/hotel_list_feed_json`, or by an internal on-demand trigger to `/getaways/v2/feed` that generates XML feed files and uploads them to S3. In both cases, the service aggregates active Getaways hotel deals from the Deal Catalog API and enriches them with hotel metadata from the Getaways content API. The JSON variant returns results immediately; the XML variant persists generated files to S3.

## Trigger

- **Type**: api-call
- **Source**: Google Hotel Ads fetching hotel list feed, or internal operator triggering feed file generation
- **Frequency**: On-demand; also executed daily by the scheduled cron flow

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Google Hotel Ads | Fetches hotel list feed | `continuumGoogleHotelAds` |
| Google Hotel List Feed Controller | Serves JSON hotel list feed directly | `continuumTravelAffiliatesApi_googleHotelListFeedController` |
| Hotel Feed Controller | Triggers XML feed generation and S3 upload | `continuumTravelAffiliatesApi_hotelFeedController` |
| Active Deals Summary Manager | Aggregates active deal UUIDs and hotel metadata | `continuumTravelAffiliatesApi_activeDealsSummaryManager` |
| Deal Catalog API Client | Fetches active deal UUIDs and regional mappings | `continuumTravelAffiliatesApi_dealCatalogApiClient` |
| Getaways API Client | Fetches product sets and batch hotel details | `continuumTravelAffiliatesApi_getawaysApiClient` |
| Country Name to ISO Code Mapper | Normalizes country names to ISO codes | `continuumTravelAffiliatesApi_countryNameToISOCodeMapper` |
| Hotels Feed Service | Generates hotel feed XML from aggregated hotel data | `continuumTravelAffiliatesApi_hotelsFeedService` |
| AWS File Upload Service | Uploads generated XML feed files to S3 | `continuumTravelAffiliatesApi_awsFileUploadService` |
| Getaways AWS Bucket Configuration | Provides bucket name, region, and prefix | `continuumTravelAffiliatesApi_getawaysAwsBucketConfiguration` |
| Getaways API | Returns product sets and hotel detail data | `continuumGetawaysApi` |
| Travel Affiliates S3 Feed Bucket | Persists generated feed files | `continuumTravelAffiliatesFeedBucket` |

## Steps

### Path A: JSON Feed (GET /google/hotel_list_feed_json)

1. **Receives hotel list feed request**: Google Hotel Ads GETs `/google/hotel_list_feed_json`.
   - From: `continuumGoogleHotelAds`
   - To: `continuumTravelAffiliatesApi_googleHotelListFeedController`
   - Protocol: HTTPS

2. **Requests active hotel aggregation**: Google Hotel List Feed Controller invokes Active Deals Summary Manager to build the hotel list.
   - From: `continuumTravelAffiliatesApi_googleHotelListFeedController`
   - To: `continuumTravelAffiliatesApi_activeDealsSummaryManager`
   - Protocol: In-process call

3. **Fetches active deal UUIDs**: Active Deals Summary Manager calls Deal Catalog API Client to retrieve active deal UUIDs and their regional mappings.
   - From: `continuumTravelAffiliatesApi_activeDealsSummaryManager`
   - To: `continuumTravelAffiliatesApi_dealCatalogApiClient`
   - Protocol: In-process → REST/JSON

4. **Fetches product sets**: Active Deals Summary Manager calls Getaways API Client's `getProductSets()`, paginating through all active deals using `offset` and `count`.
   - From: `continuumTravelAffiliatesApi_activeDealsSummaryManager`
   - To: `continuumTravelAffiliatesApi_getawaysApiClient`
   - Protocol: In-process call

5. **Queries Getaways product sets endpoint**: Getaways API Client GETs the product sets endpoint with `limit`, `status_list`, and `offset` parameters; uses `Authorization` header.
   - From: `continuumTravelAffiliatesApi_getawaysApiClient`
   - To: `continuumGetawaysApi`
   - Protocol: REST/JSON

6. **Fetches batch hotel details**: Active Deals Summary Manager calls Getaways API Client's `getHotelDetails()` with hotel UUID lists, batched by `getaways.api.content.batchhoteldetail.batchsize`.
   - From: `continuumTravelAffiliatesApi_activeDealsSummaryManager`
   - To: `continuumTravelAffiliatesApi_getawaysApiClient`
   - Protocol: In-process call

7. **Queries batch hotel detail endpoint**: Getaways API Client GETs the batch hotel detail endpoint with `idList` and `idType=uuid` parameters.
   - From: `continuumTravelAffiliatesApi_getawaysApiClient`
   - To: `continuumGetawaysApi`
   - Protocol: REST/JSON

8. **Normalizes country codes**: Active Deals Summary Manager passes raw country names through Country Name to ISO Code Mapper.
   - From: `continuumTravelAffiliatesApi_activeDealsSummaryManager`
   - To: `continuumTravelAffiliatesApi_countryNameToISOCodeMapper`
   - Protocol: In-process lookup

9. **Returns HotelDetails array**: Google Hotel List Feed Controller returns the JSON array of `HotelDetails` objects to Google.
   - From: `continuumTravelAffiliatesApi_googleHotelListFeedController`
   - To: `continuumGoogleHotelAds`
   - Protocol: HTTPS, JSON

### Path B: XML Feed Generation and S3 Upload (on-demand trigger)

Steps 1-8 are the same as Path A, substituting `HotelFeedController` and `HotelsFeedService`.

9. **Generates feed XML**: Hotels Feed Service generates hotel feed XML files from the aggregated hotel data.
   - From: `continuumTravelAffiliatesApi_hotelsFeedService`
   - To: `continuumTravelAffiliatesApi_awsFileUploadService`
   - Protocol: In-process call

10. **Resolves bucket configuration**: AWS File Upload Service reads bucket name, prefix, and region from Getaways AWS Bucket Configuration.
    - From: `continuumTravelAffiliatesApi_awsFileUploadService`
    - To: `continuumTravelAffiliatesApi_getawaysAwsBucketConfiguration`
    - Protocol: In-process

11. **Uploads to S3**: AWS File Upload Service uploads each generated XML file to the configured S3 bucket using AWS SDK v2.
    - From: `continuumTravelAffiliatesApi_awsFileUploadService`
    - To: `continuumTravelAffiliatesFeedBucket`
    - Protocol: AWS SDK v2 (S3 PutObject)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal Catalog API unavailable | No evidence of explicit fallback; exception propagates | HTTP 5xx returned; no feed generated |
| Getaways product sets pagination failure | Partial product set list used for remaining steps | Feed generated with incomplete hotel list |
| Hotel batch detail call failure | Results from failed batches omitted | Feed generated with partial hotel metadata |
| S3 upload failure | Exception logged; no retry configured | Feed file not uploaded; must re-trigger manually |

## Sequence Diagram

```
GoogleHotelAds -> GoogleHotelListFeedController: GET /google/hotel_list_feed_json
GoogleHotelListFeedController -> ActiveDealsSummaryManager: getActiveDealHotels()
ActiveDealsSummaryManager -> DealCatalogApiClient: GET active deal UUIDs
DealCatalogApiClient --> ActiveDealsSummaryManager: deal UUID list
ActiveDealsSummaryManager -> GetawaysApiClient: getProductSets() [paginated]
GetawaysApiClient -> GetawaysApi: GET product sets endpoint
GetawaysApi --> GetawaysApiClient: ProductSetResponse (paginated)
GetawaysApiClient --> ActiveDealsSummaryManager: List<ProductSet>
ActiveDealsSummaryManager -> GetawaysApiClient: getHotelDetails(hotelUUIDs) [batched]
GetawaysApiClient -> GetawaysApi: GET batch hotel detail endpoint
GetawaysApi --> GetawaysApiClient: HotelBatchDetails
GetawaysApiClient --> ActiveDealsSummaryManager: hotel metadata
ActiveDealsSummaryManager -> CountryNameToISOCodeMapper: normalize(countryName)
CountryNameToISOCodeMapper --> ActiveDealsSummaryManager: ISO code
ActiveDealsSummaryManager --> GoogleHotelListFeedController: List<HotelDetails>
GoogleHotelListFeedController --> GoogleHotelAds: 200 OK JSON array of HotelDetails
```

## Related

- Architecture dynamic view: `dynamic-affiliate-availability-flow`
- Related flows: [Scheduled Hotel Feed Export (Cron)](scheduled-hotel-feed-export.md), [Affiliate Hotel Availability Request](affiliate-hotel-availability.md)
