---
service: "tripadvisor-api"
title: "Google Hotel List Feed"
generated: "2026-03-03"
type: flow
flow_name: "google-hotel-list-feed"
flow_type: synchronous
trigger: "POST /google/hotel_list_feed from Google Hotel Ads"
participants:
  - "continuumGoogleHotelAds"
  - "continuumTripadvisorApiV1Webapp"
  - "googleHotelListFeedController"
  - "remoteGetawaysApiClient"
  - "getawaysContentApi"
architecture_ref: "dynamic-google-hotel-list-feed"
---

# Google Hotel List Feed

## Summary

Google Hotel Ads requests a complete list of Groupon Getaways hotel properties via the hotel list feed endpoint. The service fetches all live product sets from the Getaways Content API, transforms them into the Google hotel list feed format (CSV or XML), and returns the feed to Google. Google uses this feed to build and maintain its index of bookable properties offered through Groupon's Google Hotel Ads partnership.

## Trigger

- **Type**: api-call
- **Source**: `continuumGoogleHotelAds` (Google Hotel Ads integration)
- **Frequency**: On demand; typically periodic polling by Google

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Google Hotel Ads | Requests hotel property list | `continuumGoogleHotelAds` |
| TripAdvisor API v1 Webapp | Receives request and coordinates response | `continuumTripadvisorApiV1Webapp` |
| Google Hotel List Feed Controller | Request routing and feed assembly | `googleHotelListFeedController` |
| Remote Getaways API Client | HTTP client fetching product sets from Content API | `remoteGetawaysApiClient` |
| Getaways Content API | Source of hotel product set data | `getawaysContentApi` |

## Steps

1. **Receives hotel list feed request**: Google Hotel Ads sends `POST /google/hotel_list_feed` to the service.
   - From: `continuumGoogleHotelAds`
   - To: `googleHotelListFeedController`
   - Protocol: HTTPS

2. **Fetches hotel product sets**: Controller delegates to `remoteGetawaysApiClient`, which pages through the Getaways Content API product sets endpoint (`http://getaways-content-app-vip/v2/getaways/content/product_sets`) requesting up to 100 live products per page using `X-GRPN-Groups` authorization.
   - From: `googleHotelListFeedController`
   - To: `remoteGetawaysApiClient`
   - Protocol: direct

3. **Calls Getaways Content API**: Client issues paginated HTTP requests to retrieve all live hotel product sets.
   - From: `remoteGetawaysApiClient`
   - To: `getawaysContentApi`
   - Protocol: HTTP (internal VIP)

4. **Transforms product sets to feed format**: Controller adapts product set data using `GoogleBundleAdapter` or `GooglePriceAdapter` into the Google hotel list feed format (CSV via `super-csv` library, or string output per Swagger spec).
   - From: `googleHotelListFeedController`
   - To: `googleHotelListFeedController` (internal)
   - Protocol: direct

5. **Returns hotel list feed**: Controller returns the assembled feed as the response body (content type string / CSV).
   - From: `googleHotelListFeedController`
   - To: `continuumGoogleHotelAds`
   - Protocol: HTTPS

A JSON variant is available at `GET /google/hotel_list_feed_json` (the `GOOGLE_HOTEL_LIST_JSON` constant) for non-XML consumers or debugging.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Getaways Content API unavailable | HTTP error propagated; empty or partial feed | Google receives empty feed or HTTP error |
| Paginated content fetch incomplete | Partial product set list assembled | Partial hotel list returned to Google (Google may retry) |
| Connection timeout (5s) | Async HTTP client timeout | Partial or empty feed |

## Sequence Diagram

```
continuumGoogleHotelAds -> googleHotelListFeedController: POST /google/hotel_list_feed
googleHotelListFeedController -> remoteGetawaysApiClient: Fetch all live product sets
remoteGetawaysApiClient -> getawaysContentApi: GET /v2/getaways/content/product_sets (page 1..N, limit=100, status=live)
getawaysContentApi --> remoteGetawaysApiClient: Product set pages
remoteGetawaysApiClient --> googleHotelListFeedController: Aggregated product sets
googleHotelListFeedController -> googleHotelListFeedController: Transform to Google feed format (CSV/string)
googleHotelListFeedController --> continuumGoogleHotelAds: Hotel list feed response
```

## Related

- Architecture dynamic view: `dynamic-google-hotel-list-feed` (not yet defined in `architecture/views/dynamics.dsl`)
- Related flows: [Google Transaction Query](google-transaction-query.md), [Google Query Control Message](google-query-control-message.md)
- Google Hotel Ad No-Bid script: `scripts/GoogleHotelAdNoBid/` — standalone script for managing no-bid hotel lists in Google Ads
