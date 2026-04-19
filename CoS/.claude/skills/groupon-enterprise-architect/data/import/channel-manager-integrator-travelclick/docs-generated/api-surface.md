---
service: "channel-manager-integrator-travelclick"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest, xml]
auth_mechanisms: [basic-auth]
---

# API Surface

## Overview

The service exposes two groups of HTTP endpoints using JAX-RS over Dropwizard. The first group receives ARI (Availability, Rate, Inventory) push messages from TravelClick in OTA XML format and validates/persists them. The second group retrieves hotel product data. All endpoints require HTTP Basic Authentication as defined in the OpenAPI schema. The API uses `application/xml` as the content type for both requests and responses, conforming to the OpenTravel Alliance (OTA) 2003/05 standard.

## Endpoints

### ARI Push Endpoints (TravelClick ARI Push)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/getaways/v2/partner/travelclick/CMService/pushAvailability` | Receives an OTA availability notification from TravelClick and updates availability restrictions | Basic Auth |
| POST | `/getaways/v2/partner/travelclick/CMService/pushInventory` | Receives an OTA inventory count notification from TravelClick and updates room inventory | Basic Auth |
| POST | `/getaways/v2/partner/travelclick/CMService/pushRates` | Receives an OTA rate plan notification from TravelClick and updates hotel rate plans | Basic Auth |

### Hotel Products Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/getaways/v2/partner/travelclick/hotelProducts` | Retrieves hotel product details (room types, rate plans) from TravelClick | Basic Auth |

## Request/Response Patterns

### Common headers

- `Content-Type: application/xml` — all requests and responses use OTA XML
- HTTP Basic Auth credentials required on all endpoints

### Error format

Errors are returned as OTA XML response objects with an `Errors` element containing one or more `Error` entries. Each `Error` includes:
- `Code` (attribute): error code string
- `ShortText` (attribute): human-readable error description
- `Type` (attribute): integer error type code
- `value`: error detail text

Example response structure (availability):
```xml
<OTA_HotelAvailNotifRS xmlns="http://www.opentravel.org/OTA/2003/05">
  <Errors>
    <Error Code="..." ShortText="..." Type="..."/>
  </Errors>
</OTA_HotelAvailNotifRS>
```

Success responses include a `<Success/>` element. Warning conditions include a `<Warnings>` element with one or more `<Warning>` entries using the same structure as errors.

### Pagination

> Not applicable — all ARI push endpoints are stateless per-call operations with no pagination.

## Rate Limits

> No rate limiting configured. TravelClick is the only caller of these endpoints.

## Versioning

URL path versioning is used: `/getaways/v2/partner/travelclick/...`. The current version is `v2`.

## OpenAPI / Schema References

- OpenAPI schema: `doc/schema.yml` (OpenAPI 3.0.0)
- Swagger config: `doc/swagger/config.yml`
- Published Swagger: `https://pages.github.groupondev.com/sox-inscope/channel-manager-integrator-travelclick/swagger.json`
- XML namespace: `http://www.opentravel.org/OTA/2003/05`
