---
service: "my_appointments_client"
title: "Widget Bootstrap"
generated: "2026-03-03"
type: flow
flow_name: "widget-bootstrap"
flow_type: synchronous
trigger: "Groupon.com page loads with embedded booking widget script tag"
participants:
  - "myAppts_jsApiController"
  - "myAppts_bookingFrontend"
  - "myAppts_requestModules"
architecture_ref: "dynamic-dynamics-continuum-my-appointments-client-reservation"
---

# Widget Bootstrap

## Summary

The Widget Bootstrap flow handles the initialization of the Preact booking widget embedded on Groupon.com deal pages. An external host page references the widget script via a URL obtained from `/mobile-reservation/next/jsapi-script-url`. The JS API Controller returns the CDN-hosted JS and CSS asset URLs, a CSRF token, feature-flag values, and the user's login state. The browser then loads the widget assets and initializes the booking experience.

## Trigger

- **Type**: api-call
- **Source**: Groupon.com deal page or embedding host page requests widget bootstrap metadata by calling `GET /mobile-reservation/next/jsapi-script-url`
- **Frequency**: On-demand, per page load that includes the booking widget

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Embedding Host Page | External Groupon.com page that needs to load the booking widget | External consumer |
| JS API Controller | Returns asset URLs, CSRF token, feature flags, and user login state | `myAppts_jsApiController` |
| Request Module Registry | Provides `urlHelpers` (CDN asset URL resolver), `featureFlags`, `userAuth`, and `csrfToken` | `myAppts_requestModules` |
| Booking Widget Frontend | Preact widget loaded from CDN; uses the bootstrap payload to initialize booking UI | `myAppts_bookingFrontend` |

## Steps

1. **Host page requests bootstrap metadata**: Groupon.com deal page (or any embedding page) sends `GET /mobile-reservation/next/jsapi-script-url`. The request includes an `Origin` or `Host` header. CORS headers (`Access-Control-Allow-Origin`, `Access-Control-Allow-Credentials`, `Access-Control-Allow-Methods: GET`) are set by the service's CORS middleware for this path prefix.
   - From: Browser (embedding host page)
   - To: `myAppts_jsApiController`
   - Protocol: HTTPS/JSON

2. **Controller resolves asset URLs**: JS API Controller calls `urlHelpers.assetUrl('jsapi.js')` and `urlHelpers.assetUrl('jsapi.css')` from `itier-assets` to resolve the fingerprinted CDN URLs for the current build's widget bundle.
   - From: `myAppts_jsApiController`
   - To: `myAppts_requestModules` (`urlHelpers`)
   - Protocol: Direct (in-process)

3. **Controller reads auth state**: `userAuth.extractAccessTokenOrNull()` determines whether the user is currently logged in, setting `userIsLoggedIn` in the payload.
   - From: `myAppts_jsApiController`
   - To: `myAppts_requestModules` (`userAuth`)
   - Protocol: Direct (in-process)

4. **Controller reads feature flags**: `featureFlags.enabled('bookingConstraint')` and `featureFlags.enabled('availabilityPreviewEnhancements')` are evaluated to populate the feature-flag payload.
   - From: `myAppts_jsApiController`
   - To: `myAppts_requestModules` (`featureFlags`)
   - Protocol: Direct (in-process)

5. **Controller returns bootstrap JSON**: Response includes `url` (widget JS CDN URL), `styleUrl` (widget CSS CDN URL), `csrfToken`, and a `payload` object containing `userIsLoggedIn`, `csrfToken`, `featureFlags`, and `clientSideTranslationQueryString`.
   - From: `myAppts_jsApiController`
   - To: Browser (embedding host page)
   - Protocol: HTTPS/JSON

6. **Browser loads widget assets**: Host page uses the returned `url` to inject a `<script>` tag loading the Preact booking widget bundle from the Groupon CDN (`www<1,2>.grouponcdn.com` in production).
   - From: Browser
   - To: Groupon CDN
   - Protocol: HTTPS

7. **Widget initializes with payload**: The Preact booking widget bootstraps using the returned `payload` data, establishing CSRF token state, feature-flag awareness, and user login state before making any reservation API calls.
   - From: `myAppts_bookingFrontend` (widget runtime)
   - To: Browser DOM
   - Protocol: JavaScript execution

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing `Origin`/`Host` header | CORS headers not set (non-blocking) | Widget still loads but CORS checks may fail on subsequent calls |
| Asset URL resolution failure | `urlHelpers.assetUrl` returns null or throws | Widget JS/CSS URL is empty; browser fails to load widget |
| User auth token missing | `userAuth.extractAccessTokenOrNull()` returns null | `userIsLoggedIn: false` in payload; widget shows logged-out state |
| Feature flag service unavailable | Flags return defaults | Widget loads with default feature behavior |

## Sequence Diagram

```
HostPage -> JSApiController: GET /mobile-reservation/next/jsapi-script-url
JSApiController -> RequestModules: Resolve assetUrl('jsapi.js'), assetUrl('jsapi.css')
JSApiController -> RequestModules: extractAccessTokenOrNull()
JSApiController -> RequestModules: featureFlags.enabled('bookingConstraint')
JSApiController -> RequestModules: featureFlags.enabled('availabilityPreviewEnhancements')
JSApiController --> HostPage: 200 OK {url, styleUrl, csrfToken, payload}
HostPage -> GrouponCDN: Load jsapi.js (widget bundle)
GrouponCDN --> HostPage: Widget JS
BookingWidget -> HostPage: Initialize with payload (userIsLoggedIn, featureFlags, csrfToken)
```

## Related

- Architecture dynamic view: `dynamic-dynamics-continuum-my-appointments-client-reservation`
- Related flows: [Reservation Creation](reservation-creation.md), [Mobile Webview Page Load](mobile-webview-load.md)
