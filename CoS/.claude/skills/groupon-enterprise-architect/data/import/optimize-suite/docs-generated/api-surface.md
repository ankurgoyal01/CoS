---
service: "optimize-suite"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [javascript-api, browser-dom-events]
auth_mechanisms: [cookie-based]
---

# API Surface

## Overview

Optimize Suite does not expose HTTP endpoints. Its public surface is a JavaScript API attached to `window.OptimizeSuite` in the browser. Host applications initialize the suite by calling `window.OptimizeSuite.init(config)` and then `window.OptimizeSuite.initBloodhound()` when the DOM is ready. For SPA navigation, `window.OptimizeSuite.treatAsNewPage(url, newConfig)` resets tracking state without a full page reload. The bundle also exposes library references (`TrackingHub`, `Bloodhound`, `Finch`, `Evented`, `SanityCheck`, `Warehouse`, `Portal`) for direct use by host-application code.

## Endpoints

### `window.OptimizeSuite` — Public JavaScript API

| Method / Property | Signature | Purpose | Auth |
|-------------------|-----------|---------|------|
| `init` | `init(config: Object) → void` | Bootstraps all tracking and experimentation subsystems (TrackingHub, Finch, ErrorCatcher, InteractionGoals, Google Analytics) | Cookie-based identity |
| `initBloodhound` | `initBloodhound() → Bloodhound` | Instantiates the Bloodhound engine and begins periodic DOM scanning for tracked widgets | None |
| `treatAsNewPage` | `treatAsNewPage(url: string, newConfig?: Object) → void` | Resets TrackingHub page state and re-scans widgets for SPA navigation; debounced at 1000 ms | Cookie-based identity |
| `bloodhoundWait` | `bloodhoundWait() → boolean` | Pauses Bloodhound impression scanning (call before `initBloodhound`) | None |
| `isBloodhoundPaused` | `isBloodhoundPaused() → boolean` | Returns current pause state of Bloodhound | None |
| `version` | `string` | Current bundle version string (replaced at build time from `package.json`) | None |
| `TrackingHub` | Library reference | Exposes the initialized TrackingHub instance for direct event submission | None |
| `Bloodhound` | Library reference | Exposes the Bloodhound class for custom tracking integrations | None |
| `Finch` | Library reference | Exposes the Finch experiment runner | None |
| `InteractionGoals` | Library reference | Exposes the typed interaction-goals instance | None |
| `Evented` | Library reference | Exposes the Evented event-emitter utility | None |
| `SanityCheck` | Library reference | Exposes the SanityCheck runtime validation instance | None |
| `Warehouse` | Library reference | Exposes the TrackingHub.Warehouse storage utility | None |

### `init(config)` — Configuration Object Shape

| Key | Type | Purpose |
|-----|------|---------|
| `user` | Object | User identity fields: `consumerId`, `browserId`, `scid`, `loggedIn`, `platform`, etc. |
| `page` | Object | Page metadata: `url`, `parentEventId`, `parentPageId`, `type`, `metadata` |
| `session` | Object | Session data: `id`, `sessionCookie.key`, `referrer` |
| `finch` | Object | Experiment config: `config`, `debug`, `alwaysFirePixel`, `trackers` |
| `bloodhound` | Object | Bloodhound options: `devMode`, `widgetKey`, `contentKey`, `updateInterval` |
| `trackingHub` | boolean | Whether to initialize TrackingHub |
| `errorCatcher` | boolean | Whether to initialize ErrorCatcher |
| `sanityCheck` | boolean | Whether to initialize SanityCheck |
| `googleAnalyticsTrackingId` | string | UA or GA4 tracking ID for Google Analytics |
| `advancedAnalytics` | Object | ClickTale config: `enabled`, `serverDimensions` |
| `cookieDomain` | string | Cookie domain override |
| `devMode` | boolean | Enables inspector overlay and throws errors instead of suppressing |
| `suppressErrors` | boolean | Suppresses thrown errors from sub-libraries (auto-set from `devMode`) |
| `flushInterval` | number | TrackingHub flush interval in milliseconds |
| `referralMap` | Object | Custom UTM-style query parameter → referral field mapping |

### Bloodhound DOM Attribute API

| Attribute | Purpose |
|-----------|---------|
| `data-bhw="<widget-name>"` | Marks an HTML element as a tracked widget; value is the widget name |
| `data-bhc="<content-name>"` | Marks an element as tracked content within a widget |
| `data-bhd` | Additional data attribute observed by MutationObserver for widget lifecycle |
| `data-bhclick="<click-type>"` | Tags the click type on a widget element for click event metadata |

### Published DOM Events (Browser)

| Event Name | Target | Payload `detail` | Description |
|------------|--------|-------------------|-------------|
| `optimize-bh-event` | `window` | `{ type: 'event', event: { id, type, widgets, meta } }` | Fired on click/auxclick interactions with tracked widgets |
| `optimize-bh-impression` | `window` | `{ type: 'impression', widgets: [...] }` | Fired when new tracked widgets enter the viewport |

## Request/Response Patterns

### Common headers

> Not applicable — this is a browser JavaScript library, not an HTTP service.

### Error format

Errors from sub-libraries are captured by ErrorCatcher and submitted to TrackingHub as `uncaught-error` events containing `message`, `page_type`, and `page_url` fields.

### Pagination

> Not applicable.

## Rate Limits

> No rate limiting configured at the Optimize Suite library layer. Rate limiting is handled at the analytics endpoint level (Google Analytics, ClickTale, TrackingHub backend).

## Versioning

The bundle is versioned via npm semantic versioning (`package.json` `version` field, currently `2.18.0`). The version string is embedded in the built bundle at Webpack compile time by replacing the `%optimize_version%` placeholder. Consumers upgrade by bumping the `optimize-suite` npm dependency in Layout Service's `package.json`.

## OpenAPI / Schema References

> No OpenAPI spec exists. The JavaScript API is documented at `https://github.groupondev.com/optimize/optimize-suite/wiki/Optimize-Suite-API`.
