---
service: "coupons-astro-demo"
title: "Dependency Initialization"
generated: "2026-03-03"
type: flow
flow_name: "dependency-initialization"
flow_type: synchronous
trigger: "Every incoming HTTP request — Astro middleware pipeline"
participants:
  - "dependenciesMiddleware"
  - "redisClient_CouAstDem"
  - "voucherCloudClient"
architecture_ref: "CouponsAstroWebAppComponents"
---

# Dependency Initialization

## Summary

On every incoming HTTP request, the `dependenciesMiddleware` runs before any route handler. It creates a configured `ioredis` connection, wraps it in a `RedisClient` (which applies country/locale key prefixing), wraps that in a `VoucherCloudClient` (which provides typed data-access methods), and injects both into Astro's `context.locals` for type-safe access by route handlers and components downstream. This implements a per-request dependency injection pattern in a stateless SSR context.

## Trigger

- **Type**: api-call (automatic — Astro middleware pipeline)
- **Source**: Every HTTP request arriving at the Node.js server
- **Frequency**: Per-request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Dependencies Middleware | Orchestrates client construction and context injection | `dependenciesMiddleware` |
| Redis Client | Wraps `ioredis` with key prefixing and JSON decode logic | `redisClient_CouAstDem` |
| VoucherCloud Client | Provides typed business-data methods backed by Redis | `voucherCloudClient` |

## Steps

1. **Instantiate ioredis connection**: Creates a new `ioredis.Redis` instance with configuration read from environment variables: `REDIS_HOST` (default `localhost`), `REDIS_PORT` (default `6379`), `REDIS_PASSWORD` (optional), `REDIS_DB` (default `0`). Uses `lazyConnect: true` (no TCP connection until first command), `maxRetriesPerRequest: 3`, `connectTimeout: 10000` ms, `commandTimeout: 5000` ms.
   - From: `dependenciesMiddleware`
   - To: ioredis (in-process instantiation)
   - Protocol: direct

2. **Register error and connect listeners**: Attaches `redis.on('error', ...)` to log `"Redis connection error:"` to stderr and `redis.on('connect', ...)` to log `"Redis connected successfully"` to stdout.
   - From: `dependenciesMiddleware`
   - To: ioredis event emitter
   - Protocol: direct

3. **Construct RedisClient**: Creates `new RedisClient(redis, COUNTRY_CODE, LOCALE_CODE)`. The constructor upper-cases the country code and builds the key prefix: `vouchercloud:{COUNTRY}:{LOCALE}:groupon`.
   - From: `dependenciesMiddleware`
   - To: `redisClient_CouAstDem`
   - Protocol: direct

4. **Construct VoucherCloudClient**: Creates `new VoucherCloudClient(redisClient, COUNTRY_CODE, LOCALE_CODE)`. Stores the Redis client reference for use by all data-access methods.
   - From: `dependenciesMiddleware`
   - To: `voucherCloudClient`
   - Protocol: direct

5. **Inject into context.locals**: Assigns `context.locals.redis = redisClient` and `context.locals.voucherCloudClient = voucherCloudClient`. Route handlers access these via `Astro.locals` (type-safe through the `env.d.ts` locals declaration).
   - From: `dependenciesMiddleware`
   - To: `couponsRouteHandler` (downstream, via Astro locals)
   - Protocol: direct

6. **Continue middleware chain**: Calls `await next()` to pass control to the next middleware or route handler.
   - From: `dependenciesMiddleware`
   - To: `couponsRouteHandler`
   - Protocol: direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid `REDIS_HOST` or unreachable host | ioredis uses `lazyConnect`; error only surfaces on first command | `error` event logged; first Redis GET returns error/null |
| Missing `REDIS_PASSWORD` | `ioredis` connects without auth; Redis may reject commands | Redis error event logged; commands fail → null returns from client |
| Environment variable missing | Falls back to hardcoded defaults (`localhost`, `6379`, `US`, `en_US`) | Works for local development; wrong prefix in production if not set |

## Sequence Diagram

```
Request         dependenciesMiddleware    RedisClient    VoucherCloudClient
  |                     |                     |                  |
  |--HTTP request------->|                     |                  |
  |                     |--new Redis({host,port,password,db})     |
  |                     |--redis.on('error', log)                 |
  |                     |--redis.on('connect', log)               |
  |                     |--new RedisClient(redis, country, locale)->|
  |                     |                     |<-keyPrefix built--|
  |                     |--new VoucherCloudClient(redisClient)---->|
  |                     |--context.locals.redis = redisClient      |
  |                     |--context.locals.voucherCloudClient = vc  |
  |                     |--await next()------->RouteHandler        |
```

## Related

- Architecture dynamic view: `CouponsAstroWebAppComponents`
- Related flows: [Merchant Page Request](merchant-page-request.md), [Redis Cache Read](redis-cache-read.md)
