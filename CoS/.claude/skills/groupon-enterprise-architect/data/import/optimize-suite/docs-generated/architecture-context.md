---
service: "optimize-suite"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumOptimizeSuiteClientBundle]
---

# Architecture Context

## System Context

Optimize Suite is a client-side JavaScript library that runs inside browsers on Groupon pages. It exists within the `continuumSystem` (Continuum Platform) as the browser-facing tracking and experimentation layer. End users interact with instrumented Groupon pages; Optimize Suite captures their behavior (impressions, clicks, interactions) and forwards enriched events to analytics platforms. It receives pre-processed experiment configuration from Optimize I-Tier Bindings (a server-side component) and resolves experiment variants locally. It also communicates cross-window via Optimize Portal when embedded in iframes.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Optimize Suite Client Bundle | `continuumOptimizeSuiteClientBundle` | Library / Frontend | JavaScript (Node.js/Webpack) | 2.18.0 | Browser-side optimize-suite bundle distributed via npm and loaded by host applications for tracking and experimentation initialization |

## Components by Container

### Optimize Suite Client Bundle (`continuumOptimizeSuiteClientBundle`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Optimize Suite Public API (`osPublicApi`) | Exports `init`, `initBloodhound`, and `treatAsNewPage` entry points; assembles runtime dependencies on `window.OptimizeSuite` | JavaScript module (`lib/components/optimize-suite.js`) |
| Initialization Orchestrator (`osInitOrchestrator`) | Initializes Finch, TrackingHub, ErrorCatcher, InteractionGoals, and Bloodhound in correct lifecycle order | JavaScript module (`lib/components/inits.js`) |
| Bloodhound Tracking Engine (`osBloodhoundEngine`) | Scans DOM widgets, captures impressions and clicks, emits tracking events to TrackingHub | JavaScript modules (`lib/components/bloodhound.js`, `lib/bloodhound/*`) |
| Analytics Adapter (`osAnalyticsAdapter`) | Builds Google Analytics dimensions from TrackingHub user/page data; emits GA purchase and subscription events; loads ClickTale for advanced analytics | JavaScript module (`lib/components/analytics.js`) |
| Config and Helper Utilities (`osConfigAndHelpers`) | Computes default config from browser cookies; manages session/browser identity cookies; performs browser detection and referral attribution | JavaScript modules (`lib/components/default-config.js`, `lib/components/helpers.js`, `lib/components/browser-detect.js`) |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `consumer` | `continuumOptimizeSuiteClientBundle` | Uses Groupon pages instrumented with optimize-suite | Browser session |
| `continuumOptimizeSuiteClientBundle` | `analyticsPlatforms` | Sends analytics events and dimensions | HTTP |
| `osPublicApi` | `osInitOrchestrator` | Calls init lifecycle and bootstrap flows | Function call |
| `osPublicApi` | `osBloodhoundEngine` | Initializes bloodhound tracking flows | Function call |
| `osPublicApi` | `osAnalyticsAdapter` | Initializes analytics and advanced analytics | Function call |
| `osInitOrchestrator` | `osConfigAndHelpers` | Reads defaults, cookies, and runtime config | Function call |
| `osInitOrchestrator` | `osAnalyticsAdapter` | Adds analytics dimensions during init | Function call |
| `osBloodhoundEngine` | `osConfigAndHelpers` | Reads helper utilities and persisted event IDs | Function call |

## Architecture Diagram References

- Container: `optimize_suite_container`
- Component: `optimize_suite_components`
