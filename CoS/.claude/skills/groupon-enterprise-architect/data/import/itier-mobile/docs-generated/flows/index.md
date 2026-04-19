---
service: "itier-mobile"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for I-Tier Mobile Redirect.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [SMS Download Link](sms-download-link.md) | synchronous | User submits phone number on `/mobile` page | Service receives phone number, constructs a download/deep-link, and delegates SMS delivery to Twilio |
| [Dispatch Deep-Link Routing](dispatch-deep-link-routing.md) | synchronous | Browser or native app opens a `/dispatch/{country}/*` URL | Service detects device OS (iOS/Android/default), constructs the appropriate deep-link destination, and redirects |
| [Mobile Landing and App Store Redirect](mobile-landing-redirect.md) | synchronous | User navigates to `/mobile` or `/mobile/download` | Service detects UA, resolves platform-specific app store or Kochava campaign link, and redirects or renders landing page |
| [Apple App Site Association Serving](app-association-serving.md) | synchronous | iOS device or Akamai CDN requests association files on app install/update | Service serves pre-signed Apple (`/apple-app-site-association`) or Android (`/.well-known/assetlinks.json`) association JSON with CDN cache headers |
| [iPad Intercept Experience](ipad-intercept.md) | synchronous | User with an iPad user-agent lands on Groupon web | Service detects iPad UA, checks for native app presence cookie, and renders an intercept page prompting app download or redirects |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- The SMS download flow is documented in the central architecture dynamic view: `dynamic-sms-download-flow` — see [SMS Download Link](sms-download-link.md)
- The dispatch routing flow spans `continuumItierMobileService` and optionally `legacyWeb` — see [Dispatch Deep-Link Routing](dispatch-deep-link-routing.md)
