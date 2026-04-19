---
service: "ugc-moderation"
title: "Video Moderation"
generated: "2026-03-03"
type: flow
flow_name: "video-moderation"
flow_type: synchronous
trigger: "Moderator opens the user videos page or takes a video action"
participants:
  - "Moderator (browser)"
  - "continuumUgcModerationWeb"
  - "continuumUgcService"
architecture_ref: "dynamic-ugcModeration"
---

# Video Moderation

## Summary

This flow covers how image admins review user-submitted videos and take moderation actions (accept or reject). The moderation tool renders a video browsing page and proxies accept/reject actions to the UGC API. The video moderation flow follows the same authorization and pattern as image moderation, restricted to users in the `imageAdmins` Okta allowlist.

## Trigger

- **Type**: user-action
- **Source**: Image admin navigates to `GET /user_videos`
- **Frequency**: on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Image Admin (browser) | Views and moderates user videos | Human operator (imageAdmins allowlist) |
| `continuumUgcModerationWeb` | Receives requests, enforces image admin authorization, calls UGC API, renders results | `continuumUgcModerationWeb` |
| `continuumUgcService` | Stores video records and processes video actions | `continuumUgcService` |

## Steps

1. **Image admin navigates to videos page**: Browser sends `GET /user_videos` with optional query parameters.
   - From: Browser
   - To: `continuumUgcModerationWeb` (Videos Controller — `main` action)
   - Protocol: HTTP

2. **Controller renders videos page**: Videos Controller renders the HTML page; video data is loaded asynchronously via search.
   - From: `continuumUgcModerationWeb`
   - To: Browser
   - Protocol: HTTP (HTML)

3. **Image admin rejects a video**: Browser sends `POST /user_videos/reject` with video identifier in request body.
   - From: Browser
   - To: `continuumUgcModerationWeb` (Videos Controller — `reject` action)
   - Protocol: HTTP

4. **Okta middleware validates image admin authorization**: Checks `x-grpn-username` against `imageAdmins` allowlist for `/user_videos/reject` (restricted POST route).
   - From: Okta User Middleware
   - To: Videos Controller
   - Protocol: internal

5. **Controller forwards reject to UGC API**: Calls UGC service videos action endpoint with reject action.
   - From: `continuumUgcModerationWeb`
   - To: `continuumUgcService`
   - Protocol: HTTPS

6. **UGC API confirms rejection**: Returns success response.
   - From: `continuumUgcService`
   - To: `continuumUgcModerationWeb`
   - Protocol: HTTPS

7. **Image admin accepts a video**: Browser sends `POST /user_videos/accept` with video identifier.
   - From: Browser
   - To: `continuumUgcModerationWeb` (Videos Controller — `accept` action)
   - Protocol: HTTP

8. **Controller forwards accept to UGC API**: Calls UGC service videos action endpoint with accept/approve action.
   - From: `continuumUgcModerationWeb`
   - To: `continuumUgcService`
   - Protocol: HTTPS

9. **Result returned to browser**: Moderation tool returns `{ result: "ok" }` or error response.
   - From: `continuumUgcModerationWeb`
   - To: Browser
   - Protocol: HTTP (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| UGC API action error | `responders.jsonError('unable-to-remove')` | Browser receives `{ result: "error", code: "unable-to-remove" }` |
| Unauthorized image admin | Okta middleware returns 401 | Browser receives 401 Unauthorized |

## Sequence Diagram

```
ImageAdmin -> continuumUgcModerationWeb: GET /user_videos
continuumUgcModerationWeb --> ImageAdmin: HTML page

ImageAdmin -> continuumUgcModerationWeb: POST /user_videos/reject { videoId }
continuumUgcModerationWeb -> OktaMiddleware: validate imageAdmin x-grpn-username
OktaMiddleware --> continuumUgcModerationWeb: authorized
continuumUgcModerationWeb -> continuumUgcService: videos.action(id, action=reject)
continuumUgcService --> continuumUgcModerationWeb: success
continuumUgcModerationWeb --> ImageAdmin: { result: "ok" }

ImageAdmin -> continuumUgcModerationWeb: POST /user_videos/accept { videoId }
continuumUgcModerationWeb -> continuumUgcService: videos.action(id, action=approve)
continuumUgcService --> continuumUgcModerationWeb: success
continuumUgcModerationWeb --> ImageAdmin: { result: "ok" }
```

## Related

- Architecture dynamic view: `dynamic-ugcModeration`
- Related flows: [Image Moderation](image-moderation.md)
- [API Surface](../api-surface.md) for endpoint details
