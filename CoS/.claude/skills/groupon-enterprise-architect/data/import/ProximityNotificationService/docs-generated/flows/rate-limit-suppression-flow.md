---
service: "proximity-notification-service"
title: "Rate Limit and Suppression Flow"
generated: "2026-03-03"
type: flow
flow_name: "rate-limit-suppression-flow"
flow_type: synchronous
trigger: "Sub-flow invoked during every geofence request before committing to send a notification"
participants:
  - "continuumProximityNotificationService"
  - "continuumProximityNotificationPostgres"
  - "continuumProximityNotificationRedis"
architecture_ref: "dynamic-rate_limit_suppression_flow"
---

# Rate Limit and Suppression Flow

## Summary

Before the Proximity Notification Service sends a push notification to a mobile device, it applies a multi-layer rate-limiting and suppression policy to prevent notification fatigue. This flow checks unconditional mute buckets, location data freshness, general per-device daily send limits, and per-deal-type rate limits (hotzone, CLO, coupon, travel, newdeal, reminder). Rate-limit decisions combine data from Redis (transient state) and PostgreSQL (historical send logs). If a device is suppressed, the service returns a `muteUntil` timestamp instructing the client to hold off on future location reports.

## Trigger

- **Type**: sub-flow (invoked internally during every geofence request)
- **Source**: `GeofenceController.getGeofenceResponse()` and `getFirstEligiblePointOfInterest()`
- **Frequency**: Per every inbound geofence request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Geofence Workflow | Invokes rate-limit checks at multiple stages | `continuumProximityNotificationService` / `geofenceWorkflow` |
| Rate Limit and Travel Guard | Applies suppression, travel, and type-level rate limit logic | `continuumProximityNotificationService` / `rateLimitAndTravelGuard` |
| Cache Access Layer | Reads and writes user location and travel state | `continuumProximityNotificationService` / `cacheAccessLayer` |
| Redis | Provides transient location and rate-limit state | `continuumProximityNotificationRedis` |
| Persistence Layer / Send Log Manager | Reads send log history | `continuumProximityNotificationService` / `proximitynotificationservice_persistenceLayer` |
| PostgreSQL | Stores historical send log records | `continuumProximityNotificationPostgres` |

## Steps

1. **Applies unconditional mute check**: Geofence Workflow computes a hash of the device's `bcookie` against the current time bucket. If the device falls within the configured `unconditionalMutePercentage` (default: 0%), it returns an empty geofence response with `muteUntil = now + unconditionalMuteDuration`.
   - From: Geofence Workflow
   - To: (in-process)
   - Protocol: in-process

2. **Validates detect time freshness**: Checks whether the `detectTime` in the request is older than `geoPointUpdateThresholdWindow`. If stale, returns a mute response with `muteUntil = now + 1 day`.
   - From: Geofence Workflow
   - To: (in-process)
   - Protocol: in-process

3. **Reads send log from PostgreSQL**: `SendLogManager.getSendRecord()` queries the send log for the device's `bcookie` within the `maxDurationForRateLimitCheck` window, returning a `UserSendItems` record with all send history.
   - From: Rate Limit and Travel Guard / Persistence Layer
   - To: `continuumProximityNotificationPostgres`
   - Protocol: JDBI/JDBC

4. **Applies general rate limit**: `RateLimitManager.applyGeneralRateLimit()` checks whether the device has exceeded the general notification limit (default: 2 notifications per 1 day). If exceeded and the request is not flagged as a travel event, returns a mute response with `muteUntil = now + waitWhenNotificationSentMins`.
   - From: Rate Limit and Travel Guard
   - To: (in-process using `UserSendItems`)
   - Protocol: in-process

5. **Reads travel state from Redis (if travel-enabled)**: `CacheAccessLayer` fetches the device's recent location and travel state from Redis to determine whether the device is in travel mode and when travel state was last updated.
   - From: Cache Access Layer
   - To: `continuumProximityNotificationRedis`
   - Protocol: Jedis/Redis

6. **Applies type-level rate limits per POI**: For each candidate point of interest, `RateLimitManager.applyTypeLevelRateLimit()` checks the per-deal-type rate limit using `RateLimitConfiguration.getRateLimitByDealType()`. Rate limits are configurable per type:
   - `hotZone`: level-based (configurable)
   - `clo`: level-based (configurable)
   - `cloRedeem`: level-based (configurable)
   - `travel`: level-based (configurable)
   - `coupon`: level-based (configurable)
   - `newDeal`: level-based (configurable)
   - `reminder`: level-based (configurable)
   - `push` / `pull` send types: 1 per 1 day (default)

   POIs that exceed their type-level rate limit are excluded from the candidate list.
   - From: Rate Limit and Travel Guard
   - To: (in-process using `UserSendItems`)
   - Protocol: in-process

7. **Writes updated location/travel state to Redis**: After the rate-limit evaluation, the Cache Access Layer updates the device's last-known location and travel state in Redis.
   - From: Cache Access Layer
   - To: `continuumProximityNotificationRedis`
   - Protocol: Jedis/Redis

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| PostgreSQL send-log query failure | Exception propagated; request fails with HTTP 500 | No geofence response; no push sent |
| Redis unavailable | Exception from Jedis; logged | Rate-limit or travel state check may fail; flow may continue without Redis data |
| All POIs rate-limited | `getFirstEligiblePointOfInterest` returns `Optional.absent()` | No notification sent; geofences still returned |
| General rate limit exceeded | Mute response returned immediately | Client muted for `waitWhenNotificationSentMins` |

## Sequence Diagram

```
GeofenceWorkflow      -> GeofenceWorkflow: Unconditional mute check (hash % 100)
GeofenceWorkflow      -> GeofenceWorkflow: Detect time freshness check
GeofenceWorkflow      -> PostgreSQL: READ send log by bcookie + time window
PostgreSQL            --> GeofenceWorkflow: UserSendItems
GeofenceWorkflow      -> RateLimitManager: applyGeneralRateLimit(UserSendItems)
RateLimitManager      --> GeofenceWorkflow: pass / mute
GeofenceWorkflow      -> Redis: READ location + travel state
Redis                 --> GeofenceWorkflow: cached user state
GeofenceWorkflow      -> RateLimitManager: applyTypeLevelRateLimit per POI
RateLimitManager      --> GeofenceWorkflow: eligible POIs list
GeofenceWorkflow      -> Redis: WRITE updated location + travel state
```

## Related

- Architecture component: `rateLimitAndTravelGuard` within `continuumProximityNotificationService`
- Related flows: [Geofence Notification Flow](geofence-notification-flow.md)
- Configuration: `rateLimitConfiguration` section in YAML config (see [Configuration](../configuration.md))
