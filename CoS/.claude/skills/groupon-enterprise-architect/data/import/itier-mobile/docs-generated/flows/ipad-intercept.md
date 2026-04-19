---
service: "itier-mobile"
title: "iPad Intercept Experience"
generated: "2026-03-03"
type: flow
flow_name: "ipad-intercept"
flow_type: synchronous
trigger: "User with an iPad user-agent navigates to Groupon web"
participants:
  - "consumer"
  - "continuumItierMobileService"
architecture_ref: "components-continuumItierMobileService"
---

# iPad Intercept Experience

## Summary

When an iPad user visits Groupon's web experience, `itier-mobile` can render a full-screen intercept page encouraging the user to download or open the native iPad app. The Intercept Controller serves two routes: `/mobile/ipad` (standard intercept) and `/mobile/ipad_email_to_app` (for users arriving from email links who may already have the app installed). The behavior adapts based on cookies (`mobile_r`, `utm_content`, `ipad_native_exists`) and the `email_to_app_browse_ipad` feature flag. The intercept page is localised per market with country-specific imagery.

## Trigger

- **Type**: user-action
- **Source**: Routing layer or navigation logic detects iPad UA and redirects to `/mobile/ipad` or `/mobile/ipad_email_to_app`
- **Frequency**: On-demand (per eligible iPad session)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (iPad browser) | Navigates to Groupon web; receives intercept page or is redirected to continue on web | `consumer` |
| itier-mobile service — Intercept Controller | Evaluates cookies and feature flags; renders intercept page or issues redirect | `continuumItierMobileService` |
| Mobile Controller | Provides download link targets and app link construction for intercept page CTAs | `continuumItierMobileService` |

## Steps

### Standard iPad intercept (`/mobile/ipad`)

1. **Receives intercept request**: Consumer (iPad) sends `GET /mobile/ipad` with optional `mobile_r` and `utm_content` cookies and `utm_source`, `utm_medium`, `utm_campaign`, `utm_term` query parameters.
   - From: `consumer`
   - To: `continuumItierMobileService`
   - Protocol: HTTPS

2. **Evaluates feature flags and cookies**: Intercept Controller checks the `email_to_app_browse_ipad` feature flag. Reads `mobile_r` cookie to determine if the user has seen the intercept before (to avoid re-intercepting on return visits).
   - From: `continuumItierMobileService` (internal)
   - To: `continuumItierMobileService` (internal)
   - Protocol: In-process

3. **Builds app link targets**: Delegates to Mobile Controller to build the App Store link and native deep-link for the "Download App" and "Open App" CTAs on the intercept page.
   - From: `interceptController`
   - To: `mobileLandingController`
   - Protocol: In-process

4. **Renders intercept page**: Returns `200 text/html` intercept page with localized imagery (`ipad_{country}_hor.jpg` / `ipad_{country}_vert.jpg`) and CTAs. UTM parameters are forwarded for analytics tracking.
   - From: `continuumItierMobileService`
   - To: `consumer`
   - Protocol: HTTPS

### Email-to-app intercept (`/mobile/ipad_email_to_app`)

1. **Receives email-to-app request**: Consumer sends `GET /mobile/ipad_email_to_app` with `uri` query parameter (the deep-link destination), optional `ipad_native_exists` cookie, `mobile_r`, and UTM parameters.
   - From: `consumer`
   - To: `continuumItierMobileService`
   - Protocol: HTTPS

2. **Checks for existing native app**: Reads `ipad_native_exists` cookie to determine if the native iPad app was previously detected on the device.
   - From: `continuumItierMobileService` (internal)
   - To: `continuumItierMobileService` (internal)
   - Protocol: In-process

3. **Builds redirect targets**: Constructs native app deep-link from `uri` parameter and App Store fallback link.
   - From: `interceptController`
   - To: `mobileLandingController`
   - Protocol: In-process

4. **Renders email-to-app page**: Returns `200 text/html` intercept page that attempts to open the native app at the specified `uri`; falls back to App Store if app is not installed.
   - From: `continuumItierMobileService`
   - To: `consumer`
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `uri` parameter missing on `/mobile/ipad_email_to_app` | Controller handles missing parameter | Fallback to standard App Store redirect |
| `ipad_native_exists` cookie absent | Assumes no app installed | Shows download CTA rather than open-app CTA |
| Localized image not found for market | Falls back to default market images | Intercept page renders with default imagery |
| Feature flag `email_to_app_browse_ipad` disabled | Route may not render the email-to-app variant | User served standard intercept or web experience |

## Sequence Diagram

```
Consumer (iPad) -> continuumItierMobileService: GET /mobile/ipad[?utm_*=...] (mobile_r cookie)
continuumItierMobileService -> continuumItierMobileService: Check feature flags, read mobile_r cookie
interceptController -> mobileLandingController: Build App Store link and native deep-link
continuumItierMobileService --> Consumer: HTTP 200 text/html (intercept page with CTA)

Consumer (iPad, email link) -> continuumItierMobileService: GET /mobile/ipad_email_to_app?uri={deeplink}&utm_*=...
continuumItierMobileService -> continuumItierMobileService: Check ipad_native_exists cookie
interceptController -> mobileLandingController: Build deep-link and App Store fallback
continuumItierMobileService --> Consumer: HTTP 200 text/html (email-to-app intercept page)
```

## Related

- Architecture ref: `components-continuumItierMobileService`
- Component relationships: `interceptController -> mobileLandingController` (`architecture/models/components-relations.dsl`)
- Feature flag: `email_to_app_browse_ipad` — see [Configuration](../configuration.md)
- Related flows: [Mobile Landing and App Store Redirect](mobile-landing-redirect.md), [Dispatch Deep-Link Routing](dispatch-deep-link-routing.md)
