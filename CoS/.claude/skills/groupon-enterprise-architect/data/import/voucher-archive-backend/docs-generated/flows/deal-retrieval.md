---
service: "voucher-archive-backend"
title: "Deal Retrieval"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "deal-retrieval"
flow_type: synchronous
trigger: "GET request to /ls-voucher-archive/api/v1/deals/:id"
participants:
  - "continuumVoucherArchiveBackendApp"
  - "continuumVoucherArchiveDealsDb"
  - "continuumImageService"
  - "continuumCityService"
architecture_ref: "dynamic-voucher-archive-deal-retrieval"
---

# Deal Retrieval

## Summary

Retrieves a complete deal record — including deal options, images, redemption instructions, and city/location data — from the legacy LivingSocial archive. This flow is used to populate voucher display screens with full deal context. Images and city data are supplemented from the Image Service and City Service respectively when not fully denormalized in the archive database.

## Trigger

- **Type**: api-call
- **Source**: Consumer mobile/web client, CSR tooling, or merchant portal needing deal context
- **Frequency**: On demand, per voucher display request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Caller Client | Requests deal details by deal ID | external |
| Voucher Archive API | Routes request, queries archive, assembles response | `continuumVoucherArchiveBackendApp` |
| Deals Database | Primary source of deal, option, and instruction records | `continuumVoucherArchiveDealsDb` |
| Image Service | Provides image URLs for deal display | `continuumImageService` |
| City Service | Provides city/location display data for the deal | `continuumCityService` |

## Steps

1. **Receives deal request**: Caller sends GET `/ls-voucher-archive/api/v1/deals/:id` with auth token.
   - From: `Caller Client`
   - To: `continuumVoucherArchiveBackendApp`
   - Protocol: REST / HTTP

2. **Queries deal record**: `voucherRepositories` fetches the deal record and associated options from the deals database.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `continuumVoucherArchiveDealsDb`
   - Protocol: MySQL

3. **Retrieves deal images**: API calls the Image Service to fetch image URLs for the deal.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `continuumImageService`
   - Protocol: REST

4. **Retrieves city data**: API calls the City Service to fetch location/city details for the deal's geographic context.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `continuumCityService`
   - Protocol: REST

5. **Fetches redemption instructions**: `voucherRepositories` fetches redemption instructions associated with the deal from the deals database.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `continuumVoucherArchiveDealsDb`
   - Protocol: MySQL

6. **Assembles and returns deal response**: `voucherServices` assembles the complete deal payload and returns it as JSON.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `Caller Client`
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal not found in archive | No record returned from deals database | 404 Not Found |
| Image Service unavailable | Partial response without images, or error | Degraded response or 503 |
| City Service unavailable | Partial response without city data, or error | Degraded response or 503 |
| Deals database unreachable | Connection error | 503 Service Unavailable |

## Sequence Diagram

```
Caller -> VoucherArchiveAPI: GET /ls-voucher-archive/api/v1/deals/:id
VoucherArchiveAPI -> DealsDB: SELECT deal, options, instructions WHERE deal_id = :id
DealsDB --> VoucherArchiveAPI: deal record
VoucherArchiveAPI -> ImageService: GET /images?deal_id=:id
ImageService --> VoucherArchiveAPI: image URLs
VoucherArchiveAPI -> CityService: GET /cities/:city_id
CityService --> VoucherArchiveAPI: city data
VoucherArchiveAPI --> Caller: 200 OK (deal with options, images, instructions, city)
```

## Related

- Architecture dynamic view: `dynamic-voucher-archive-deal-retrieval`
- Related flows: [Consumer Retrieve Vouchers](consumer-retrieve-vouchers.md)
