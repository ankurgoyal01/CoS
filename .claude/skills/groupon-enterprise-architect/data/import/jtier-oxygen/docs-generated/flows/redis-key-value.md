---
service: "jtier-oxygen"
title: "Redis Key-Value"
generated: "2026-03-03"
type: flow
flow_name: "redis-key-value"
flow_type: synchronous
trigger: "API call — POST /redis or GET /redis/{key}"
participants:
  - "oxygenHttpApi"
  - "continuumOxygenRedisCache"
architecture_ref: "dynamic-oxygen-runtime-flow"
---

# Redis Key-Value

## Summary

The Redis key-value flow exercises JTier's RaaS (Redis as a Service) building block via the Jedis bundle. A caller stores a key-value pair (with optional TTL) in Redis and retrieves it by key. This flow validates the full round-trip from HTTP request through the Jedis connection pool to the managed Redis instance and back.

## Trigger

- **Type**: API call
- **Source**: HTTP client (JTier engineer or automated test)
- **Frequency**: On-demand (per-request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| HTTP Resources | Receives the key-value request and routes to Redis integration | `oxygenHttpApi` |
| Oxygen Redis | Stores and retrieves key-value data | `continuumOxygenRedisCache` |

## Steps

### Write Path

1. **Receive key-value write request**: Caller sends `POST /redis` with JSON body `{"key": "myKey", "value": "myValue", "ttlMilliseconds": 60000}`. The `ttlMilliseconds` field is optional.
   - From: `HTTP client`
   - To: `oxygenHttpApi`
   - Protocol: REST (HTTP)

2. **Write to Redis**: HTTP Resources uses the Jedis bundle (RaaS) to execute a `SET` command (with `PX` option if TTL is specified).
   - From: `oxygenHttpApi`
   - To: `continuumOxygenRedisCache`
   - Protocol: Redis protocol (Jedis)

3. **Return response**: Redis acknowledges the write; HTTP Resources returns a success response.
   - From: `continuumOxygenRedisCache` → `oxygenHttpApi`
   - To: `HTTP client`
   - Protocol: Redis → REST

### Read Path

1. **Receive key lookup request**: Caller sends `GET /redis/{key}`.
   - From: `HTTP client`
   - To: `oxygenHttpApi`
   - Protocol: REST (HTTP)

2. **Read from Redis**: HTTP Resources uses the Jedis bundle to execute a `GET` command for the specified key.
   - From: `oxygenHttpApi`
   - To: `continuumOxygenRedisCache`
   - Protocol: Redis protocol (Jedis)

3. **Return value**: Redis returns the value; HTTP Resources serializes it as `{"key": "myKey", "value": "myValue"}` and returns `200 OK`.
   - From: `continuumOxygenRedisCache` → `oxygenHttpApi`
   - To: `HTTP client`
   - Protocol: Redis → REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis unavailable | Jedis connection pool throws exception | `500 Internal Server Error` returned |
| Key not found on GET | Redis returns null | `200 OK` with null value or empty body (behavior depends on JAX-RS serialization) |
| TTL expired | Key is automatically evicted by Redis | `GET /redis/{key}` returns null/empty after expiry |

## Sequence Diagram

```
Client -> oxygenHttpApi: POST /redis {key, value, ttlMilliseconds?}
oxygenHttpApi -> continuumOxygenRedisCache: SET key value [PX ttl]
continuumOxygenRedisCache --> oxygenHttpApi: OK
oxygenHttpApi --> Client: 200 OK

Client -> oxygenHttpApi: GET /redis/{key}
oxygenHttpApi -> continuumOxygenRedisCache: GET key
continuumOxygenRedisCache --> oxygenHttpApi: value
oxygenHttpApi --> Client: 200 OK {key, value}
```

## Related

- Architecture dynamic view: `dynamic-oxygen-runtime-flow`
- API surface: [Redis endpoints](../api-surface.md)
- Data store: [Oxygen Redis](../data-stores.md)
