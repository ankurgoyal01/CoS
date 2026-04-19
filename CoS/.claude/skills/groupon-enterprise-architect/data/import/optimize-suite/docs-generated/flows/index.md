---
service: "optimize-suite"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Optimize Suite.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Suite Initialization](suite-initialization.md) | synchronous | Host application calls `window.OptimizeSuite.init(config)` | Bootstraps all tracking and experimentation subsystems in the correct lifecycle order |
| [Bloodhound Widget Tracking](bloodhound-widget-tracking.md) | event-driven | DOM scan or mutation detects new `data-bhw`/`data-bhc` elements | Discovers tracked widgets in the viewport and emits impression events to TrackingHub |
| [Click and Interaction Capture](click-interaction-capture.md) | event-driven | User clicks or interacts with a `data-bhw`/`data-bhc` element | Captures widget click events, enriches with widget hierarchy and element metadata, submits to TrackingHub |
| [Experiment Variant Resolution](experiment-variant-resolution.md) | synchronous | Finch initializes on page load and DOM ready | Resolves A/B experiment variants from pre-processed Birdcage config, tracks assignments, applies custom analytics dimensions |
| [SPA Page Transition](spa-page-transition.md) | synchronous | Host application calls `window.OptimizeSuite.treatAsNewPage(url, newConfig)` | Resets TrackingHub page state and re-scans widgets for single-page application route changes |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 0 |
| Event-driven (DOM/internal) | 1 |

## Cross-Service Flows

- The **Suite Initialization** flow depends on Optimize I-Tier Bindings having pre-assembled and injected the config object server-side before optimize-suite initializes.
- The **Experiment Variant Resolution** flow depends on Birdcage experiment configuration having been fetched and processed by Optimize I-Tier Bindings.
- All tracking events ultimately flow through TrackingHub to backend analytics pipelines — cross-service flows beyond optimize-suite are tracked in the central architecture model.
