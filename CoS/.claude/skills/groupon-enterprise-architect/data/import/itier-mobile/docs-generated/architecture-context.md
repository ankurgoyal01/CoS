---
service: "itier-mobile"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumItierMobileService"]
---

# Architecture Context

## System Context

`itier-mobile` is a container within the `continuumSystem` (Groupon's legacy/modern commerce engine). It sits at the edge of the Continuum platform, acting as the mobile web gateway. Web browsers and native apps reach it via Akamai CDN and the Hybrid Boundary ingress layer. The service dispatches inbound requests to native app deep-links (iOS Universal Links, Android App Links), delivers the `/mobile` download experience, and delegates SMS sending to Twilio. When `/mobile` traffic volume exceeds capacity, the GROUT routing-service can redirect those routes to the legacyWeb (`citydeal_app`) frontend as a fallback.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| itier-mobile service | `continuumItierMobileService` | Service | Node.js / itier-server | 16.16.0 / ^7.14.0 | Handles /dispatch, /mobile, subscription pages, app association files, and SMS download endpoints |

## Components by Container

### itier-mobile service (`continuumItierMobileService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Dispatch Controller | Routes `/dispatch*` requests to deep-link or fallback destinations based on country, device OS (iOS/Android/default), and route context (deal, channel, search, voucher, BWF, webview, business) | Node.js module (`modules/dispatch`) |
| Mobile Controller | Renders `/mobile` routes, resolves platform-specific app store links, serves landing/link/download pages, and tracks Kochava campaigns via `grpn_dl` | Node.js module (`modules/mobile`) |
| SMS Controller | Handles `POST /mobile/send_sms_message`, constructs Twilio payload with download/deep-link, and delegates delivery | Node.js module (`modules/sms`) |
| Intercept Controller | Serves iPad intercept experiences (`/mobile/ipad`, `/mobile/ipad_email_to_app`) and decides app/web redirect behavior | Node.js module (`modules/intercept`) |
| Subscription Controller | Serves the `/subscription` page experience | Node.js module (`modules/subscription`) |
| App Association Controller | Serves Apple App Site Association (`/apple-app-site-association`) and Android asset links (`/.well-known/assetlinks.json`) for Universal Links / App Links | Node.js module (`modules/appassociation`) |
| Localization Controller | Serves v1 and v2 localization translation assets for mobile clients | Node.js module (`modules/localize`) |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `consumer` | `continuumItierMobileService` | Requests mobile and dispatch routes | HTTPS |
| `continuumItierMobileService` | `twilio` | Sends SMS messages with app download links | HTTPS |
| `twilio` | `consumer` | Delivers SMS to the user's device | SMS |
| `continuumItierMobileService` | `legacyWeb` | Redirects /mobile traffic as fallback during high load or ownership changes | HTTPS |

## Architecture Diagram References

- Component view: `components-continuumItierMobileService`
- Dynamic view (SMS download flow): `dynamic-sms-download-flow`
