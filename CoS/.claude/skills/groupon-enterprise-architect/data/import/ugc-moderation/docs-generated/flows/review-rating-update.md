---
service: "ugc-moderation"
title: "Review Rating Update"
generated: "2026-03-03"
type: flow
flow_name: "review-rating-update"
flow_type: synchronous
trigger: "Moderator searches for ratings and submits a rating update"
participants:
  - "Moderator (browser)"
  - "continuumUgcModerationWeb"
  - "continuumUgcService"
architecture_ref: "dynamic-ugcModeration"
---

# Review Rating Update

## Summary

This flow covers how moderators search for review ratings (merchant recommendation scores) and update them. Moderators can filter by merchant ID, deal ID, masked name, and date range. After locating the target review, they update the rating score along with optional case ID, issue type, and reason summary for audit purposes. The update is proxied to the UGC API using an admin key.

## Trigger

- **Type**: user-action
- **Source**: Moderator navigates to `GET /review_ratings`
- **Frequency**: on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Moderator (browser) | Searches for ratings and submits updates | Human operator (admins allowlist) |
| `continuumUgcModerationWeb` | Receives requests, authorizes, calls UGC API, renders results | `continuumUgcModerationWeb` |
| `continuumUgcService` | Stores review rating data and processes updates | `continuumUgcService` |

## Steps

1. **Moderator navigates to ratings page**: Browser sends `GET /review_ratings` with optional query parameters (`merchantId`, `dealId`, `maskedName`, `startDate`, `endDate`, `offset`).
   - From: Browser
   - To: `continuumUgcModerationWeb` (Ratings Controller — `main` action)
   - Protocol: HTTP

2. **Controller checks for search criteria**: If neither `merchantId` nor `maskedName` is provided, renders empty page without calling the API.
   - From: Ratings Controller
   - To: Ratings Controller (internal)
   - Protocol: internal

3. **Controller fetches ratings from UGC API**: Calls `ugcServiceClient.admin.searchRatings()` with `{ merchantId, dealId, maskedName, startDate, endDate, offset, orderBy: updatedAt }`.
   - From: `continuumUgcModerationWeb`
   - To: `continuumUgcService`
   - Protocol: HTTPS

4. **UGC API returns paginated rating results**: Returns `{ items, total, limit }`.
   - From: `continuumUgcService`
   - To: `continuumUgcModerationWeb`
   - Protocol: HTTPS

5. **Controller renders ratings page**: Computes pagination state; sets page data (reviews array, offsets, grouponUrl, filter parameters); renders HTML.
   - From: `continuumUgcModerationWeb`
   - To: Browser
   - Protocol: HTTP (HTML)

6. **Moderator updates a rating**: Moderator selects a review and submits an update; browser sends `POST /review_ratings/update` with `{ answerId, rating, caseId, reasonSummary, issueType }`.
   - From: Browser
   - To: `continuumUgcModerationWeb` (Ratings Controller — `update` action)
   - Protocol: HTTP

7. **Controller validates required fields**: Checks that `answerId` and `rating` are present; returns `jsonMissingParams` error if missing.
   - From: Ratings Controller
   - To: Ratings Controller (internal)
   - Protocol: internal

8. **Controller calls UGC ratings update API**: Calls `ugcServiceClient.admin.updateRatings()` with `{ answerId, caseId, reasonSummary, rating, issueType, adminKey: 'admin' }`.
   - From: `continuumUgcModerationWeb`
   - To: `continuumUgcService`
   - Protocol: HTTPS

9. **UGC API confirms update**: Returns updated rating record.
   - From: `continuumUgcService`
   - To: `continuumUgcModerationWeb`
   - Protocol: HTTPS

10. **Result returned to browser**: Moderation tool returns `{ result: "ok", data: <response> }`.
    - From: `continuumUgcModerationWeb`
    - To: Browser
    - Protocol: HTTP (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing `answerId` | `responders.jsonMissingParams('answerId')` | Browser receives missing params error |
| Missing `rating` | `responders.jsonMissingParams('rating')` | Browser receives missing params error |
| UGC API update error | `responders.jsonError('unable-to-remove')` | Browser receives `{ result: "error", code: "unable-to-remove" }` |
| Search returns null/404 | Empty page rendered | No results state shown to moderator |
| Unauthorized user | Okta middleware returns 401 | Browser receives 401 Unauthorized |

## Sequence Diagram

```
Moderator -> continuumUgcModerationWeb: GET /review_ratings?merchantId=...
continuumUgcModerationWeb -> continuumUgcService: searchRatings(merchantId, orderBy=updatedAt)
continuumUgcService --> continuumUgcModerationWeb: { items, total, limit }
continuumUgcModerationWeb --> Moderator: HTML page with ratings table

Moderator -> continuumUgcModerationWeb: POST /review_ratings/update { answerId, rating, caseId, reasonSummary }
continuumUgcModerationWeb -> continuumUgcService: updateRatings(answerId, rating, caseId, adminKey=admin)
continuumUgcService --> continuumUgcModerationWeb: updated record
continuumUgcModerationWeb --> Moderator: { result: "ok", data: ... }
```

## Related

- Architecture dynamic view: `dynamic-ugcModeration`
- Related flows: [Tip Search and Delete](tip-search-and-delete.md)
- [API Surface](../api-surface.md) for endpoint details
