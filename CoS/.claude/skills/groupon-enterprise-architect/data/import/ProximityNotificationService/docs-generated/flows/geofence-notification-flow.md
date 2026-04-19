---
service: "proximity-notification-service"
title: "Geofence Notification Flow"
generated: "2026-03-03"
type: flow
flow_name: "geofence-notification-flow"
flow_type: synchronous
trigger: "Mobile client POSTs device location coordinates to the geofence endpoint"
participants:
  - "continuumProximityNotificationService"
  - "continuumProximityNotificationRedis"
  - "continuumProximityNotificationPostgres"
  - "continuumAudienceManagementService"
  - "continuumCouponsInventoryService"
  - "continuumCloInventoryService"
  - "continuumVoucherInventoryService"
  - "watsonKv"
architecture_ref: "dynamic-geofence_notification_flow"
---

# Geofence Notification Flow

## Summary

When a mobile device enters or is near a Hotzone boundary, the Groupon app POSTs the device's current location and event metadata to the geofence endpoint. The service evaluates the location against active hotzone deals, applies user-level rate limits and suppression rules, enriches candidate deals with audience, voucher, CLO, coupon, and annotation data from downstream services, and — if an eligible deal is found — dispatches a push notification via the Rocketman service and records the send in PostgreSQL. The response always returns a set of geofence coordinates for the device to monitor.

## Trigger

- **Type**: api-call
- **Source**: Groupon iOS or Android mobile app (via API proxy)
- **Frequency**: On-demand, every time the device enters or crosses a geofence boundary

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Mobile Client | Initiates request with device location, receives geofence set | (stub) `mobileClient_unknown_4397a830` |
| Proximity Notification Service | Orchestrates the entire flow | `continuumProximityNotificationService` |
| Redis Cache | Provides recent user location and travel state | `continuumProximityNotificationRedis` |
| PostgreSQL | Provides send log history; receives new send log entry | `continuumProximityNotificationPostgres` |
| Realtime Audience Management | Provides audience membership for targeted deals | `continuumAudienceManagementService` |
| Coupon Inventory | Provides nearby pushable coupons | `continuumCouponsInventoryService` |
| CLO Inventory | Checks CLO deal redemption readiness | `continuumCloInventoryService` |
| Voucher Inventory | Checks deal sold-out state | `continuumVoucherInventoryService` |
| Watson KV | Provides deal scoring / Watson support data | `watsonKv` |
| Targeted Deal Message | Provides purchased deals and deal annotations | (stub) `targetedDealMessage_unknown_357de281` |
| Rocketman Push Service | Delivers push notification or email to device | (stub) `rocketmanService_unknown_12b7730b` |

## Steps

1. **Receives location event**: Mobile client POSTs device location (lat/lng, bcookie, consumerId, detectTime, action, activity, supports, countryCode) to `POST /proximity/{countryCode}/location/geofence`.
   - From: Mobile Client
   - To: `continuumProximityNotificationService` / API Resources
   - Protocol: HTTPS/JSON (form-encoded)

2. **Applies unconditional mute check**: If `parameterConfiguration.unconditionalMutePercentage > 0`, the service hashes the bcookie and deterministically mutes a configured percentage of traffic to shed load. Returns empty geofences with `muteUntil` timestamp.
   - From: Geofence Workflow
   - To: (internal)
   - Protocol: in-process

3. **Validates detect time freshness**: If the `detectTime` in the request is older than `geoPointUpdateThresholdWindow`, the service rejects the location as stale and returns a mute response.
   - From: Geofence Workflow
   - To: (internal)
   - Protocol: in-process

4. **Reads send log from PostgreSQL**: Looks up the user's recent send history by `bcookie` within the `maxDurationForRateLimitCheck` window to retrieve `UserSendItems`.
   - From: `continuumProximityNotificationService`
   - To: `continuumProximityNotificationPostgres`
   - Protocol: JDBI/JDBC

5. **Applies general rate limit**: Evaluates whether the device has already received notifications within the general rate-limit window (default: 2 per day). If the limit is exceeded and the request is not a travel event, returns a mute response with `muteUntil` set to `waitWhenNotificationSentMins` in the future.
   - From: Rate Limit and Travel Guard
   - To: (in-process using Redis and PostgreSQL data)
   - Protocol: in-process

6. **Fetches candidate points of interest**: The `HotzonePointOfInterestClient` queries PostgreSQL for active hotzone deals within `hotzoneSearchRadiusInMeters` of the device's location, filtered by audience, brand, and time window. Also calls Audience Management, Watson KV, and Coupon services to gather enriched POI data.
   - From: `continuumProximityNotificationService`
   - To: `continuumProximityNotificationPostgres`, `continuumAudienceManagementService`, `watsonKv`, `continuumCouponsInventoryService`
   - Protocol: JDBI/JDBC + HTTP/JSON

7. **Checks CLO redemption readiness**: For any candidate deal of type `HOTZONE_CLO`, calls the CLO Inventory service to determine if the user's linked card is ready to redeem at this merchant. If ready, promotes the deal to type `HOTZONE_CLO_REDEEM`.
   - From: `continuumProximityNotificationService`
   - To: `continuumCloInventoryService`
   - Protocol: HTTP/JSON

8. **Checks voucher sold-out state**: For each candidate POI, calls the Voucher Inventory service. If the deal is sold out, deletes it from PostgreSQL and removes it from the candidate list.
   - From: `continuumProximityNotificationService`
   - To: `continuumVoucherInventoryService`, `continuumProximityNotificationPostgres`
   - Protocol: HTTP/JSON + JDBI/JDBC

9. **Applies type-level rate limits**: For each remaining candidate, checks `RateLimitManager.applyTypeLevelRateLimit` against the user's send history. Deals that exceed their per-type rate limit are excluded.
   - From: Rate Limit and Travel Guard
   - To: (in-process)
   - Protocol: in-process

10. **Selects best POI via convenience score**: Among eligible candidates, `ConvenienceScoreManager` selects the highest-scoring deal based on proximity, convenience, and deal quality.
    - From: Geofence Workflow
    - To: (in-process)
    - Protocol: in-process

11. **Fetches deal annotation (if supported)**: If the mobile client declares `IN_RESPONSE_NOTIFICATION` in `supports`, the service calls the Targeted Deal Message service to retrieve a `DealAnnotationResponse` for the selected deal.
    - From: `continuumProximityNotificationService`
    - To: `targetedDealMessage_unknown_357de281`
    - Protocol: HTTP/JSON

12. **Generates notification payload**: The `ProximityNotificationGenerator` / Notification Engine builds a localized notification text using Mustache templates and locale-specific resource bundles, plus a tracking ID.
    - From: Notification Engine
    - To: (in-process)
    - Protocol: in-process

13. **Sends push notification**: Calls the Rocketman push service with a `PushNotificationRequest` payload containing the notification text, tracking ID, bcookie, and client roles.
    - From: `continuumProximityNotificationService`
    - To: `rocketmanService_unknown_12b7730b`
    - Protocol: HTTP/JSON

14. **Writes send log**: On successful push, writes a send log record to PostgreSQL to enforce future rate limits.
    - From: `continuumProximityNotificationService`
    - To: `continuumProximityNotificationPostgres`
    - Protocol: JDBI/JDBC

15. **Returns geofence response**: Always returns a set of `Geofence` objects (lat/lng/radius/validUntil) for the device to monitor locally. If no POIs are found, returns fallback corner geofences. If rate-limited or muted, returns empty geofences with `muteUntil`.
    - From: `continuumProximityNotificationService`
    - To: Mobile Client
    - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Stale detect time | Mute response with `muteUntil = now + 1 day` | Client muted for 24 hours |
| Unconditional mute bucket | Mute response with `muteUntil = now + muteDuration` | Client muted for configured duration |
| General rate limit exceeded | Mute response with `muteUntil = now + waitMins` | Client muted until rate limit window resets |
| Notification generation exception | Logged as ERROR; `Optional.absent()` returned | No push sent; geofences still returned |
| Push notification send failure | Logged; send log NOT written | No rate limit consumed; client will be eligible again |
| Voucher sold-out | Deal deleted from PostgreSQL | Sold-out deals removed from future responses |
| Downstream service failure (CLO, coupon, audience, watson) | Logged; flow continues without that data | Notification may not be sent; geofences returned |

## Sequence Diagram

```
MobileClient         -> ProximityNotificationService: POST /proximity/{countryCode}/location/geofence
ProximityNotificationService -> ProximityNotificationService: Mute/freshness check
ProximityNotificationService -> PostgreSQL: Read send log by bcookie
ProximityNotificationService -> ProximityNotificationService: Apply general rate limit
ProximityNotificationService -> PostgreSQL: Query hotzone POIs by location
ProximityNotificationService -> AudienceManagementService: GET audience membership
ProximityNotificationService -> WatsonKV: GET scoring data
ProximityNotificationService -> CouponInventoryService: GET pushable coupons
ProximityNotificationService -> CloInventoryService: GET CLO redemption readiness
ProximityNotificationService -> VoucherInventoryService: GET voucher sold-out state
ProximityNotificationService -> ProximityNotificationService: Apply type-level rate limits + score selection
ProximityNotificationService -> TargetedDealMessageService: GET deal annotation
ProximityNotificationService -> ProximityNotificationService: Generate notification payload
ProximityNotificationService -> RocketmanService: POST push notification
RocketmanService     --> ProximityNotificationService: Push result
ProximityNotificationService -> PostgreSQL: Write send log
ProximityNotificationService --> MobileClient: GeofenceResponse (geofences + optional muteUntil)
```

## Related

- Architecture dynamic view: `dynamic-geofence_notification_flow`
- Related flows: [Rate Limit and Suppression Flow](rate-limit-suppression-flow.md), [Hotzone Management Flow](hotzone-management-flow.md)
