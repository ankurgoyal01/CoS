---
service: "itier-mobile"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest, http-redirect]
auth_mechanisms: [none, cookie]
---

# API Surface

## Overview

`itier-mobile` exposes a set of HTTP endpoints accessible through the Hybrid Boundary at `https://itier-mobile.production.service` (production) and `https://itier-mobile.staging.service` (staging). The API has four functional groups: dispatch/deep-link routing, mobile landing and download, app association files, and utility endpoints (localization, subscription). Most endpoints return either an HTML page (`200`) or an HTTP redirect (`302`). The SMS endpoint is the only `POST` action. No authentication is required for most routes; some use cookies for session context.

OpenAPI spec: `doc/openapi.yml` (OpenAPI 3.0.0)

## Endpoints

### App Association Files

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/.well-known/assetlinks.json` | Serves the Android App Links association file | None |
| GET | `/apple-app-site-association` | Serves the Apple Universal Links association file | None |

### Dispatch / Deep-Link Routing

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/dispatch` | Opens the Groupon native app (country-neutral) | None |
| GET | `/dispatch/{country}` | Opens native app for the given country code | None |
| GET | `/dispatch/{country}/deal/{dealId}` | Opens native app and navigates to a deal page | None |
| GET | `/dispatch/deal/{dealId}` | Opens native app and navigates to a deal page (country-neutral) | None |
| GET | `/dispatch/{country}/channel/{channelId}` | Opens native app and navigates to a channel page | None |
| GET | `/dispatch/channel/{channelId}` | Opens native app channel (country-neutral) | None |
| GET | `/dispatch/{country}/search` | Opens native app search results page | None |
| GET | `/dispatch/search` | Opens native app search (country-neutral) | None |
| GET | `/dispatch/{country}/bwf/{bwfId}` | Opens the Buy With Friends experience | None |
| GET | `/dispatch/bwf/{bwfId}` | Opens Buy With Friends (country-neutral) | None |
| GET | `/dispatch/{country}/profile/groupons/{voucherId}` | Opens native app voucher/my-groupons detail | None |
| GET | `/dispatch/profile/groupons/{voucherId}` | Opens voucher detail (country-neutral) | None |
| GET | `/dispatch/{country}/webview` | Renders or redirects to a web view URL inside the native app | None |
| GET | `/dispatch/webview` | Renders or redirects to a webview (country-neutral) | None |
| GET | `/dispatch/{country}/business` | Opens native app business page | None |
| GET | `/dispatch/business` | Opens business page (country-neutral) | None |
| GET | `/dispatch/US/browse_results` | Redirects to browse results filtered by `category_uuid` query param | None |

### Mobile Landing and Download

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/mobile` | Main landing page for mobile app downloads; detects UA and redirects or renders | None |
| GET | `/mobile/download` | Redirects to the appropriate app store download URL based on UA and `grpn_dl` param | None |
| GET | `/mobile/link` | Deep-link launcher; accepts `originalUrl` and `fallbackUrl`; redirects to `/` if params missing | Cookie (`division`) |
| POST | `/mobile/send_sms_message` | Sends an SMS to the user's phone with an app download or deep-link | None |
| GET | `/mobile/ipad` | iPad intercept page prompting app download | Cookie (`mobile_r`, `utm_content`) |
| GET | `/mobile/ipad_email_to_app` | iPad email-to-app intercept experience | Cookie (`ipad_native_exists`, `mobile_r`) |

### Utility

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/subscription` | Renders the subscription page | Cookie (`division`) |
| GET | `/v1/trees/-/{packageId}` | Serves legacy localization translation files | None |
| GET | `/v2/translations/{packageId}` | Serves current localization translation files | None |

## Request/Response Patterns

### Common headers

- `User-Agent` — used by `/mobile` and `/mobile/download` to detect iOS, Android, or iPad and select the correct dispatch strategy or app store link
- `Cache-Control` — set on association file responses to enable Akamai CDN caching (e.g., `public, max-age=300`)
- `Referer` — read by `/mobile/send_sms_message` to validate the request origin

### Error format

Endpoints return standard HTTP status codes. No structured JSON error envelope is defined in the OpenAPI spec. Redirect failures return a `302` to the appropriate fallback URL (e.g., `/` for `/mobile/link`).

### Pagination

> Not applicable — no paginated endpoints.

## Rate Limits

| Tier | Limit | Window |
|------|-------|--------|
| SMS (`/mobile/send_sms_message`) | Feature flag `rate_limiter: true` enabled | Per request (implementation internal) |

> No documented global rate limiting. SMS abuse mitigation is handled by the `rate_limiter` feature flag and IP-level blocking via the Global Security team.

## Versioning

Two localization endpoint prefixes exist (`/v1/trees` and `/v2/translations`) indicating path-based versioning for that resource group. All other endpoints are unversioned.

## OpenAPI / Schema References

- OpenAPI 3.0.0 spec: `doc/openapi.yml` (relative to repo root)
- Spec path registered in `.service.yml` as `open_api_schema_path: doc/openapi.yml`
- Dispatch endpoints also documented in `doc/endpoints.md`
