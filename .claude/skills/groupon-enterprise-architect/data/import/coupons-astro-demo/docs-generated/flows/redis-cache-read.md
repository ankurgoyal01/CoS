---
service: "coupons-astro-demo"
title: "Redis Cache Read"
generated: "2026-03-03"
type: flow
flow_name: "redis-cache-read"
flow_type: synchronous
trigger: "Called by VoucherCloudClient data-access methods"
participants:
  - "voucherCloudClient"
  - "redisClient_CouAstDem"
  - "voucherCloudRedisCache"
architecture_ref: "CouponsAstroWebAppComponents"
---

# Redis Cache Read

## Summary

This flow describes the standardized pattern by which all data is read from the VoucherCloud Redis cache. Every `VoucherCloudClient` method (e.g., `getMerchantDetails`, `getMerchantOffers`, `getAdverts`) follows the same four-step pattern: construct a versioned cache key, delegate to `RedisClient.get()`, which applies the country/locale prefix and unwraps the JSON envelope (the `d` key), then the VoucherCloud client validates the expected response shape and extracts the typed payload.

## Trigger

- **Type**: api-call (internal, in-process)
- **Source**: `VoucherCloudClient` methods, called by `couponsRouteHandler` during SSR
- **Frequency**: Up to 7 times per merchant page request (once per data type)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| VoucherCloud Client | Constructs typed cache keys; validates and extracts response payloads | `voucherCloudClient` |
| Redis Client | Applies key prefix; calls ioredis GET; parses JSON envelope | `redisClient_CouAstDem` |
| VoucherCloud Redis Cache | External Redis store holding VoucherCloud data blobs | `voucherCloudRedisCache` |

## Steps

1. **Compose cache key**: The `VoucherCloudClient` method constructs a versioned base key specific to the data type. Examples:
   - Merchant details: `getMerchantDetails:{permalink}:v4`
   - Active offers: `VC_merchantOffers:{permalink}:v3`
   - Adverts: `getAdvertData:{typeValue}:{limit}` (where `Carousel` maps to type value `32768`)
   - Similar merchants: `getSimilarMerchants:{permalink}:{limit}:{country}`
   - Top merchants: `getTopMerchants:{brandType}:{categoryId}:{limit}:{country}`
   - Expired offers: `VC_merchantExpiredOffers:{permalink}:v3`
   - Meta content: `VC_merchantMetaContent:{permalink}:v3`
   - From: `voucherCloudClient`
   - To: `redisClient_CouAstDem`
   - Protocol: direct

2. **Apply key prefix**: `RedisClient.getPrefixedKey(baseKey)` prepends `vouchercloud:{COUNTRY}:{LOCALE}:groupon:` to produce the full Redis key. Example: `vouchercloud:US:en_US:groupon:getMerchantDetails:amazon:v4`.
   - From: `redisClient_CouAstDem`
   - To: `redisClient_CouAstDem` (internal)
   - Protocol: direct

3. **Execute Redis GET**: `ioredis.get(prefixedKey)` sends a `GET` command to the Redis server. Returns a raw JSON string or `null` if the key does not exist.
   - From: `redisClient_CouAstDem`
   - To: `voucherCloudRedisCache`
   - Protocol: Redis TCP

4. **Parse JSON envelope**: If the raw string is not null, `RedisClient.get()` parses it as JSON. The VoucherCloud cache format wraps data in `{ "b": <timestamp>, "d": <data> }`. The method extracts and returns `parsedValue.d`. If parsing fails or `d` is absent, returns `null`.
   - From: `redisClient_CouAstDem`
   - To: `voucherCloudClient`
   - Protocol: direct

5. **Validate response shape**: The `VoucherCloudClient` method checks that the returned object has the expected top-level key (e.g., `VC_merchantDetails`, `VC_merchantOffers`, `VC_adverts`, etc.) and that the nested collection (e.g., `Details`, `Offers`, `Adverts`, `Merchants`) is a non-empty array. If validation fails, returns `null`.
   - From: `voucherCloudClient`
   - To: `couponsRouteHandler` (return value)
   - Protocol: direct

6. **Extract and return typed payload**: On successful validation, extracts the relevant array or object and returns it as the strongly-typed TypeScript return type (e.g., `MerchantDetail`, `MerchantOffersResponse`, `Advert[]`, `SimilarMerchant[]`).
   - From: `voucherCloudClient`
   - To: `couponsRouteHandler`
   - Protocol: direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Cache key not found (Redis returns null) | `RedisClient.get()` returns `null`; VoucherCloudClient returns `null` | Route handler defaults to empty array or redirects to /404 for merchant |
| JSON parse error | Caught by try/catch in `RedisClient.get()`; returns `null` | Same as cache miss |
| Unexpected response shape (missing expected keys) | VoucherCloudClient structural validation fails; returns `null` | Same as cache miss |
| Redis command timeout (5s) | ioredis rejects the promise | Exception propagates; will surface as 500 if unhandled by route |
| Redis connection failure | ioredis error event emitted; `get()` throws or returns error | Logged; bubbles up to route handler |

## Sequence Diagram

```
VoucherCloudClient      RedisClient             Redis (voucherCloudRedisCache)
       |                     |                              |
       |--compose base key-->|                              |
       |                     |--getPrefixedKey(key)-------->|
       |                     |  prefix: vouchercloud:US:en_US:groupon:
       |                     |--ioredis.GET(prefixedKey)--->|
       |                     |                              |--lookup key--|
       |                     |<--raw JSON string or null----|
       |                     |--JSON.parse(rawValue)        |
       |                     |--extract .d value            |
       |<--parsed .d value---|                              |
       |--validate shape     |                              |
       |--extract typed payload                             |
       |--return typed data or null                         |
```

## Related

- Architecture dynamic view: `CouponsAstroWebAppComponents`
- Related flows: [Merchant Page Request](merchant-page-request.md), [Dependency Initialization](dependency-initialization.md)
