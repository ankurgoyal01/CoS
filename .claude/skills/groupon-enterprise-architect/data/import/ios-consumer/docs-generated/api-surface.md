---
service: "ios-consumer"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest, apns]
auth_mechanisms: [oauth2, session-cookie, bcookie]
---

# API Surface

## Overview

> No evidence found in codebase.

The iOS Consumer App is a mobile client, not an API server. It does not expose HTTP endpoints for external consumption. All consumer-facing functionality is delivered through the native iOS UI. Backend API calls are made outbound to the `api-lazlo-sox` mobile API gateway.

## Endpoints

> Not applicable — this service is a mobile application and does not expose HTTP endpoints.

## Request/Response Patterns

### Common headers

> No evidence found in codebase.

The app communicates with `api-lazlo-sox` using standard HTTPS. Authentication is established via session cookies and `bcookie`, stored in the iOS Keychain and NSUserDefaults under `GROUPON_COOKIES_SAVED_BCOOKIE_KEY_V2`. Auth tokens are stored in the Keychain under the `LEGACY_AUTH_TOKEN_KEY` constant.

### Error format

> No evidence found in codebase.

### Pagination

> No evidence found in codebase.

## Rate Limits

> Not applicable — this service is a mobile client and does not impose rate limits.

## Versioning

The app uses a `Major.Minor(.Patch)` versioning scheme managed by Fastlane (`nx bump-version mobile-expo`). Release branches follow the pattern `release/Major.Minor`. The version is tracked in `NSUserDefaults` under `lastAppVersion`.

## OpenAPI / Schema References

> Not applicable — the iOS Consumer App does not own an API schema. Backend API contracts are owned by `api-lazlo-sox`.
