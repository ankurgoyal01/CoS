---
service: "proximity-notification-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 7
---

# Integrations

## Overview

The Proximity Notification Service calls seven downstream Groupon internal services via synchronous HTTP/JSON using Retrofit-based client adapters. All outbound HTTP clients are constructed through `HttpClientGenerator` and managed by `ProximityClientManagerImpl`. No external third-party integrations are present; all dependencies are Groupon internal services.

## External Dependencies

> No evidence found in codebase of integrations with external (non-Groupon) third-party systems.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Rocketman push service | HTTP/JSON (Retrofit) | Sends push notifications and email messages to mobile devices | stub: `rocketmanService_unknown_12b7730b` |
| Targeted Deal Message service | HTTP/JSON (Retrofit) | Fetches purchased deal annotations enriching notification content | stub: `targetedDealMessage_unknown_357de281` |
| Coupon/Inventory service | HTTP/JSON (Retrofit) | Fetches nearby pushable coupons for geofence proximity | `continuumCouponsInventoryService` |
| CLO Inventory service | HTTP/JSON (Retrofit) | Checks CLO (Card-Linked Offer) redemption readiness for a user | `continuumCloInventoryService` |
| Voucher Inventory service | HTTP/JSON (Retrofit) | Checks voucher sold-out state before sending notification | `continuumVoucherInventoryService` |
| Realtime Audience Management service | HTTP/JSON (Retrofit) | Fetches audience memberships and user affinity scores | `continuumAudienceManagementService` |
| Watson KV | HTTP/JSON (Retrofit) | Retrieves Watson support data (deal scoring / annotation) used by proximity flows | `watsonKv` |

### Rocketman Push Service Detail

- **Protocol**: HTTP/JSON via `HttpPushNotificationClient` (Retrofit)
- **Base URL**: Configured via `pushNotificationConfiguration` in YAML config
- **Auth**: Not visible from codebase (internal service)
- **Purpose**: Dispatches push notifications and email messages to iOS/Android devices based on a `PushNotificationRequest` or `PushNotificationEmailRequest` payload
- **Failure mode**: On push failure the send log is not written and the geofence response still returns geofences to the mobile client
- **Circuit breaker**: No evidence found

### Targeted Deal Message Service Detail

- **Protocol**: HTTP/JSON via `HttpTargetedDealMessageClient` (Retrofit)
- **Base URL**: Configured via `targetedDealMessageConfiguration` in YAML config
- **Auth**: Not visible from codebase
- **Purpose**: Returns `PurchasedDealsResponse` (user's purchased deals) and `DealAnnotationResponse` (deal-level EC annotations) to enrich notification decisions
- **Failure mode**: Geofence workflow continues with absent annotation if this call fails; notification can still be generated without annotation
- **Circuit breaker**: No evidence found

### Coupon Inventory Service Detail

- **Protocol**: HTTP/JSON via `HttpCouponClient` (Retrofit)
- **Base URL**: Configured via `couponConfiguration` in YAML config
- **Auth**: Not visible from codebase
- **Purpose**: Returns `PushableCouponResponse` containing nearby coupons with location, price, and time-box data
- **Failure mode**: No coupons returned; hotzone flow continues with other deal types
- **Circuit breaker**: No evidence found

### CLO Inventory Service Detail

- **Protocol**: HTTP/JSON via `HttpCloClient` (Retrofit)
- **Base URL**: Configured via `cloConfiguration` in YAML config
- **Auth**: Not visible from codebase
- **Purpose**: Returns `CloResponse` indicating whether a CLO deal linked to a user's payment card is ready to redeem at a nearby merchant
- **Failure mode**: CLO deal type not promoted to `HOTZONE_CLO_REDEEM`; standard hotzone flow continues
- **Circuit breaker**: No evidence found

### Voucher Inventory Service Detail

- **Protocol**: HTTP/JSON via `HttpVoucherInventoryClient` (Retrofit)
- **Base URL**: Configured via `voucherInventoryConfiguration` in YAML config
- **Auth**: Not visible from codebase
- **Purpose**: Returns `VoucherInventoryResponse` to determine if a deal's vouchers are sold out; sold-out deals are deleted from PostgreSQL and excluded from geofence response
- **Failure mode**: Deal assumed not sold out; notification may be sent for unavailable inventory
- **Circuit breaker**: No evidence found

### Realtime Audience Management Service Detail

- **Protocol**: HTTP/JSON via `HttpRealtimeAudienceManagementServiceClient` (Retrofit)
- **Base URL**: Configured via `realtimeAudienceManagementServiceConfiguration` in YAML config
- **Auth**: Not visible from codebase
- **Purpose**: Returns audience membership data (`ConsumerAuthorityResponse`) and user attributes (`GetUserAttributesResponse`) for audience-targeted hotzones
- **Failure mode**: Audience filtering skipped; all-audience fallback used
- **Circuit breaker**: No evidence found

### Watson KV Detail

- **Protocol**: HTTP/JSON (Retrofit)
- **Base URL**: Configured via `watsonConfiguration` in YAML config
- **Auth**: Not visible from codebase
- **Purpose**: Retrieves Watson scoring/support data for deal ranking within proximity flows
- **Failure mode**: Watson data absent; deal ranking falls back to default scoring
- **Circuit breaker**: No evidence found

## Consumed By

> Upstream consumers are tracked in the central architecture model. Mobile clients (iOS and Android) are the primary callers, routed through the Groupon API proxy. The Proximity UI admin interface calls the hotzone management endpoints.

## Dependency Health

All outbound HTTP clients are constructed via `HttpClientGenerator` using JTier's `jtier-okhttp` base. Connection and read timeouts are configured in the `HttpClientConfig` section of the YAML configuration. Health checks for PostgreSQL and Redis are registered via the `Health and Metrics` component. No evidence of circuit breaker or retry patterns beyond OkHttp default behavior.
