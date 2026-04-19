---
service: "ugc-moderation"
title: "Reported Tips Review"
generated: "2026-03-03"
type: flow
flow_name: "reported-tips-review"
flow_type: synchronous
trigger: "Moderator navigates to the reported tips page"
participants:
  - "Moderator (browser)"
  - "continuumUgcModerationWeb"
  - "continuumUgcService"
architecture_ref: "dynamic-ugcModeration"
---

# Reported Tips Review

## Summary

This flow covers how a moderator views tips that have been flagged (reported) by users or automated systems. On page load, the moderation tool automatically fetches the last 30 days of tip actions with `action=flag` from the UGC API and presents them in a table. Moderators can also search reported tips by custom date range.

## Trigger

- **Type**: user-action
- **Source**: Moderator navigates to `GET /reported`
- **Frequency**: on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Moderator (browser) | Views flagged content; optionally searches by date range | Human operator |
| `continuumUgcModerationWeb` | Receives page request, calls UGC tip actions API, renders result | `continuumUgcModerationWeb` |
| `continuumUgcService` | Provides flagged tip action records | `continuumUgcService` |

## Steps

1. **Moderator navigates to reported tips page**: Browser sends `GET /reported`.
   - From: Browser
   - To: `continuumUgcModerationWeb` (Reported Tips Controller — `main` action)
   - Protocol: HTTP

2. **Controller computes default date range**: Calculates `actionStartDate` = 1 month + 1 day ago, `actionEndDate` = now (current hour boundary).
   - From: Reported Tips Controller
   - To: Reported Tips Controller (internal)
   - Protocol: internal

3. **Controller fetches flagged tip actions**: Calls `ugcServiceClient.tipActions.fetch()` with `{ action: 'flag', limit: 50, actionStartDate, actionEndDate }`.
   - From: `continuumUgcModerationWeb`
   - To: `continuumUgcService`
   - Protocol: HTTPS

4. **UGC API returns flagged tips**: Returns `{ items, total }` of tip action records with `action=flag`.
   - From: `continuumUgcService`
   - To: `continuumUgcModerationWeb`
   - Protocol: HTTPS

5. **Controller formats and renders page**: Passes items through `reportedTipsPresenter` formatter; sets `{ tipTableRow, counter }` on the page object; renders HTML.
   - From: `continuumUgcModerationWeb`
   - To: Browser
   - Protocol: HTTP (HTML)

6. **Moderator searches by date range**: Moderator selects date range; browser sends `GET /reported/search?startDate=...&endDate=...&offset=...`.
   - From: Browser
   - To: `continuumUgcModerationWeb` (Reported Tips Controller — `search` action)
   - Protocol: HTTP

7. **Controller fetches with custom dates**: Calls `ugcServiceClient.tipActions.fetch()` with moderator-supplied date range and optional offset.
   - From: `continuumUgcModerationWeb`
   - To: `continuumUgcService`
   - Protocol: HTTPS

8. **Returns JSON results**: Formats results through `reportedTipsPresenter`; returns `{ result: "ok", data: { tipTableRow, total } }`.
   - From: `continuumUgcModerationWeb`
   - To: Browser
   - Protocol: HTTP (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| UGC API error on page load | Error passed directly to `responders.html(err)` | Error displayed in browser |
| UGC API error on search | `jsonErrorResponse(err.statusCode, 'unable-to-fetch')` | Browser receives `{ result: "error", code: "unable-to-fetch" }` |
| Unauthorized access (POST/DELETE on /reported) | Okta middleware returns 401 | Browser receives 401 Unauthorized |

## Sequence Diagram

```
Moderator -> continuumUgcModerationWeb: GET /reported
continuumUgcModerationWeb -> continuumUgcService: tipActions.fetch(action=flag, limit=50, last 30 days)
continuumUgcService --> continuumUgcModerationWeb: { items, total }
continuumUgcModerationWeb --> Moderator: HTML page with flagged tips table

Moderator -> continuumUgcModerationWeb: GET /reported/search?startDate=...&endDate=...
continuumUgcModerationWeb -> continuumUgcService: tipActions.fetch(action=flag, startDate, endDate, offset)
continuumUgcService --> continuumUgcModerationWeb: { items, total }
continuumUgcModerationWeb --> Moderator: JSON { result: "ok", data: { tipTableRow, total } }
```

## Related

- Architecture dynamic view: `dynamic-ugcModeration`
- Related flows: [Tip Search and Delete](tip-search-and-delete.md)
- [API Surface](../api-surface.md) for endpoint details
