---
service: "ugc-moderation"
title: "Tip Search and Delete"
generated: "2026-03-03"
type: flow
flow_name: "tip-search-and-delete"
flow_type: synchronous
trigger: "Moderator submits a search query on the tips or merchant places page"
participants:
  - "Moderator (browser)"
  - "continuumUgcModerationWeb"
  - "continuumUgcService"
architecture_ref: "dynamic-ugcModeration"
---

# Tip Search and Delete

## Summary

This flow covers how a moderator searches for tips (merchant customer feedback) by merchant ID, deal ID, or masked name, then optionally deletes individual tips or all tips matching the search criteria. The moderation tool acts as a proxy — it forwards the search to the UGC API and renders paginated results. Delete actions are also forwarded to the UGC API.

## Trigger

- **Type**: user-action
- **Source**: Moderator navigates to `/` (home / merchant places) or `/tips/search` in the browser
- **Frequency**: on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Moderator (browser) | Initiates search and delete actions | Human operator |
| `continuumUgcModerationWeb` | Receives requests, applies authorization, calls UGC API, renders results | `continuumUgcModerationWeb` |
| `continuumUgcService` | Executes tip search and deletion queries | `continuumUgcService` |

## Steps

1. **Moderator opens home page**: Moderator navigates to `GET /`.
   - From: Browser
   - To: `continuumUgcModerationWeb` (Tips Controller — `merchantPlaces` action)
   - Protocol: HTTP

2. **Okta middleware validates access**: Middleware checks `x-grpn-username` header against the `ugcModeration.admins.oktaUsernames` allowlist. POST and DELETE verbs on `/` require authorization.
   - From: `continuumUgcModerationWeb` (Okta User Middleware)
   - To: Tips Controller
   - Protocol: internal

3. **Moderator submits search**: Moderator enters search criteria (merchantId, dealId, or maskedName) and optional date range; browser sends `GET /tips/search?merchantId=...&startDate=...&endDate=...&offset=0`.
   - From: Browser
   - To: `continuumUgcModerationWeb` (Tips Controller — `search` action)
   - Protocol: HTTP

4. **Tips Controller calls UGC API**: Controller calls `ugcServiceClient.admin.searchAnswers()` with the search parameters including `tag: mc_feedback` for merchant tips.
   - From: `continuumUgcModerationWeb`
   - To: `continuumUgcService`
   - Protocol: HTTPS

5. **UGC API returns paginated results**: Returns `{ items, total, limit }`.
   - From: `continuumUgcService`
   - To: `continuumUgcModerationWeb`
   - Protocol: HTTPS

6. **Moderation tool renders results**: Controller computes pagination (`nextOffset`, `previousOffset`, `showNext`, `showPrevious`) and returns JSON to the browser for UI rendering.
   - From: `continuumUgcModerationWeb`
   - To: Browser
   - Protocol: HTTP (JSON)

7. **Moderator deletes a tip**: Moderator clicks delete; browser sends `POST /tips/delete` with `{ tipId }`.
   - From: Browser
   - To: `continuumUgcModerationWeb` (Tips Controller — `delete` action)
   - Protocol: HTTP

8. **Tips Controller forwards delete to UGC API**: Calls UGC service delete endpoint.
   - From: `continuumUgcModerationWeb`
   - To: `continuumUgcService`
   - Protocol: HTTPS

9. **Delete result returned**: UGC API confirms deletion; moderation tool returns `{ result: "ok" }` to browser.
   - From: `continuumUgcModerationWeb`
   - To: Browser
   - Protocol: HTTP (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| UGC API search error | Error passed to `responders.jsonError('unable-to-fetch')` | Browser receives `{ result: "error", code: "unable-to-fetch" }` |
| UGC API delete error | Error passed to `responders.jsonError('unable-to-remove')` | Browser receives `{ result: "error", code: "unable-to-remove" }` |
| No results (404 from API) | Renders empty page state | Empty table displayed to moderator |
| Unauthorized user (POST/DELETE) | Okta middleware returns 401 | Browser receives 401 Unauthorized |

## Sequence Diagram

```
Moderator -> continuumUgcModerationWeb: GET /tips/search?merchantId=...
continuumUgcModerationWeb -> OktaMiddleware: validate x-grpn-username
OktaMiddleware --> continuumUgcModerationWeb: authorized
continuumUgcModerationWeb -> continuumUgcService: searchAnswers(merchantId, tag=mc_feedback)
continuumUgcService --> continuumUgcModerationWeb: { items, total, limit }
continuumUgcModerationWeb --> Moderator: JSON { items, pagination }

Moderator -> continuumUgcModerationWeb: POST /tips/delete { tipId }
continuumUgcModerationWeb -> continuumUgcService: delete(tipId)
continuumUgcService --> continuumUgcModerationWeb: success
continuumUgcModerationWeb --> Moderator: { result: "ok" }
```

## Related

- Architecture dynamic view: `dynamic-ugcModeration`
- Related flows: [Reported Tips Review](reported-tips-review.md)
- [API Surface](../api-surface.md) for endpoint details
