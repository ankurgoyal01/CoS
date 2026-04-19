---
service: "subscription-programs-itier"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Select I-Tier (subscription-programs-itier).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Select Landing Page](select-landing-page.md) | synchronous | HTTP GET from browser | Renders the Groupon Select landing page with current membership state and offer variant |
| Subscription Enrollment | synchronous | HTTP POST from browser | Processes a new Groupon Select subscription enrollment through payment and confirmation |
| Membership Status Poll | synchronous | Browser AJAX GET after enrollment submit | Polls enrollment/membership status until confirmation or failure is determined |
| Benefits Display | synchronous | HTTP GET from browser | Renders the Select member benefits page for authenticated members |
| Embedded Webview Flow | synchronous | HTTP GET from mobile app webview | Serves the Select enrollment flow within a Groupon mobile app embedded webview |

> Flows without links are documented above but flow detail files are pending generation.

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The **Subscription Enrollment** flow spans `subscriptionProgramsItier`, Groupon Subscriptions API, and Tracking Hub. The **Embedded Webview Flow** spans the Groupon mobile app and `subscriptionProgramsItier`. Cross-service architecture views are tracked in the central architecture model.
