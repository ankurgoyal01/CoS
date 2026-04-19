---
service: "tripadvisor-api"
title: "Partner Hotel Availability"
generated: "2026-03-03"
type: flow
flow_name: "partner-hotel-availability"
flow_type: synchronous
trigger: "POST /{partnerSeoName}/hotel_availability from TripAdvisor or Trivago partner"
participants:
  - "tripadvisorPartner or trivagoPartner"
  - "continuumTripadvisorApiV1Webapp"
  - "hotelAvailabilityApiController"
  - "getawaysHotelAvailabilityService"
  - "hotelPricingSummaryManager"
  - "hotelBundlesSummaryManager"
  - "remoteGetawaysApiClient"
  - "getawaysSearchApi"
  - "getawaysContentApi"
architecture_ref: "dynamic-partner-hotel-availability"
---

# Partner Hotel Availability

## Summary

When a CPC partner (TripAdvisor or Trivago) requests hotel availability, this service receives the partner-keyed request, resolves the partner identity, fetches real-time availability from the internal Getaways Search API, enriches with pricing and room bundle data from the Getaways Content API, and returns a partner-formatted JSON availability response. The flow is entirely synchronous with a target end-to-end latency of under 500 ms for up to 10 hotels.

## Trigger

- **Type**: api-call
- **Source**: TripAdvisor or Trivago partner system (external)
- **Frequency**: On demand; up to 3000 RPM per SLA

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| TripAdvisor / Trivago Partner | Initiates availability request | `tripadvisorPartner` / `trivagoPartner` (stubs) |
| TripAdvisor API v1 Webapp | Receives, dispatches, and responds to request | `continuumTripadvisorApiV1Webapp` |
| Hotel Availability API Controller | Request routing and partner resolution | `hotelAvailabilityApiController` |
| Getaways Hotel Availability Service | Orchestrates availability fetch and transformation | `getawaysHotelAvailabilityService` |
| Hotel Pricing Summary Manager | Aggregates per-hotel pricing | `hotelPricingSummaryManager` |
| Hotel Bundles Summary Manager | Aggregates room bundle data | `hotelBundlesSummaryManager` |
| Remote Getaways API Client | Issues HTTP calls to downstream APIs | `remoteGetawaysApiClient` |
| Getaways Search API | Provides real-time hotel availability | `getawaysSearchApi` |
| Getaways Content API | Provides hotel product set and detail content | `getawaysContentApi` |

## Steps

1. **Receives availability request**: Partner sends `POST /{partnerSeoName}/hotel_availability?hotels={hotel_ids}` with `HotelAvailabilityForm` JSON body.
   - From: `tripadvisorPartner` or `trivagoPartner`
   - To: `hotelAvailabilityApiController`
   - Protocol: HTTPS

2. **Resolves partner identity**: Controller resolves `partnerSeoName` to a `PartnerEnum` value (`tripadvisor` or `trivago`) using the `SeoResolver` bean. Resolves `user_country` to a `UserCountry` with region code using `UserCountryMapper`.
   - From: `hotelAvailabilityApiController`
   - To: `hotelAvailabilityApiController` (internal resolution)
   - Protocol: direct

3. **Translates request to internal form**: Adapts `HotelAvailabilityForm` + hotel ID list + partner + user country into a `HotelAvailabilityDetails` internal request object via `TransformUtils.ADAPTER.toInternal(...)`.
   - From: `hotelAvailabilityApiController`
   - To: `getawaysHotelAvailabilityService`
   - Protocol: direct

4. **Fetches availability**: Availability service calls pricing summary and bundle summary managers in parallel or sequence to collect per-hotel availability data.
   - From: `getawaysHotelAvailabilityService`
   - To: `hotelPricingSummaryManager`, `hotelBundlesSummaryManager`
   - Protocol: direct

5. **Queries Getaways Search API**: Pricing and bundle managers call the remote client, which issues `HTTP POST` to `http://getaways-search-app-vip/getaways/v2/search` with hotel IDs, check-in/out dates, party composition, and currency.
   - From: `remoteGetawaysApiClient`
   - To: `getawaysSearchApi`
   - Protocol: HTTP (internal VIP)

6. **Queries Getaways Content API (product sets)**: Client fetches product sets from `http://getaways-content-app-vip/v2/getaways/content/product_sets` (up to 100 per page, `live` status, using `X-GRPN-Groups` auth header).
   - From: `remoteGetawaysApiClient`
   - To: `getawaysContentApi`
   - Protocol: HTTP (internal VIP)

7. **Queries Getaways Content API (batch hotel detail)**: Client fetches batch hotel detail for enrichment from `http://getaways-content-app-vip/v2/getaways/content/hotelDetailBatch`.
   - From: `remoteGetawaysApiClient`
   - To: `getawaysContentApi`
   - Protocol: HTTP (internal VIP)

8. **Filters hotels by partner rules**: Partner-specific `filterHotels()` method removes hotels that do not meet partner eligibility criteria.
   - From: `hotelAvailabilityApiController`
   - To: `hotelAvailabilityApiController` (internal)
   - Protocol: direct

9. **Transforms response to partner format**: `TransformUtils.ADAPTER.fromInternal(...)` converts `AvailableHotel` list and request parameters into a `HotelAvailabilityResponse` JSON payload.
   - From: `hotelAvailabilityApiController`
   - To: `hotelAvailabilityApiController` (internal)
   - Protocol: direct

10. **Returns availability response**: Controller returns JSON `HotelAvailabilityResponse` to the partner.
    - From: `hotelAvailabilityApiController`
    - To: `tripadvisorPartner` or `trivagoPartner`
    - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unknown `partnerSeoName` | `handleUnknownPartnerException` — returns 404 | Partner receives HTTP 404 Not Found |
| Invalid request parameters | `handleIllegalArgumentException` — returns 400 | Partner receives HTTP 400 Bad Request |
| `HotelAvailabilityException` from Getaways API | Caught in controller; adapts to empty `HotelAvailabilityResponse` | Partner receives empty hotel list (no error code) |
| `URISyntaxException` building upstream URL | Caught in controller; returns empty hotel list; logs error | Partner receives empty hotel list |
| Unexpected exception | `handleException` — sets HTTP 500 and rethrows | Partner receives HTTP 500; error logged with request details |
| Getaways API connection timeout | Triggers after 5 seconds; raises `HotelAvailabilityException` | Empty hotel list returned |

## Sequence Diagram

```
Partner -> hotelAvailabilityApiController: POST /{partnerSeoName}/hotel_availability
hotelAvailabilityApiController -> hotelAvailabilityApiController: Resolve partner + user country
hotelAvailabilityApiController -> getawaysHotelAvailabilityService: getAvailability(request, partner)
getawaysHotelAvailabilityService -> hotelPricingSummaryManager: Aggregate pricing
getawaysHotelAvailabilityService -> hotelBundlesSummaryManager: Aggregate bundles
hotelPricingSummaryManager -> remoteGetawaysApiClient: Fetch pricing data
hotelBundlesSummaryManager -> remoteGetawaysApiClient: Fetch bundle data
remoteGetawaysApiClient -> getawaysSearchApi: POST /getaways/v2/search
getawaysSearchApi --> remoteGetawaysApiClient: Availability data
remoteGetawaysApiClient -> getawaysContentApi: GET /v2/getaways/content/product_sets
getawaysContentApi --> remoteGetawaysApiClient: Product sets
remoteGetawaysApiClient -> getawaysContentApi: GET /v2/getaways/content/hotelDetailBatch
getawaysContentApi --> remoteGetawaysApiClient: Hotel details
remoteGetawaysApiClient --> hotelPricingSummaryManager: Pricing summary
remoteGetawaysApiClient --> hotelBundlesSummaryManager: Bundle summary
getawaysHotelAvailabilityService --> hotelAvailabilityApiController: List<AvailableHotel>
hotelAvailabilityApiController -> hotelAvailabilityApiController: filterHotels + transform response
hotelAvailabilityApiController --> Partner: HotelAvailabilityResponse (JSON)
```

## Related

- Architecture dynamic view: `dynamic-partner-hotel-availability` (not yet defined in `architecture/views/dynamics.dsl`)
- Related flows: [Google Transaction Query](google-transaction-query.md), [Google Hotel List Feed](google-hotel-list-feed.md)
- See [API Surface](../api-surface.md) for full endpoint documentation
- See [Integrations](../integrations.md) for upstream dependency details
