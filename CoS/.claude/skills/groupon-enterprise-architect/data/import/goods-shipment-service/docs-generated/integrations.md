---
service: "goods-shipment-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 8
internal_count: 4
---

# Integrations

## Overview

The Goods Shipment Service has a broad integration footprint: it calls seven external carrier or tracking platforms for shipment status, plus one aggregation/webhook platform (Aftership), and four internal Groupon services. Carrier APIs use OAuth2 token-based auth managed by the service's own Auth Token Refresh Job. Internal services use `clientId`-based API key auth or regional headers.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Aftership API | REST | Create shipment trackings and receive inbound webhooks | yes | `aftershipApi` |
| UPS API | REST | Tracking data and OAuth2 token endpoint | yes | `upsApi` |
| FedEx API | REST | Tracking data and OAuth2 token endpoint | yes | `fedexApi` |
| DHL API | REST | Tracking data and OAuth2 token endpoint | yes | `dhlApi` |
| USPS API | REST | Tracking data | yes | `uspsApi` |
| AIT API | REST | Tracking data | yes | `aitApi` |
| UPSMI API | REST | Tracking data | yes | `upsmiApi` |
| FedEx SmartPost API | REST | Tracking data | yes | `fedexspApi` |

### Aftership API Detail

- **Protocol**: REST/HTTP
- **Base URL / SDK**: Configured via `aftership.apiUrl` in the service YAML config
- **Auth**: API key sent in `as-api-key` header; webhook HMAC-SHA256 signature or `auth_token` query param for inbound validation
- **Purpose**: Registers shipments for passive carrier tracking; receives push status webhooks when carrier status changes
- **Failure mode**: Aftership create-shipment job retries on schedule (`retryForHours` default 480h); webhook errors return HTTP 500 and are retried by Aftership
- **Circuit breaker**: No evidence found in codebase

### UPS API Detail

- **Protocol**: REST/HTTP via Retrofit2
- **Base URL / SDK**: Configured via `ups.apiUrl` or `upsApiUrl`; generated from `UpsSingleTrack.json` and `UpsOauthCredentials.json`
- **Auth**: OAuth2 client credentials (`security/v1/oauth/token`); token managed by UPS OAuth Adapter and Auth Token Refresh Job
- **Purpose**: Fetch package tracking events (`api/track/v1/details/{trackingNumber}`)
- **Failure mode**: Carrier refresh job proceeds to next shipment on error; carrier max timeout controlled by `carrierApiMaxTimeout`
- **Circuit breaker**: No evidence found in codebase

### FedEx API Detail

- **Protocol**: REST/HTTP via Retrofit2 (`fedex-api` library 1.1.2)
- **Base URL / SDK**: Configured via `fedex` config block; generated from `FedexSingleTrack.json` and `FedexOauthCredentials.json`
- **Auth**: OAuth2 client credentials (`oauth/token`); token managed by FedEx OAuth Adapter and Auth Token Refresh Job
- **Purpose**: Fetch package tracking events (`track/v1/trackingnumbers`)
- **Failure mode**: Carrier refresh job proceeds to next shipment on error
- **Circuit breaker**: No evidence found in codebase

### DHL API Detail

- **Protocol**: REST/HTTP via Retrofit2
- **Base URL / SDK**: Configured via `dhl` config block
- **Auth**: OAuth2 client credentials (`auth/v4/accesstoken`); token managed by DHL OAuth Adapter and Auth Token Refresh Job
- **Purpose**: Fetch package tracking events (`tracking/v4/package/open`)
- **Failure mode**: Carrier refresh job proceeds to next shipment on error
- **Circuit breaker**: No evidence found in codebase

### USPS / AIT / UPSMI / FedEx SmartPost API Details

- **Protocol**: REST/HTTP via Retrofit2 (carrier-specific implementations)
- **Auth**: Per-carrier credentials configured in the service YAML
- **Purpose**: Fetch carrier-specific tracking events for active shipments
- **Failure mode**: Carrier refresh job proceeds to next shipment on error
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Commerce Interface | REST/HTTP (OkHttp) | Sends tracking status updates via `PUT api/internal/v1/tracking_update` (EMEA only) | `commerceInterfaceService` |
| Rocketman | REST/HTTP (OkHttp) | Sends transactional shipment notification emails | `rocketmanService` |
| Event Delivery Service | REST/HTTP (OkHttp) | Publishes mobile push notifications for SHIPPED, OUT_FOR_DELIVERY, DELIVERED statuses | `eventDeliveryService` |
| Token Service | REST/HTTP (OkHttp) | Fetches consumer mobile push tokens (device tokens) before sending push notifications | `tokenService` |

### Commerce Interface Detail

- **Protocol**: REST/HTTP PUT
- **Base URL / SDK**: Configured via `ciApiUrl`; endpoint `api/internal/v1/tracking_update`
- **Auth**: `X-HB-Region` header set to `ciRegion` config value
- **Purpose**: Notifies Commerce Interface of shipment tracking status transitions (only called when status is a notification state; only supported in EMEA)
- **Failure mode**: Throws `IOException` if response is not successful; logged and propagated

### Rocketman Detail

- **Protocol**: REST/HTTP POST
- **Base URL / SDK**: Configured via `rocketman.url` + `rocketman.sendEmailEndpoint`; `client_id` as query param
- **Auth**: `X-brand` header + `client_id` query param
- **Purpose**: Delivers HTML transactional email for shipment notifications (NA and EMEA templates)
- **Failure mode**: Throws `WebApplicationException` on non-2xx response

### Event Delivery Service Detail

- **Protocol**: REST/HTTP POST
- **Base URL / SDK**: Configured via `eventDeliveryService.url`; three endpoints: `/pns/v1.0/notification/EVENT/goods_shipment_shipped`, `/pns/v1.0/notification/EVENT/goods_shipment_out_for_delivery`, `/pns/v1.0/notification/EVENT/goods_shipment_delivered`
- **Auth**: `client_id` query param; optional `X-HB-Region` header
- **Purpose**: Delivers mobile push notification events to iOS/Android devices
- **Failure mode**: Throws `IOException` on non-2xx response

### Token Service Detail

- **Protocol**: REST/HTTP
- **Base URL / SDK**: Configured via `tokenServiceUrl`
- **Purpose**: Retrieves consumer device tokens needed to send push notifications via Event Delivery Service
- **Failure mode**: No evidence found in codebase for specific fallback behaviour

## Consumed By

> Upstream consumers are tracked in the central architecture model. Internal Groupon commerce and fulfilment services POST shipment records to the `/shipments` endpoint. Aftership pushes webhook events to `/aftership`.

## Dependency Health

Carrier API timeouts are bounded by the `carrierApiMaxTimeout` configuration property. All HTTP clients use OkHttp or Retrofit2 with JTier-managed pooling. No service-wide circuit breaker or retry library is configured beyond individual try/catch blocks and the Quartz job retry schedule.
