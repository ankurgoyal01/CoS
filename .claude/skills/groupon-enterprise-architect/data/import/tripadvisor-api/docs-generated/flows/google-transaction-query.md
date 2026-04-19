---
service: "tripadvisor-api"
title: "Google Transaction Query"
generated: "2026-03-03"
type: flow
flow_name: "google-transaction-query"
flow_type: synchronous
trigger: "POST /google/transaction_query from Google Hotel Ads with XML Query document"
participants:
  - "continuumGoogleHotelAds"
  - "continuumTripadvisorApiV1Webapp"
  - "googleTransactionMessageController"
  - "hotelPricingSummaryManager"
  - "hotelBundlesSummaryManager"
  - "xsdValidationService"
  - "remoteGetawaysApiClient"
  - "getawaysSearchApi"
  - "getawaysContentApi"
architecture_ref: "dynamic-google-transaction-query"
---

# Google Transaction Query

## Summary

Google Hotel Ads sends periodic pricing queries to the service via an XML Query document conforming to the Google Hotel Ads schema. The service parses the XML query, validates it against the XSD schema, fetches hotel pricing and room bundle data from the Getaways APIs, and returns a Google-formatted Transaction XML document. This flow provides Google with live pricing data used to populate Google Hotel Ads pricing panels.

## Trigger

- **Type**: api-call
- **Source**: `continuumGoogleHotelAds` (Google Hotel Ads integration)
- **Frequency**: On demand; frequency driven by Google's query cadence

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Google Hotel Ads | Sends XML pricing query | `continuumGoogleHotelAds` |
| TripAdvisor API v1 Webapp | Receives request and coordinates response | `continuumTripadvisorApiV1Webapp` |
| Google Transaction Message Controller | Request routing, XML binding, response assembly | `googleTransactionMessageController` |
| Hotel Pricing Summary Manager | Builds per-property pricing for Transaction response | `hotelPricingSummaryManager` |
| Hotel Bundles Summary Manager | Builds room bundle payloads for Transaction response | `hotelBundlesSummaryManager` |
| XSD Validation Service | Validates inbound Query XML and outbound Transaction XML | `xsdValidationService` |
| Remote Getaways API Client | HTTP client for upstream Getaways calls | `remoteGetawaysApiClient` |
| Getaways Search API | Provides real-time hotel pricing | `getawaysSearchApi` |
| Getaways Content API | Provides hotel detail for bundle enrichment | `getawaysContentApi` |

## Steps

1. **Receives Google Query XML**: Google Hotel Ads sends `POST /google/transaction_query` with an XML `Query` document body (JAXB-generated `Query` type; header `x-request-id` required).
   - From: `continuumGoogleHotelAds`
   - To: `googleTransactionMessageController`
   - Protocol: HTTPS

2. **Validates inbound XML against XSD**: `XSDValidationService` validates the received `Query` XML against `xsd/Query.xsd` generated schema.
   - From: `googleTransactionMessageController`
   - To: `xsdValidationService`
   - Protocol: direct

3. **Builds pricing data**: Controller instructs `hotelPricingSummaryManager` to fetch pricing for each property listed in the Query's `PropertyList`.
   - From: `googleTransactionMessageController`
   - To: `hotelPricingSummaryManager`
   - Protocol: direct

4. **Builds room bundle data**: Controller instructs `hotelBundlesSummaryManager` to fetch room bundle payloads for each property.
   - From: `googleTransactionMessageController`
   - To: `hotelBundlesSummaryManager`
   - Protocol: direct

5. **Queries Getaways Search API**: Pricing and bundle managers call `remoteGetawaysApiClient` which issues HTTP requests to `http://getaways-search-app-vip/getaways/v2/search` with date ranges from the Query document.
   - From: `remoteGetawaysApiClient`
   - To: `getawaysSearchApi`
   - Protocol: HTTP (internal VIP)

6. **Queries Getaways Content API**: Client fetches hotel detail batch for bundle enrichment from `http://getaways-content-app-vip/v2/getaways/content/hotelDetailBatch`.
   - From: `remoteGetawaysApiClient`
   - To: `getawaysContentApi`
   - Protocol: HTTP (internal VIP)

7. **Assembles Transaction XML**: Controller builds a `Transaction` XML document (JAXB-generated type) with `Result` entries per property, containing `Baserate`, `Tax`, `OtherFees`, `Refundable`, and `RoomBundle` elements.
   - From: `googleTransactionMessageController`
   - To: `googleTransactionMessageController` (internal assembly)
   - Protocol: direct

8. **Validates outbound Transaction XML**: `XSDValidationService` validates the assembled `Transaction` XML against `xsd/Transaction.xsd`.
   - From: `googleTransactionMessageController`
   - To: `xsdValidationService`
   - Protocol: direct

9. **Returns Transaction XML response**: Controller returns the serialized `Transaction` XML to Google Hotel Ads.
   - From: `googleTransactionMessageController`
   - To: `continuumGoogleHotelAds`
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| XSD validation failure (inbound) | Validation error returned before processing | HTTP 400 or error document returned |
| Getaways API unavailable | `HotelAvailabilityException` propagates; empty Transaction returned | Empty Transaction XML (no results) |
| XSD validation failure (outbound) | Logged; degraded response may be returned | Partial Transaction XML |
| Connection timeout (5s) | Async HTTP client times out; empty result | Empty Transaction XML |

## Sequence Diagram

```
continuumGoogleHotelAds -> googleTransactionMessageController: POST /google/transaction_query (XML Query)
googleTransactionMessageController -> xsdValidationService: Validate Query XML
xsdValidationService --> googleTransactionMessageController: Valid
googleTransactionMessageController -> hotelPricingSummaryManager: Build pricing
googleTransactionMessageController -> hotelBundlesSummaryManager: Build bundles
hotelPricingSummaryManager -> remoteGetawaysApiClient: Fetch pricing
hotelBundlesSummaryManager -> remoteGetawaysApiClient: Fetch bundles
remoteGetawaysApiClient -> getawaysSearchApi: POST /getaways/v2/search
getawaysSearchApi --> remoteGetawaysApiClient: Availability data
remoteGetawaysApiClient -> getawaysContentApi: GET /v2/getaways/content/hotelDetailBatch
getawaysContentApi --> remoteGetawaysApiClient: Hotel details
remoteGetawaysApiClient --> hotelPricingSummaryManager: Pricing summary
remoteGetawaysApiClient --> hotelBundlesSummaryManager: Bundle summary
googleTransactionMessageController -> googleTransactionMessageController: Assemble Transaction XML
googleTransactionMessageController -> xsdValidationService: Validate Transaction XML
xsdValidationService --> googleTransactionMessageController: Valid
googleTransactionMessageController --> continuumGoogleHotelAds: Transaction XML response
```

## Related

- Architecture dynamic view: `dynamic-google-transaction-query` (not yet defined in `architecture/views/dynamics.dsl`)
- Related flows: [Partner Hotel Availability](partner-hotel-availability.md), [Google Query Control Message](google-query-control-message.md)
- Google Transaction XSD: `ta-api-v1/src/main/resources/xsd/Transaction.xsd`
- Google Query XSD: `ta-api-v1/src/main/resources/xsd/Query.xsd`
