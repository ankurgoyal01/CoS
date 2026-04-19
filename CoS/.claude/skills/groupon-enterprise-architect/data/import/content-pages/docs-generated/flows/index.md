---
service: "content-pages"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Content Pages.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Content Page Retrieval](content-page-retrieval.md) | synchronous | User navigates to a `/pages/*` or `/legal/*` URL | Fetches CMS content from GraphQL API and renders the page server-side |
| [Incident Report Submission](incident-report-submission.md) | synchronous | User submits an incident report form | Accepts incident form data, uploads image to Image Service, sends notification email via Rocketman |
| [Privacy Hub Navigation](privacy-hub-navigation.md) | synchronous | User navigates to `/privacy-hub` | Renders the privacy hub page with table of contents for all privacy-related legal documents |
| [Infringement Report Submission](infringement-report-submission.md) | synchronous | User submits an infringement report form | Accepts infringement form data and sends notification email via Rocketman |
| [Cookie Consent Disclosure](cookie-consent-disclosure.md) | synchronous | User navigates to `/cookie-consent` | Renders the cookie consent disclosure page |
| [Error Page Rendering](error-page-rendering.md) | synchronous | An HTTP error occurs (404, 500, etc.) | Renders the appropriate error page |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 6 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- The Incident Report Submission flow spans `continuumContentPagesService` and `continuumImageService`. See [Incident Report Submission](incident-report-submission.md) for the full step sequence.
- No dynamic views are defined in the DSL for content-pages (`views/dynamics.dsl` is empty).
