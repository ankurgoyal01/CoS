---
service: "forex-ng"
title: "Rate Query (API Lookup)"
generated: "2026-03-03"
type: flow
flow_name: "rate-query"
flow_type: synchronous
trigger: "Incoming HTTP GET to /v1/rates/{currency}.json"
participants:
  - "continuumForexService_ratesApiResource"
  - "continuumForexService_forexService"
  - "continuumForexService_rateStoreAdapter"
  - "continuumForexService_s3StorageClient"
  - "continuumForexS3Bucket"
architecture_ref: "dynamic-forex-refresh-rates"
---

# Rate Query (API Lookup)

## Summary

An internal Groupon service (consumer) calls `GET /v1/rates/{currency}.json` to retrieve the current exchange rates for a given ISO 4217 base currency or base/quote currency pair. The Forex NG service validates the currency code format, reads the corresponding JSON rate file directly from AWS S3, and returns it as an HTTP 200 response. No computation is performed — the response is the pre-serialized `ForexRate` object stored in S3 during the most recent rate refresh.

## Trigger

- **Type**: api-call
- **Source**: Internal Groupon service (HTTP client)
- **Frequency**: On-demand per request; rate depends on consumer call patterns

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Internal Consumer | Issues the HTTP GET request | External to this service |
| Rates API Resource | Receives and validates the HTTP request; delegates to service layer | `continuumForexService_ratesApiResource` |
| Forex Service | Retrieves conversion rate from the data store | `continuumForexService_forexService` |
| Rate Store Adapter | Selects the appropriate store and reads the rate | `continuumForexService_rateStoreAdapter` |
| AWS S3 Storage Client | Executes the async S3 GetObject operation | `continuumForexService_s3StorageClient` |
| Forex Rates S3 Bucket | Returns the stored rate JSON file | `continuumForexS3Bucket` |

## Steps

1. **Receive HTTP request**: Consumer sends `GET /v1/rates/{currencyCode}.json` to the service.
   - From: Internal consumer
   - To: `continuumForexService_ratesApiResource`
   - Protocol: HTTP

2. **Validate currency code format**: The Rates API Resource splits the path on `.`, verifies the extension is `json`, and matches the currency portion against regex `[A-Za-z]{6}|[A-Za-z]{3}`. If invalid, returns HTTP 400 immediately.
   - From: `continuumForexService_ratesApiResource`
   - To: (internal validation, no external call)
   - Protocol: Direct

3. **Delegate to service layer**: Calls `ForexService.getConversionRate(currencyCode)` with the validated 3- or 6-character currency string.
   - From: `continuumForexService_ratesApiResource`
   - To: `continuumForexService_forexService`
   - Protocol: Direct (Java)

4. **Read from data store**: `ForexServiceImpl` calls `ForexRateStore.getConversionRate(currencyCode)`, which routes to `AWSS3ForexStore` in production.
   - From: `continuumForexService_forexService`
   - To: `continuumForexService_rateStoreAdapter`
   - Protocol: Direct (Java)

5. **Fetch rate file from S3**: `AWSS3ForexStore` calls `AWSS3Client.read("v1/rates/{currencyCode}.json")`, which issues an async `S3AsyncClient.getObject()` request.
   - From: `continuumForexService_s3StorageClient`
   - To: `continuumForexS3Bucket`
   - Protocol: AWS SDK v2 (HTTPS)

6. **Return S3 object content**: S3 returns the JSON content of the rate file as a UTF-8 string.
   - From: `continuumForexS3Bucket`
   - To: `continuumForexService_s3StorageClient`
   - Protocol: AWS SDK v2 (HTTPS)

7. **Close S3 client**: `AWSS3ForexStore.getConversionRate()` closes the `AWSS3Client` in the `finally` block.
   - From: `continuumForexService_rateStoreAdapter`
   - To: (internal resource cleanup)
   - Protocol: Direct

8. **Wrap and return response**: The service wraps the raw JSON string in a `ForexRateResponse` and the `ForexResource` returns it as `Response.status(200).entity(...)`.
   - From: `continuumForexService_ratesApiResource`
   - To: Internal consumer
   - Protocol: HTTP 200 JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid currency code format (wrong length, missing `.json`, invalid characters) | Returns HTTP 400 immediately without calling the service layer | Consumer receives 400; no S3 call is made |
| S3 object not found (currency not in rate store) | `AWSS3Client.read()` returns `null`; no exception thrown | Consumer receives 200 with `null` entity — upstream consumer must handle null/empty response |
| S3 client error / exception | Exception propagates up from `AWSS3Client.read()`; not explicitly caught in `getConversionRate()` | HTTP 500 is returned by Dropwizard's exception mapper |

## Sequence Diagram

```
Consumer -> ForexResource: GET /v1/rates/USD.json
ForexResource -> ForexResource: Validate "USD.json" (split, regex match)
ForexResource -> ForexServiceImpl: getConversionRate("USD")
ForexServiceImpl -> AWSS3ForexStore: getConversionRate("USD")
AWSS3ForexStore -> AWSS3Client: read("v1/rates/USD.json")
AWSS3Client -> S3Bucket: GetObject(bucket, "v1/rates/USD.json")
S3Bucket --> AWSS3Client: JSON string content
AWSS3Client --> AWSS3ForexStore: JSON string
AWSS3ForexStore --> ForexServiceImpl: JSON string (then closes S3 client)
ForexServiceImpl --> ForexResource: ForexRateResponse(json)
ForexResource --> Consumer: HTTP 200 { "status":"ok","base":"USD","rates":{...} }
```

## Related

- Architecture dynamic view: `dynamic-forex-refresh-rates`
- Related flows: [Scheduled Rate Refresh](scheduled-rate-refresh.md), [Manual Rate Refresh (Admin)](manual-rate-refresh.md)
