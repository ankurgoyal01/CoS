---
service: "itier-mobile"
title: "Apple App Site Association Serving"
generated: "2026-03-03"
type: flow
flow_name: "app-association-serving"
flow_type: synchronous
trigger: "iOS device or Android OS requests app association files on app install or update"
participants:
  - "consumer"
  - "continuumItierMobileService"
architecture_ref: "components-continuumItierMobileService"
---

# Apple App Site Association Serving

## Summary

iOS and Android operating systems fetch app association files from well-known URLs when a user installs or updates the native Groupon app. These files authorize the native app to handle Universal Links (iOS) and App Links (Android) for the Groupon domain. `itier-mobile` serves both files from its App Association Controller, sets appropriate `Cache-Control` headers for Akamai CDN caching (~500k requests/day for the Apple file), and the iOS file must be pre-signed with the Groupon domain's TLS certificate. Akamai has a special exception configured to cache the `/apple-app-site-association` path.

## Trigger

- **Type**: user-action (OS-initiated on app install or update)
- **Source**: iOS OS (`/apple-app-site-association`), Android OS (`/.well-known/assetlinks.json`), or Akamai CDN cache miss
- **Frequency**: Per app install/update event (high volume — ~500k/day for Apple file as of 2015 baseline)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (iOS/Android OS or Akamai) | Requests the association file for the domain | `consumer` |
| itier-mobile service — App Association Controller | Serves pre-built signed (Apple) or plain (Android) JSON association file with CDN cache headers | `continuumItierMobileService` |

## Steps

### Apple Universal Links flow

1. **Receives association file request**: iOS OS or Akamai CDN sends `GET /apple-app-site-association` to the Groupon domain.
   - From: `consumer`
   - To: `continuumItierMobileService`
   - Protocol: HTTPS

2. **Selects correct association file**: App Association Controller selects the appropriate signed Apple App Site Association file based on the request domain (US, Japan, or non-US Groupon domain), from `modules/appassociation/`.
   - From: `continuumItierMobileService` (internal)
   - To: `continuumItierMobileService` (internal)
   - Protocol: In-process

3. **Returns signed JSON with cache headers**: Responds `200 application/json` with the signed binary association file and `Cache-Control: public, max-age=300` so Akamai caches it.
   - From: `continuumItierMobileService`
   - To: `consumer`
   - Protocol: HTTPS

### Android App Links flow

1. **Receives asset links request**: Android OS or Akamai CDN sends `GET /.well-known/assetlinks.json`.
   - From: `consumer`
   - To: `continuumItierMobileService`
   - Protocol: HTTPS

2. **Serves asset links file**: App Association Controller returns the appropriate `assetlinks.groupon.js` or `assetlinks.livingsocial.js` JSON response with `Cache-Control` header.
   - From: `continuumItierMobileService`
   - To: `consumer`
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Association file not signed / expired TLS cert | App association may fail OS validation | Universal Links stop working for the domain; iOS team must regenerate and re-sign |
| Akamai not caching the Apple file | File served directly from pods on every iOS install | High origin load (~500k/day); contact Akamai/ops to confirm exception is active |
| Deploy of association file changes near iOS app launch | Timing risk — iOS apps launch worldwide simultaneously | Schedule deploys for all data centers on the same day; request TDO permission |

## Sequence Diagram

```
Consumer (iOS OS) -> continuumItierMobileService: GET /apple-app-site-association
continuumItierMobileService -> continuumItierMobileService: Select domain-specific signed file
continuumItierMobileService --> Consumer: HTTP 200 application/json (signed file, Cache-Control: public, max-age=300)
Consumer (iOS OS) -> continuumItierMobileService: (Akamai caches; subsequent requests served from CDN)

Consumer (Android OS) -> continuumItierMobileService: GET /.well-known/assetlinks.json
continuumItierMobileService --> Consumer: HTTP 200 application/json (assetlinks, Cache-Control header)
```

## Related

- Architecture ref: `components-continuumItierMobileService`
- File sources: `modules/appassociation/apple-app-site-association.us.js`, `modules/appassociation/apple-app-site-association.jp.js`, `modules/appassociation/apple-app-site-association.non-us.js`, `modules/appassociation/assetlinks.groupon.js`, `modules/appassociation/assetlinks.livingsocial.js`
- Deploy notes: `OWNERS_MANUAL.md` — "Deploying Apple App Site Association changes" section
- Related flows: [Dispatch Deep-Link Routing](dispatch-deep-link-routing.md)
