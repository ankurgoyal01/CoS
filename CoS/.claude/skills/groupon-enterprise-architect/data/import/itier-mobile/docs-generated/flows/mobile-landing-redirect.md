---
service: "itier-mobile"
title: "Mobile Landing and App Store Redirect"
generated: "2026-03-03"
type: flow
flow_name: "mobile-landing-redirect"
flow_type: synchronous
trigger: "User navigates to /mobile or /mobile/download"
participants:
  - "consumer"
  - "continuumItierMobileService"
architecture_ref: "components-continuumItierMobileService"
---

# Mobile Landing and App Store Redirect

## Summary

When a user arrives at `/mobile` or `/mobile/download`, the Mobile Controller detects the device platform from the `User-Agent` header and resolves the correct destination: iOS users are directed to the Apple App Store (via a Kochava attribution link if `grpn_dl` is present), Android users are directed to the Google Play Store, and desktop browsers receive the landing page rendering. The `/mobile/link` endpoint provides a deep-link launcher that attempts to open the native app with a fallback URL if the app is not installed.

## Trigger

- **Type**: user-action
- **Source**: User clicks a Groupon mobile download link from an email, ad campaign, web page, or customer care interaction
- **Frequency**: On-demand (per request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (browser) | Navigates to `/mobile`; receives page render or redirect to app store | `consumer` |
| itier-mobile service — Mobile Controller | Detects UA, resolves app store / Kochava link, renders or redirects | `continuumItierMobileService` |

## Steps

1. **Receives landing page request**: Consumer sends `GET /mobile` (optionally with `grpn_dl` query parameter for campaign tracking and UTM parameters).
   - From: `consumer`
   - To: `continuumItierMobileService`
   - Protocol: HTTPS

2. **Detects device platform**: Mobile Controller reads `User-Agent` header using `ua-parser-js` to classify the device as iPhone, Android, iPad, or desktop.
   - From: `continuumItierMobileService` (internal)
   - To: `continuumItierMobileService` (internal)
   - Protocol: In-process

3. **Resolves app store or campaign link**:
   - If `grpn_dl` query parameter is present, looks up the corresponding Kochava campaign link from `modules/mobile/DownloadLinks.js` for iOS attribution tracking
   - For iOS/iPhone: resolves Apple App Store link (or Kochava link)
   - For Android: resolves Google Play Store link with UTM campaign parameters
   - For desktop: renders the `/mobile` landing page HTML for the user's country/division
   - From: `continuumItierMobileService` (internal)
   - To: `continuumItierMobileService` (internal)
   - Protocol: In-process

4. **Renders page or issues redirect**: Returns either `302 Location` redirect (for mobile devices) or `200 text/html` (for desktop) using remote-layout for page scaffolding.
   - From: `continuumItierMobileService`
   - To: `consumer`
   - Protocol: HTTPS

### `/mobile/download` sub-flow

1. **Receives download redirect request**: Consumer sends `GET /mobile/download` with `User-Agent` header and optional `grpn_dl` parameter.
   - From: `consumer`
   - To: `continuumItierMobileService`
   - Protocol: HTTPS

2. **Resolves download URL**: Same UA detection and link resolution as `/mobile`, but always redirects — no page render.
   - From: `continuumItierMobileService` (internal)
   - To: `continuumItierMobileService` (internal)
   - Protocol: In-process

3. **Redirects to app store**: Issues `302` redirect to the resolved app store or campaign URL.
   - From: `continuumItierMobileService`
   - To: `consumer`
   - Protocol: HTTPS

### `/mobile/link` sub-flow

1. **Receives deep-link launcher request**: Consumer sends `GET /mobile/link?originalUrl=...&fallbackUrl=...` (with `division` cookie).
   - From: `consumer`
   - To: `continuumItierMobileService`
   - Protocol: HTTPS

2. **Validates parameters**: If `originalUrl` or `fallbackUrl` are missing, issues `302` redirect to `/`.
   - From: `continuumItierMobileService` (internal)
   - To: `continuumItierMobileService` (internal)
   - Protocol: In-process

3. **Renders link page**: Returns `200 text/html` with JS that attempts to open `originalUrl` (native app deep-link) and falls back to `fallbackUrl` if the app is not installed within the timeout.
   - From: `continuumItierMobileService`
   - To: `consumer`
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unknown `grpn_dl` value | No Kochava link found; falls back to default app store URL for the country | User redirected to App Store / Play Store without campaign attribution |
| Missing `originalUrl` or `fallbackUrl` on `/mobile/link` | Issues `302` redirect to `/` | User lands on Groupon homepage |
| Desktop browser on `/mobile/download` | Renders download page or redirects to default download URL | No crash; desktop experience served |
| `/mobile` under high load | GROUT team removes route group; traffic falls back to `legacyWeb` | `/mobile` served by `citydeal_app` |

## Sequence Diagram

```
Consumer -> continuumItierMobileService: GET /mobile[?grpn_dl=campaign_id&utm_*=...]
continuumItierMobileService -> continuumItierMobileService: Parse User-Agent (ua-parser-js)
continuumItierMobileService -> continuumItierMobileService: Resolve app store / Kochava link
continuumItierMobileService --> Consumer: HTTP 302 Location: {appStoreUrl} (mobile)
continuumItierMobileService --> Consumer: HTTP 200 text/html landing page (desktop)
Consumer -> AppStore/PlayStore: (browser follows redirect)
```

## Related

- Related flows: [SMS Download Link](sms-download-link.md), [iPad Intercept Experience](ipad-intercept.md)
- Architecture ref: `components-continuumItierMobileService`
- Campaign setup: `OWNERS_MANUAL.md` — "Adding a new campaign" section
