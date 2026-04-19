---
service: "ugc-moderation"
title: "Image Moderation"
generated: "2026-03-03"
type: flow
flow_name: "image-moderation"
flow_type: synchronous
trigger: "Moderator opens the user images page or performs an image action"
participants:
  - "Moderator (browser)"
  - "continuumUgcModerationWeb"
  - "continuumUgcService"
architecture_ref: "dynamic-ugcModeration"
---

# Image Moderation

## Summary

This flow covers how image admins review user-submitted images and take moderation actions. The moderation tool fetches images from the UGC API filtered by status, merchant, deal, user, and date range. Moderators can then accept images (approve), reject images with a reason code, or update the image URL. Reason codes are mapped to human-readable labels via the `imageReasonIdToText` configuration.

## Trigger

- **Type**: user-action
- **Source**: Image admin navigates to `GET /user_images`
- **Frequency**: on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Image Admin (browser) | Views and moderates user images | Human operator (imageAdmins allowlist) |
| `continuumUgcModerationWeb` | Receives requests, enforces image admin authorization, calls UGC API, renders results | `continuumUgcModerationWeb` |
| `continuumUgcService` | Stores image records and processes image actions | `continuumUgcService` |

## Steps

1. **Image admin navigates to images page**: Browser sends `GET /user_images` with optional query parameters (`merchantId`, `dealId`, `userId`, `imageId`, `status`, `startDate`, `endDate`, `offset`).
   - From: Browser
   - To: `continuumUgcModerationWeb` (Images Controller — `main` action)
   - Protocol: HTTP

2. **Controller applies default status**: If `status` is not provided, defaults to `submitted`.
   - From: Images Controller
   - To: Images Controller (internal)
   - Protocol: internal

3. **Controller fetches images from UGC API**: Calls `ugcServiceClient.admin.searchImages()` with the assembled data object including `orderBy: updatedAt`.
   - From: `continuumUgcModerationWeb`
   - To: `continuumUgcService`
   - Protocol: HTTPS

4. **UGC API returns paginated image results**: Returns `{ items, total, limit }`.
   - From: `continuumUgcService`
   - To: `continuumUgcModerationWeb`
   - Protocol: HTTPS

5. **Controller maps reason IDs to text**: For `rejected` or `reported` status, maps `imageAction.reasonId` values to human-readable text using the `imageReasonIdToText.idToText` config map (7 reason codes configured).
   - From: Images Controller
   - To: Images Controller (internal)
   - Protocol: internal

6. **Controller renders image page**: Sets page data including images array, pagination state, and current status filter; renders HTML.
   - From: `continuumUgcModerationWeb`
   - To: Browser
   - Protocol: HTTP (HTML)

7. **Image admin rejects an image**: Moderator selects a reason and clicks reject; browser sends `POST /user_images/report` with `{ imageId, reasonId, reasonText }`.
   - From: Browser
   - To: `continuumUgcModerationWeb` (Images Controller — `report` action)
   - Protocol: HTTP

8. **Controller calls UGC image action API**: Calls `ugcServiceClient.images.action()` with `{ id, action: 'reject', agent: 'admin', reasonId, reasonText, agentKey: 'moderation_tool#imageAdmin' }`.
   - From: `continuumUgcModerationWeb`
   - To: `continuumUgcService`
   - Protocol: HTTPS

9. **Image admin accepts an image**: Browser sends `POST /user_images/accept` with `{ imageId }`.
   - From: Browser
   - To: `continuumUgcModerationWeb` (Images Controller — `accept` action)
   - Protocol: HTTP

10. **Controller calls UGC image action API**: Calls `ugcServiceClient.images.action()` with `{ id, action: 'approve', agent: 'admin', agentKey: 'moderation_tool#imageAdmin' }`.
    - From: `continuumUgcModerationWeb`
    - To: `continuumUgcService`
    - Protocol: HTTPS

11. **Image admin updates image URL**: Browser sends `POST /user_images/updateUrl` with `{ imageId, imageUrl }`.
    - From: Browser
    - To: `continuumUgcModerationWeb` (Images Controller — `updateUrl` action)
    - Protocol: HTTP

12. **Controller calls UGC image action API**: Calls `ugcServiceClient.images.action()` with `{ id, action: 'updateUrl', imageUrl, agent: 'admin', agentKey: 'moderation_tool#<username>' }`. Username extracted from `x-grpn-username` header.
    - From: `continuumUgcModerationWeb`
    - To: `continuumUgcService`
    - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| UGC API search error | Error passed to `responders.html(err)` | Error displayed in browser |
| No images found | `responders.html('No Images found')` | Empty state message |
| Missing imageId on action | `responders.jsonMissingParams('imageId')` | Browser receives missing params error |
| Missing username on updateUrl | `responders.jsonMissingParams('username')` | Browser receives missing params error |
| UGC action API error | `responders.jsonError('unable-to-remove')` | Browser receives `{ result: "error" }` |
| Unauthorized image admin | Okta middleware returns 401 | Browser receives 401 Unauthorized |

## Sequence Diagram

```
ImageAdmin -> continuumUgcModerationWeb: GET /user_images?merchantId=...&status=submitted
continuumUgcModerationWeb -> continuumUgcService: searchImages(merchantId, status, orderBy=updatedAt)
continuumUgcService --> continuumUgcModerationWeb: { items, total, limit }
continuumUgcModerationWeb --> ImageAdmin: HTML page with images

ImageAdmin -> continuumUgcModerationWeb: POST /user_images/report { imageId, reasonId }
continuumUgcModerationWeb -> continuumUgcService: images.action(id, action=reject, reasonId, agentKey)
continuumUgcService --> continuumUgcModerationWeb: success
continuumUgcModerationWeb --> ImageAdmin: { result: "ok" }

ImageAdmin -> continuumUgcModerationWeb: POST /user_images/accept { imageId }
continuumUgcModerationWeb -> continuumUgcService: images.action(id, action=approve, agentKey)
continuumUgcService --> continuumUgcModerationWeb: success
continuumUgcModerationWeb --> ImageAdmin: { result: "ok" }
```

## Related

- Architecture dynamic view: `dynamic-ugcModeration`
- Related flows: [Video Moderation](video-moderation.md)
- [Configuration](../configuration.md) for image reason ID mappings (`imageReasonIdToText`)
- [API Surface](../api-surface.md) for endpoint details
