---
service: "coffee-to-go"
title: "Usage Event Tracking Flow"
generated: "2026-03-03"
type: flow
flow_name: "usage-event-tracking"
flow_type: synchronous
trigger: "User interactions in the frontend (automatic batching)"
participants:
  - "coffeeWeb"
  - "coffeeApi"
  - "coffeeDb"
---

# Usage Event Tracking Flow

## Summary

The frontend automatically captures user interaction events (page views, filter changes, map interactions) and batches them for submission to the API. The API validates the batch and inserts events into the `usage_events` table. Analytics data is later queryable via the usage graph endpoint, which aggregates events by day or week with support for feature-specific filtering.

## Trigger

- **Type**: user-action (automatic)
- **Source**: Frontend tracking components detect user interactions and batch them
- **Frequency**: Per batch (up to 50 events per request); subject to tracking rate limiter (50 requests/minute)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| React Web Application | Captures events, batches them, sends to API | `coffeeWeb` |
| Express API | Validates batch, inserts into database | `coffeeApi` |
| Coffee DB | Stores usage events for analytics | `coffeeDb` |

## Steps

1. **Frontend captures interaction**: Tracking components detect user interactions (filter changes, map movements, page navigation) and add events to the tracking store.
   - From: `coffeeWeb` (Tracking Components)
   - To: `coffeeWeb` (Tracking Store)
   - Protocol: React state

2. **Frontend batches and submits events**: The tracking store batches events and sends them to the API via POST.
   - From: `coffeeWeb` (API Client)
   - To: `coffeeApi` (Tracking Routes)
   - Protocol: HTTPS, JSON

3. **API validates batch**: The Tracking Controller validates the request body against the `UsageEventBatchSchema` (Zod). Each event must have `event_type`, `page_url`, `timestamp`, and optional `event_data` (JSON).
   - From: `coffeeApi` (Tracking Routes)
   - To: `coffeeApi` (Tracking Controller)
   - Protocol: Direct

4. **Service inserts events**: The Tracking Service transforms events to match the database schema (adding `user_id`, `session_id`, `environment`) and performs a batch insert via Kysely.
   - From: `coffeeApi` (Tracking Service)
   - To: `coffeeDb` (usage_events table)
   - Protocol: PostgreSQL (primary pool)

5. **API returns success**: The API responds with a success status.
   - From: `coffeeApi`
   - To: `coffeeWeb`
   - Protocol: HTTPS, JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid event batch | Zod validation returns 400 | Frontend may retry or drop events |
| Tracking rate limit exceeded | Rate limiter returns 429 (`TRACKING_RATE_LIMIT_EXCEEDED`) | Frontend backs off |
| Database insert failure | Service throws `TRACKING_ERROR`, logged as error | Events are lost for this batch |
| Authentication failure | Auth middleware returns 401 | Events are not submitted |

## Sequence Diagram

```
CoffeeWeb -> CoffeeWeb: Capture user interaction events
CoffeeWeb -> CoffeeApi: POST /api/usage/events { events: [...] }
CoffeeApi -> CoffeeApi: Validate batch (Zod)
CoffeeApi -> CoffeeDb: INSERT INTO usage_events (batch)
CoffeeDb --> CoffeeApi: OK
CoffeeApi --> CoffeeWeb: 200 OK
```

## Related

- Related flows: [Deal Search](deal-search.md)
