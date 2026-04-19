---
service: "badges-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-network]
---

# API Surface

## Overview

The Badges Service exposes a REST HTTP API over port 8080. Consumers (primarily RAPI and internal tooling) submit lists of deal UUIDs and receive back which deals carry badges and what type of badge to display, along with display metadata (icon URL, colors, display text). A separate `MessageController` group provides urgency-message payloads for individual deal pages. The service also exposes an admin port (8081) and a health endpoint.

The OpenAPI specification is located at `doc/swagger/swagger.yaml`.

## Endpoints

### BadgesResources

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/badges/v1` | Service root / discovery ping | Internal network |
| GET | `/badges/v1/badgesByItems` | Given a list of deal UUIDs, returns which deals should be badged and with what type | Internal network |
| POST | `/badges/v1/badgesByItems` | Same as GET variant but accepts deal list as plain-text request body | Internal network |
| POST | `/badges/v1/itemBadges` | Set a badge on a deal or deal+user combination (writes to Redis cache) | Internal network |
| DELETE | `/badges/v1/itemBadges` | Delete a badge on a deal or deal+user combination | Internal network |
| GET | `/badges/v1/list/type/{type}/channel/{channel}/country/{country}/division/{division}` | Show all deals carrying a given badge type for the specified channel, country, and division | Internal network |
| POST | `/badges/v1/setUserItemBadges` | Set a badge on a deal+user combination (deprecated) | Internal network |

### MessageController

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/api/v3/urgency_messages` | Get urgency messages (with obfuscation) associated with a single deal | Internal network |
| POST | `/api/v4/urgency_messages` | Get urgency messages without any obfuscation associated with a single deal | Internal network |

### Health / Infrastructure

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/heartbeat` | Liveness check — returns HTTP 200 when the service is healthy | Internal network |
| GET | `/grpn/status` | JTier status endpoint (port 8070) returning commit SHA and service metadata | Internal network |

## Request/Response Patterns

### Common headers

- `X-Brand` — Optional brand identifier passed on badge lookup requests to scope brand-specific badge rules.
- `locale` — Query parameter (default `en_US`) used on badge lookup and urgency-message requests to select localized display strings.

### GET /badges/v1/badgesByItems — key query parameters

| Parameter | Type | Personal Data Class | Description |
|-----------|------|---------------------|-------------|
| `itemsList` | string | unclassified | Comma-separated list of deal UUIDs to evaluate |
| `visitorId` | string | class3 | Anonymous visitor identifier for personalized badges |
| `consumerId` | string | class3 | Authenticated consumer identifier for personalized badges |
| `context` | string | unclassified | Display context hint (e.g., grid, email) |
| `locale` | string | unclassified | Locale string (default `en_US`) |
| `debug` | boolean | unclassified | When `true`, returns a `DebugResponseView` with analysis and ranking data |

### BadgesResponse shape

```json
{
  "itemBadges": [
    {
      "itemUuid": "<deal-uuid>",
      "badgeUuid": "<badge-uuid>",
      "badgeType": "<type-string>",
      "displayText": "<localized-text>",
      "displayLocation": "<location>",
      "iconImageUrl": "<url>",
      "primaryColor": "<hex>",
      "secondaryColor": "<hex>",
      "mustDisplay": true
    }
  ],
  "debugResponse": { ... }
}
```

### UrgencyMessageResponse shape

```json
{
  "showQuantity": true,
  "showTimer": false,
  "urgencyMessages": {
    "<channel-uuid>": {
      "type": "...",
      "messageText": "...",
      "messageTimerInSec": 300,
      "color": "#...",
      "visibility": "CONSTANT | FADEAWAY | ROTATING",
      "order": 1,
      "position": 0,
      "parameters": {}
    }
  }
}
```

### Error format

Standard HTTP status codes are used:
- `400` — Bad request (invalid input from caller)
- `503` — Internal error within the Badges Service

### Pagination

> No pagination is implemented. Badge results are returned in full for the submitted list of deal UUIDs.

## Rate Limits

> No rate limiting configured.

## Versioning

URL path versioning is used:
- `/badges/v1/...` — current badges resource version
- `/api/v3/urgency_messages` — urgency messages with obfuscation
- `/api/v4/urgency_messages` — urgency messages without obfuscation
- `POST /badges/v1/setUserItemBadges` is marked **deprecated** in the OpenAPI spec.

## OpenAPI / Schema References

- OpenAPI 2.0 (Swagger) spec: `doc/swagger/swagger.yaml`
- Swagger UI config: `doc/swagger/config.yml`
