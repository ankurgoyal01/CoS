---
service: "itier-mobile"
title: "Dispatch Deep-Link Routing"
generated: "2026-03-03"
type: flow
flow_name: "dispatch-deep-link-routing"
flow_type: synchronous
trigger: "Browser or native app opens a /dispatch/{country}/* URL"
participants:
  - "consumer"
  - "continuumItierMobileService"
  - "legacyWeb"
architecture_ref: "components-continuumItierMobileService"
---

# Dispatch Deep-Link Routing

## Summary

The dispatch flow resolves inbound `/dispatch/{country}/*` URLs to the correct destination for the user's device. On iOS, the service constructs a Universal Link that the OS intercepts to open the native app at the correct screen. On Android, an App Link redirect is generated. On desktop/unknown browsers, the service redirects to the equivalent Groupon web page. Route types include: app open, deal page, channel page, search results, Buy With Friends, voucher/my-groupons, webview, and business page.

## Trigger

- **Type**: user-action or api-call
- **Source**: User or native app follows a `/dispatch/{country}/*` URL (e.g., from an email, ad campaign, or in-app link)
- **Frequency**: On-demand (per request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (browser or native app) | Initiates the dispatch request; receives redirect or HTML response | `consumer` |
| itier-mobile service — Dispatch Controller | Detects OS, selects dispatcher strategy, computes redirect destination | `continuumItierMobileService` |
| legacyWeb (citydeal_app) | Receives fallback redirect for desktop/default browser traffic | `legacyWeb` |

## Steps

1. **Receives dispatch request**: Consumer sends `GET /dispatch/{country}/{route}` (e.g., `/dispatch/US/deal/some-deal-permalink`).
   - From: `consumer`
   - To: `continuumItierMobileService`
   - Protocol: HTTPS

2. **Detects device OS**: Dispatch Controller reads the `User-Agent` header using `ua-parser-js` and classifies the device as iOS (iPhone/iPad-like), Android, or default (desktop/unknown).
   - From: `continuumItierMobileService` (internal)
   - To: `continuumItierMobileService` (internal)
   - Protocol: In-process

3. **Selects dispatcher strategy**: Based on OS classification, selects one of three dispatcher objects: `iOSDispatcher`, `androidDispatcher`, or `defaultDispatcher`.
   - From: `continuumItierMobileService` (internal)
   - To: `continuumItierMobileService` (internal)
   - Protocol: In-process

4. **Computes redirect destination**: The selected dispatcher transforms the inbound URL path to the correct target:
   - **Deal**: `/dispatch/{country}/deal/{dealId}` → `{baseUrl}/deals/{dealId}`
   - **Channel**: `/dispatch/{country}/channel/{channelId}` → `{baseUrl}/{channelId}`
   - **Search**: `/dispatch/{country}/search?q=...` → `{baseUrl}/browse?...` (occasion parameter mapped to `/occasion/{theme}`)
   - **Voucher**: `/dispatch/{country}/profile/groupons/{voucherId}` → `{baseUrl}/mygroupons/details/{voucherId}`
   - **BWF**: `/dispatch/{country}/bwf/{bwfId}` → `{baseUrl}/{bwfId}`
   - **Webview (iOS)**: Generates inline HTML with JS redirect + iframe to `groupon:///dispatch/us/webview?url=...`
   - **Webview (Android)**: Decodes the `url` parameter and redirects directly
   - **Business**: `/dispatch/{country}/business` → `{baseUrl}/biz/...`
   - **Browse results**: `/dispatch/US/browse_results?category_uuid={uuid}` → `/browse?category={cat}&...`
   - **Base (app open)**: `/dispatch/{country}` → `{baseUrl}/` (country site root)
   - From: `continuumItierMobileService` (internal)
   - To: `continuumItierMobileService` (internal)
   - Protocol: In-process

5. **Responds with redirect or HTML**: Returns `302 Location` redirect to the computed URL, or `200 text/html` for webview routes.
   - From: `continuumItierMobileService`
   - To: `consumer`
   - Protocol: HTTPS

6. **Fallback (desktop default dispatcher)**: For desktop browsers, `defaultDispatcher` strips the `/dispatch/{country}` prefix and redirects to the equivalent full-site URL (e.g., `https://www.groupon.de/deals/{dealId}`). If `/mobile` routes are under heavy load, the GROUT team can remove the `mobile_redirect` route group and legacyWeb handles the traffic instead.
   - From: `continuumItierMobileService`
   - To: `legacyWeb`
   - Protocol: HTTPS redirect (via browser)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unknown country code | Uses `default` site config from `config/stage/*.cson` | Redirects to `www.groupon.com` |
| Unknown category UUID (`/dispatch/US/browse_results`) | `CAT_PERMALINKS` lookup returns null | `dispatchCategory` returns null; handled by controller |
| Android EMEA traffic via `/dispatch` | Android only registers `www.groupon.com`; EMEA forced to US domain | ~300ms additional latency; app still opens |
| High load on `/mobile/*` routes | GROUT team removes route group from itier-mobile routing | `/mobile` traffic falls back to `legacyWeb` (`citydeal_app`) |

## Sequence Diagram

```
Consumer -> continuumItierMobileService: GET /dispatch/{country}/{route}[?params]
continuumItierMobileService -> continuumItierMobileService: Parse User-Agent (ua-parser-js)
continuumItierMobileService -> continuumItierMobileService: Select dispatcher (iOS / Android / default)
continuumItierMobileService -> continuumItierMobileService: Compute redirect destination URL
continuumItierMobileService --> Consumer: HTTP 302 Location: {destination} (or 200 HTML for webview)
Consumer -> legacyWeb: (desktop fallback) browser follows redirect to full-site URL
```

## Related

- Architecture ref: `components-continuumItierMobileService`
- Dispatch endpoint documentation: `doc/endpoints.md`
- Related flows: [Mobile Landing and App Store Redirect](mobile-landing-redirect.md)
- Configuration: `dispatch.env` in `config/stage/*.cson`, `sites` per-country map
