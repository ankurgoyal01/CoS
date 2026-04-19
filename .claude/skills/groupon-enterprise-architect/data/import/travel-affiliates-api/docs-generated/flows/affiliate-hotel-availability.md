---
service: "travel-affiliates-api"
title: "Affiliate Hotel Availability Request"
generated: "2026-03-03"
type: flow
flow_name: "affiliate-hotel-availability"
flow_type: synchronous
trigger: "HTTPS POST from affiliate partner (Google, TripAdvisor, or Trivago)"
participants:
  - "continuumGoogleHotelAds"
  - "continuumTripAdvisor"
  - "continuumSkyscanner"
  - "continuumTravelAffiliatesApi"
  - "continuumTravelAffiliatesApi_hotelAvailabilityApiController"
  - "continuumTravelAffiliatesApi_seoResolver"
  - "continuumTravelAffiliatesApi_userCountryMapper"
  - "continuumTravelAffiliatesApi_getawaysHotelAvailabilityService"
  - "continuumTravelAffiliatesApi_getawaysApiClient"
  - "continuumGetawaysApi"
architecture_ref: "dynamic-affiliate-availability-flow"
---

# Affiliate Hotel Availability Request

## Summary

When an affiliate partner (Google, TripAdvisor, or Trivago) needs to display hotel pricing on their platform, they POST an availability query to `/getaways/v2/affiliates/{partnerSeoName}/hotel_availability`. The Travel Affiliates API resolves the partner identity from the SEO name path parameter, transforms the request into Groupon's internal Getaways API format, fetches availability summaries, and returns a JSON response containing hotel room types with pricing and discount information. This flow is the primary revenue-generating path for the CPC affiliate channel.

## Trigger

- **Type**: api-call
- **Source**: External affiliate partner (Google Hotel Ads, TripAdvisor, or Trivago) sending an HTTPS POST
- **Frequency**: Per-request, on-demand; up to 3000 RPM per SLA

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Affiliate Partner (Google/TripAdvisor/Trivago) | Initiates availability query | `continuumGoogleHotelAds` / `continuumTripAdvisor` / `continuumSkyscanner` |
| Hotel Availability API Controller | Receives and validates request; orchestrates partner pipeline | `continuumTravelAffiliatesApi_hotelAvailabilityApiController` |
| SEO Resolver | Resolves partnerSeoName path param to internal PartnerEnum | `continuumTravelAffiliatesApi_seoResolver` |
| User Country Mapper | Maps user_country and point-of-sale to internal locale and region | `continuumTravelAffiliatesApi_userCountryMapper` |
| Getaways Hotel Availability Service | Transforms partner request and orchestrates Getaways API calls | `continuumTravelAffiliatesApi_getawaysHotelAvailabilityService` |
| Getaways API Client | Executes HTTP call to Getaways availability summary endpoint | `continuumTravelAffiliatesApi_getawaysApiClient` |
| Getaways API | Returns hotel availability data | `continuumGetawaysApi` |

## Steps

1. **Receives availability request**: Affiliate partner POSTs `HotelAvailabilityForm` JSON to `/getaways/v2/affiliates/{partnerSeoName}/hotel_availability`.
   - From: `continuumGoogleHotelAds` / `continuumTripAdvisor` / `continuumSkyscanner`
   - To: `continuumTravelAffiliatesApi_hotelAvailabilityApiController`
   - Protocol: HTTPS/REST

2. **Resolves partner identity**: Controller invokes SEO Resolver to map the `partnerSeoName` path parameter (e.g., `tripadvisor`, `google`) to an internal `PartnerEnum` definition.
   - From: `continuumTravelAffiliatesApi_hotelAvailabilityApiController`
   - To: `continuumTravelAffiliatesApi_seoResolver`
   - Protocol: In-process call

3. **Maps user country to locale**: Controller invokes User Country Mapper to translate the `user_country` field and point-of-sale code to internal locale and region identifiers.
   - From: `continuumTravelAffiliatesApi_hotelAvailabilityApiController`
   - To: `continuumTravelAffiliatesApi_userCountryMapper`
   - Protocol: In-process lookup

4. **Delegates to availability service**: Controller invokes Getaways Hotel Availability Service with the validated and mapped request.
   - From: `continuumTravelAffiliatesApi_hotelAvailabilityApiController`
   - To: `continuumTravelAffiliatesApi_getawaysHotelAvailabilityService`
   - Protocol: In-process call

5. **Fetches availability summaries**: Getaways Hotel Availability Service calls the Getaways API Client to retrieve availability data for the requested hotel list, check-in/out dates, and occupancy.
   - From: `continuumTravelAffiliatesApi_getawaysHotelAvailabilityService`
   - To: `continuumTravelAffiliatesApi_getawaysApiClient`
   - Protocol: In-process call

6. **Queries Getaways API**: Getaways API Client sends a POST to `{getaways_base}/inventory/availabilitySummary` with locale and availability parameters.
   - From: `continuumTravelAffiliatesApi_getawaysApiClient`
   - To: `continuumGetawaysApi`
   - Protocol: REST/JSON over HTTP

7. **Returns availability data**: Getaways API responds with a `GetawayAvailabilityResponse` containing available hotels and room pricing.
   - From: `continuumGetawaysApi`
   - To: `continuumTravelAffiliatesApi_getawaysApiClient`
   - Protocol: REST/JSON

8. **Transforms to partner format**: The availability service applies `GetawaysToInternalTransformation` and partner-specific `AvailabilityFilter` logic to produce a `HotelAvailabilityResponse`.
   - From: `continuumTravelAffiliatesApi_getawaysHotelAvailabilityService`
   - To: `continuumTravelAffiliatesApi_hotelAvailabilityApiController`
   - Protocol: In-process

9. **Returns JSON response**: Controller returns the `HotelAvailabilityResponse` JSON to the affiliate partner.
   - From: `continuumTravelAffiliatesApi_hotelAvailabilityApiController`
   - To: Affiliate partner
   - Protocol: HTTPS/REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Getaways API connection timeout | `ResourceAccessException` caught; `HotelAvailabilityBusyException` thrown | HTTP 5xx returned to partner |
| Getaways API server error | `HttpServerErrorException` re-thrown | HTTP 5xx returned to partner |
| Invalid partner SEO name | SEO Resolver returns null/empty; controller returns error | HTTP 4xx returned to partner |
| Request validation failure | Bean Validation (JSR-303) via Hibernate Validator | HTTP 400 returned to partner |
| GZIP decoding failure | `GZIPRequestFilter` handles malformed compressed bodies | HTTP 400 returned to partner |

## Sequence Diagram

```
Affiliate Partner -> HotelAvailabilityApiController: POST /getaways/v2/affiliates/{partnerSeoName}/hotel_availability
HotelAvailabilityApiController -> SeoResolver: resolvePartner(partnerSeoName)
SeoResolver --> HotelAvailabilityApiController: PartnerEnum
HotelAvailabilityApiController -> UserCountryMapper: mapToLocale(user_country)
UserCountryMapper --> HotelAvailabilityApiController: locale + region
HotelAvailabilityApiController -> GetawaysHotelAvailabilityService: getAvailability(request, partner, locale)
GetawaysHotelAvailabilityService -> GetawaysApiClient: makeGetawaysAvailabilityCall(request)
GetawaysApiClient -> GetawaysApi: POST /inventory/availabilitySummary
GetawaysApi --> GetawaysApiClient: GetawayAvailabilityResponse
GetawaysApiClient --> GetawaysHotelAvailabilityService: GetawayAvailabilityResponse
GetawaysHotelAvailabilityService --> HotelAvailabilityApiController: HotelAvailabilityResponse
HotelAvailabilityApiController --> Affiliate Partner: 200 OK HotelAvailabilityResponse JSON
```

## Related

- Architecture dynamic view: `dynamic-affiliate-availability-flow`
- Related flows: [Google Transaction Query](google-transaction-query.md), [Hotel List Feed Generation](hotel-list-feed-on-demand.md)
