---
service: "travel-affiliates-api"
title: "Google Hotel Ads Transaction Query (Live Query)"
generated: "2026-03-03"
type: flow
flow_name: "google-transaction-query"
flow_type: synchronous
trigger: "HTTPS POST from Google Hotel Ads (Live Query protocol)"
participants:
  - "continuumGoogleHotelAds"
  - "continuumTravelAffiliatesApi_googleTransactionMessageController"
  - "continuumTravelAffiliatesApi_transactionService"
  - "continuumTravelAffiliatesApi_hotelPricingSummaryManager"
  - "continuumTravelAffiliatesApi_hotelBundlesSummaryManager"
  - "continuumTravelAffiliatesApi_userCountryMapper"
  - "continuumTravelAffiliatesApi_xsdValidationService"
  - "continuumTravelAffiliatesApi_getawaysApiClient"
  - "continuumGetawaysApi"
architecture_ref: "dynamic-affiliate-availability-flow"
---

# Google Hotel Ads Transaction Query (Live Query)

## Summary

Google Hotel Ads sends XML-formatted Live Query requests to the Travel Affiliates API asking for real-time hotel pricing for specific properties, check-in dates, and lengths of stay. The service processes the `Query` XML body, requests pricing and bundle data from the Getaways API in parallel, assembles the results into a `Transaction` XML document conforming to Google's published Transaction XSD schema, validates it, and returns the XML response. This flow powers Google Hotel Ads price listings for Groupon Getaways hotels.

## Trigger

- **Type**: api-call
- **Source**: Google Hotel Ads Live Query infrastructure sending HTTPS POST
- **Frequency**: Per-request, on-demand; driven by Google's search traffic patterns

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Google Hotel Ads | Initiates Live Query with XML body | `continuumGoogleHotelAds` |
| Google Transaction Controller | Receives XML query, delegates to Transaction Service | `continuumTravelAffiliatesApi_googleTransactionMessageController` |
| Transaction Service | Coordinates pricing and bundle data collection; builds Transaction XML | `continuumTravelAffiliatesApi_transactionService` |
| Hotel Pricing Summary Manager | Fetches availability-based pricing per property | `continuumTravelAffiliatesApi_hotelPricingSummaryManager` |
| Hotel Bundles Summary Manager | Fetches room bundles for requested hotels | `continuumTravelAffiliatesApi_hotelBundlesSummaryManager` |
| User Country Mapper | Resolves POS locale and user_country | `continuumTravelAffiliatesApi_userCountryMapper` |
| XSD Validation Service | Validates the generated Transaction XML against Google's Transaction XSD | `continuumTravelAffiliatesApi_xsdValidationService` |
| Getaways API Client | Executes HTTP calls to Getaways availability and bundle endpoints | `continuumTravelAffiliatesApi_getawaysApiClient` |
| Getaways API | Returns pricing and bundle data | `continuumGetawaysApi` |

## Steps

1. **Receives Google Live Query**: Google Hotel Ads POSTs a `Query` XML document to `/google/transaction_query`. The request includes `Checkin`, `Nights`, `AffectedNights`, `DeadlineMs`, and `PropertyList`.
   - From: `continuumGoogleHotelAds`
   - To: `continuumTravelAffiliatesApi_googleTransactionMessageController`
   - Protocol: HTTPS, XML body (Google Query XSD)

2. **Parses and validates Query XML**: Controller deserializes the XML body using JAXB-generated `Query` type (from `Query.xsd`). `XSDValidationService` can validate the inbound schema.
   - From: `continuumTravelAffiliatesApi_googleTransactionMessageController`
   - To: `continuumTravelAffiliatesApi_transactionService`
   - Protocol: In-process call

3. **Resolves POS locale**: Transaction Service invokes User Country Mapper to map the request's point-of-sale to the appropriate locale and region for downstream calls.
   - From: `continuumTravelAffiliatesApi_transactionService`
   - To: `continuumTravelAffiliatesApi_userCountryMapper`
   - Protocol: In-process lookup

4. **Collects hotel pricing**: Transaction Service requests pricing summaries from Hotel Pricing Summary Manager for each property in the `PropertyList`.
   - From: `continuumTravelAffiliatesApi_transactionService`
   - To: `continuumTravelAffiliatesApi_hotelPricingSummaryManager`
   - Protocol: In-process call

5. **Queries availability for pricing**: Hotel Pricing Summary Manager calls Getaways API Client with availability request parameters (checkin, nights, property IDs).
   - From: `continuumTravelAffiliatesApi_hotelPricingSummaryManager`
   - To: `continuumTravelAffiliatesApi_getawaysApiClient`
   - Protocol: In-process call

6. **Fetches availability summary**: Getaways API Client POSTs to `{getaways_base}/inventory/availabilitySummary`.
   - From: `continuumTravelAffiliatesApi_getawaysApiClient`
   - To: `continuumGetawaysApi`
   - Protocol: REST/JSON

7. **Collects hotel bundles**: Transaction Service requests room bundle data from Hotel Bundles Summary Manager.
   - From: `continuumTravelAffiliatesApi_transactionService`
   - To: `continuumTravelAffiliatesApi_hotelBundlesSummaryManager`
   - Protocol: In-process call

8. **Fetches hotel bundles**: Hotel Bundles Summary Manager calls Getaways API Client's `makeGetawaysHotelBundlesCall()` method with hotel UUIDs, POS, and locale.
   - From: `continuumTravelAffiliatesApi_hotelBundlesSummaryManager`
   - To: `continuumTravelAffiliatesApi_getawaysApiClient`
   - Protocol: In-process call

9. **Queries bundle endpoint**: Getaways API Client GETs `{getaways_base}/hotel/bundles/detail` with `hotelUUIDs`, `pointOfSale`, and `locale` parameters.
   - From: `continuumTravelAffiliatesApi_getawaysApiClient`
   - To: `continuumGetawaysApi`
   - Protocol: REST/JSON

10. **Assembles Transaction XML**: Transaction Service combines pricing and bundle data into a JAXB `Transaction` object using `GoogleBundleAdapter` and `GooglePriceAdapter`.
    - From: `continuumTravelAffiliatesApi_transactionService`
    - To: `continuumTravelAffiliatesApi_xsdValidationService`
    - Protocol: In-process

11. **Validates Transaction XML**: XSD Validation Service validates the assembled `Transaction` XML against `Transaction.xsd`.
    - From: `continuumTravelAffiliatesApi_xsdValidationService`
    - To: `continuumTravelAffiliatesApi_googleTransactionMessageController`
    - Protocol: In-process

12. **Returns Transaction XML**: Controller serializes and returns the `Transaction` XML response to Google.
    - From: `continuumTravelAffiliatesApi_googleTransactionMessageController`
    - To: `continuumGoogleHotelAds`
    - Protocol: HTTPS, XML (Google Transaction XSD)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Getaways API timeout | `HotelAvailabilityBusyException` thrown by API client | HTTP 5xx returned to Google; Google retries |
| Bundle API unavailable | `makeGetawaysHotelBundlesCall()` returns null on exception; logged | Transaction XML returned with missing bundle data |
| XSD validation failure | `CustomValidationErrorHandler` logs violation | HTTP 5xx or empty Transaction returned |
| `DeadlineMs` exceeded | Deadline is tracked; response may be partial | Transaction returned with available data only |

## Sequence Diagram

```
GoogleHotelAds -> GoogleTransactionController: POST /google/transaction_query (Query XML)
GoogleTransactionController -> TransactionService: processQuery(Query)
TransactionService -> UserCountryMapper: mapToLocale(pos)
TransactionService -> HotelPricingSummaryManager: getPricing(properties, checkin, nights)
HotelPricingSummaryManager -> GetawaysApiClient: makeGetawaysAvailabilityCall(request)
GetawaysApiClient -> GetawaysApi: POST /inventory/availabilitySummary
GetawaysApi --> GetawaysApiClient: GetawayAvailabilityResponse
GetawaysApiClient --> HotelPricingSummaryManager: pricing data
HotelPricingSummaryManager --> TransactionService: pricing summaries
TransactionService -> HotelBundlesSummaryManager: getBundles(hotelUUIDs, pos, locale)
HotelBundlesSummaryManager -> GetawaysApiClient: makeGetawaysHotelBundlesCall(hotelUUIDs, pos, locale)
GetawaysApiClient -> GetawaysApi: GET /hotel/bundles/detail
GetawaysApi --> GetawaysApiClient: GetawaysHotelBundleResponse
GetawaysApiClient --> HotelBundlesSummaryManager: bundle data
HotelBundlesSummaryManager --> TransactionService: bundle summaries
TransactionService -> XsdValidationService: validate(Transaction XML)
XsdValidationService --> TransactionService: valid
TransactionService --> GoogleTransactionController: Transaction XML
GoogleTransactionController --> GoogleHotelAds: 200 OK Transaction XML
```

## Related

- Architecture dynamic view: `dynamic-affiliate-availability-flow`
- Related flows: [Affiliate Hotel Availability Request](affiliate-hotel-availability.md), [Hotel List Feed Generation](hotel-list-feed-on-demand.md)
