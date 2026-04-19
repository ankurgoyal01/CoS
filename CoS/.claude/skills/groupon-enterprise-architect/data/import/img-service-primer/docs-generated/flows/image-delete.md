---
service: "img-service-primer"
title: "Image Delete"
generated: "2026-03-03"
type: flow
flow_name: "image-delete"
flow_type: synchronous
trigger: "Operator HTTP POST to /v1/images"
participants:
  - "imageResource"
  - "imagePreloadingService"
  - "akamaiClient"
  - "akamai"
architecture_ref: "components-continuumImageServicePrimer"
---

# Image Delete

## Summary

The image delete flow allows authorized operators to remove an image from all storage and cache layers managed or warmed by the Image Service ecosystem. A single POST to `/v1/images` with a transformed image URL triggers deletion from AWS S3 (image asset storage), GIMS nginx caches, and the Akamai CDN. Authorization is enforced by LDAP group membership passed via the `x-grpn-groups` HTTP header. The delete form is also accessible via a UI at `https://gims-primer-us.groupondev.com/html/complete_image_delete.html`.

## Trigger

- **Type**: api-call
- **Source**: Operator via HTTP POST or the web-based delete form
- **Frequency**: On demand (manual operator action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `ImageResource` | Receives the image delete request; validates LDAP group authorization | `imageResource` |
| `ImagePreloadingService` | Coordinates the multi-target delete operations | `imagePreloadingService` |
| `AkamaiClient` | Issues cache purge/invalidation request to Akamai | `akamaiClient` |
| Akamai CDN | CDN that receives the purge/invalidation request | `akamai` |

> Note: S3 deletion and GIMS nginx cache purge are referenced in the OWNERS_MANUAL and architecture DSL relations. Exact internal components handling those operations are not individually named in the DSL but are coordinated by `ImagePreloadingService`.

## Steps

1. **Receive delete request**: `ImageResource` accepts the `POST /v1/images` request with a transformed image URL in the request body (form-encoded). The `x-grpn-username` and `x-grpn-groups` headers are checked for LDAP group authorization.
   - From: Operator
   - To: `imageResource`
   - Protocol: REST/HTTP (`application/x-www-form-urlencoded`)

2. **Validate authorization**: `ImageResource` verifies the caller is a member of the required LDAP group (`gims-primer-us.groupondev.com` or `gims-primer-staging.groupondev.com`).
   - From: `imageResource` (in-process)

3. **Delete from S3**: The service removes the image asset from the AWS S3 bucket used by Image Service.
   - From: `imagePreloadingService` / S3 delete logic
   - To: AWS S3
   - Protocol: S3 API

4. **Purge GIMS nginx caches**: The service issues a cache purge request to GIMS to invalidate the image from its nginx-backed caches.
   - From: `imagePreloadingService`
   - To: `gims`
   - Protocol: HTTP

5. **Purge Akamai CDN**: `AkamaiClient` issues a cache purge/invalidation request to Akamai for the specified image URL.
   - From: `akamaiClient`
   - To: `akamai`
   - Protocol: HTTPS (EdgeGrid-signed)

6. **Return response**: `ImageResource` returns the operation result to the caller.
   - From: `imageResource`
   - To: Operator
   - Protocol: REST/HTTP (JSON response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing or invalid LDAP group | Request rejected by `ImageResource` | Operator receives authorization error; must use correct LDAP group |
| Invalid image URL format | Request may be rejected or partially processed | Operator should use the correct transformed URL format: `https://img.grouponcdn.com/{test}/{sha}/{name}/v1/{transformCode}` |
| S3 delete fails | Error logged | Image remains in S3; operator must retry |
| Akamai purge fails | Error logged | CDN may serve stale image until TTL expiry; report to info-sec team |
| GIMS cache purge fails | Error logged | GIMS may serve cached image; GIMS team should be contacted |

## Sequence Diagram

```
Operator -> ImageResource: POST /v1/images (form body: transformed image URL)
ImageResource -> ImageResource: Validate x-grpn-groups (LDAP authorization)
ImageResource -> ImagePreloadingService: Coordinate image deletion
ImagePreloadingService -> S3: Delete image asset (S3 API)
S3 --> ImagePreloadingService: Delete confirmation
ImagePreloadingService -> gims: Purge nginx cache (HTTP)
gims --> ImagePreloadingService: Cache purge confirmation
ImagePreloadingService -> AkamaiClient: Issue purge/invalidation request
AkamaiClient -> akamai: HTTPS purge (EdgeGrid-signed)
akamai --> AkamaiClient: Purge confirmation
ImagePreloadingService --> ImageResource: Deletion complete
ImageResource --> Operator: JSON response
```

## Related

- Architecture component view: `components-continuumImageServicePrimer`
- Related flows: [Daily Image Priming](daily-image-priming.md), [Manual Deal Preload](manual-deal-preload.md)
- API reference: [API Surface](../api-surface.md) — `POST /v1/images`
- Delete UI: `https://gims-primer-us.groupondev.com/html/complete_image_delete.html`
