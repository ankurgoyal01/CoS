---
service: "optimize-suite"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [browser-dom-events, trackinghub-internal-event-bus]
---

# Events

## Overview

Optimize Suite does not use a traditional message broker (no Kafka, RabbitMQ, or SQS). Its event model operates at two levels: (1) internal in-process event emission via `optimize-evented` (an event-emitter pattern) between Bloodhound, TrackingHub, Finch, and other components; and (2) browser-level DOM custom events dispatched on `window` for consumption by host-page code. All events ultimately route through TrackingHub, which buffers and flushes them to the backend analytics tracking endpoint.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `window` DOM event | `optimize-bh-event` | Click or auxclick on a `data-bhw`/`data-bhc` element | `type`, `event.id`, `event.type`, `event.widgets[]`, `event.meta` |
| `window` DOM event | `optimize-bh-impression` | New `data-bhw`/`data-bhc` elements detected in viewport | `type`, `widgets[]` (with widget data payloads) |
| TrackingHub internal bus | `bloodhound` | Impression or interaction event from Bloodhound engine | `type` (`impression`/`event`/`error`), `widgets[]` or `event` object |
| TrackingHub internal bus | `finch-experiment` | Experiment variant resolved by Finch on page load | `layer`, `experiment`, `variant`, `bucket`, `customMetric` |
| TrackingHub internal bus | `uncaught-error` | Unhandled JavaScript error captured by ErrorCatcher | `message`, `stack`, `page_type`, `page_url`, `timestamp` (via TrackingHub) |
| TrackingHub internal bus | `sanity-check-failure` | SanityCheck invariant fails | `sanityCheck` (check name), additional context data |

### `optimize-bh-event` Detail

- **Topic**: `window` (browser custom DOM event)
- **Trigger**: User clicks (`click`, `auxclick`) or interacts with an element annotated with `data-bhw` or `data-bhc`
- **Payload**: `{ detail: { type: 'event', event: { id, type, widgets: [{ name, path, ... }], meta: { element_id, element_node, element_type, populated, checked } } } }`
- **Consumers**: Host-page JavaScript listeners; TrackingHub (via internal `bloodhound` event)
- **Guarantees**: at-most-once (browser event)

### `optimize-bh-impression` Detail

- **Topic**: `window` (browser custom DOM event)
- **Trigger**: Bloodhound periodic DOM scan detects new untracked widgets in viewport (default interval: 2000 ms)
- **Payload**: `{ detail: { type: 'impression', widgets: [{ name, path, content: [...], metadata: {...} }] } }`
- **Consumers**: Host-page JavaScript listeners; TrackingHub (via internal `bloodhound` event)
- **Guarantees**: at-most-once (browser event)

### `finch-experiment` Detail

- **Topic**: TrackingHub internal bus (submitted via `TrackingHub.add`)
- **Trigger**: Finch resolves an experiment variant during `initFinch`; each unique experiment fires once per session
- **Payload**: `{ layer, experiment, variant, bucket, customMetric }` or `{ layer, experiment, variant, error }` on failure
- **Consumers**: TrackingHub backend analytics pipeline
- **Guarantees**: at-most-once per session (de-duplicated by experiment name in session storage)

### `uncaught-error` Detail

- **Topic**: TrackingHub internal bus (submitted via `TrackingHub.add`)
- **Trigger**: Any uncaught JavaScript error on the page; ErrorCatcher listens on `window.onerror`
- **Payload**: `{ message, page_type, page_url }` plus TrackingHub-injected `timestamp` and `userAgent`
- **Consumers**: TrackingHub backend analytics pipeline; used by frontend teams for error monitoring
- **Guarantees**: at-most-once (best-effort browser error capture)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| Finch internal emitter | `run` | `inits.js` Finch `on('run')` handler | Stores experiment in session storage; adds GA dimension; submits `finch-experiment` to TrackingHub |
| Finch internal emitter | `guarded` | `inits.js` Finch `on('guarded')` handler | Adds `guarded` entry to Finch Portal for dev inspector |
| Finch internal emitter | `error` | `inits.js` Finch `on('error')` handler | Submits `finch-experiment` error event to TrackingHub; re-throws if not suppressing |
| TrackingHub internal emitter | `add` | `inits.js` TrackingHub `on('add')` handler | Forwards message to Optimize Portal `tracking-hub` channel |
| TrackingHub internal emitter | `flush` | `inits.js` TrackingHub `on('flush')` handler | Calls `TrackingHub.track(messages)` to POST to backend; forwards to Portal |
| InteractionGoals internal emitter | `purchase` | `analytics.js` GA binding | Sends GA Enhanced Ecommerce purchase hit |
| InteractionGoals internal emitter | `subscription` | `analytics.js` GA binding | Sends GA `interaction-goal / subscription` event |
| DOM `DOMContentLoaded` | — | `helpers.js runOnDomReady` | Triggers `Finch.run` after DOM is ready |
| DOM `load` | — | `helpers.js runOnWindowLoad` | Triggers Google Analytics snippet injection and ClickTale load |

## Dead Letter Queues

> Not applicable. Optimize Suite is a browser-side library and does not use message broker infrastructure with DLQ support.
