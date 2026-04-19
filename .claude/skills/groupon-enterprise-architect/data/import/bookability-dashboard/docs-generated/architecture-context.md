---
service: "bookability-dashboard"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumBookabilityDashboardWeb"]
---

# Architecture Context

## System Context

The Bookability Dashboard is a static single-page application within the **Continuum** platform. It is served from Google Cloud Storage via Google Cloud CDN and a GCP load balancer. All dynamic data is fetched at runtime from the `continuumPartnerService` backend, proxied through `apiProxy` at the `/bookability/dashboard/api/*` path. Internal employees authenticate via `continuumUniversalMerchantApi` using an internal OAuth redirect flow. The dashboard has no server-side compute of its own; it is purely a browser client that orchestrates calls to Partner Service.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Bookability Dashboard Web | `continuumBookabilityDashboardWeb` | WebApp (SPA) | TypeScript, React, Vite | React 19 / Vite 7 | React and TypeScript single-page application for monitoring merchant connectivity, deal health, and investigations |
| API Proxy | `apiProxy` | Proxy/Gateway | Stub (external to this repo) | — | Routes proxied dashboard requests to partner-service upstreams at `/bookability/dashboard/api/*` |
| Partner Service | `continuumPartnerService` | Backend Service | Stub (external to this repo) | — | Provides all merchant, deal, health-check, and investigation data consumed by the dashboard |
| Universal Merchant API | `continuumUniversalMerchantApi` | Backend Service | Stub (external to this repo) | — | Provides internal OAuth token exchange and user identity endpoints |

## Components by Container

### Bookability Dashboard Web (`continuumBookabilityDashboardWeb`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Dashboard App Shell (`bookDash_appShell`) | Main React application shell: view routing, data orchestration, auto-refresh every 5 minutes, URL-based navigation state | TypeScript, React |
| Internal Auth Workflow (`bookDash_authWorkflow`) | Internal login and role-gating flow for employee access; handles Doorman/OKTA redirect and cookie-based sessions | TypeScript, React |
| Partner Service Client (`bookDash_partnerServiceClient`) | API client layer for partner-service merchant, connectivity, health-check, reports, and partner configuration endpoints | TypeScript |
| Investigation API Client (`bookDash_investigationClient`) | API client layer for deal investigation history retrieval, category assignment, and acknowledgement actions via `/v1/deals/investigation` | TypeScript |
| Report Exporter (`bookDash_reportExporter`) | Transforms dashboard and investigation data into downloadable CSV exports | TypeScript |
| JSON Parser Worker Bridge (`bookDash_jsonParserWorkerBridge`) | Web Worker bridge for parsing large health-check log JSON payloads off the main thread to keep the UI responsive | TypeScript, Web Worker |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumBookabilityDashboardWeb` | `apiProxy` | Sends all API requests to `/bookability/dashboard/api/*` and `/api/partner-service/*` | HTTPS / REST |
| `apiProxy` | `continuumPartnerService` | Routes proxied dashboard requests to partner-service upstreams | HTTPS / REST |
| `continuumBookabilityDashboardWeb` | `continuumUniversalMerchantApi` | Uses internal OAuth redirect and token endpoints for employee login (`/v2/merchant_oauth/internal/me`) | HTTPS / OAuth2 |
| `bookDash_appShell` | `bookDash_authWorkflow` | Initiates authentication and authorization checks for internal users | In-process |
| `bookDash_appShell` | `bookDash_partnerServiceClient` | Requests merchant lists, connectivity status, reports, and health-check data | In-process |
| `bookDash_appShell` | `bookDash_investigationClient` | Loads and updates investigation history and acknowledgements | In-process |
| `bookDash_appShell` | `bookDash_reportExporter` | Exports dashboard and investigation data to CSV | In-process |
| `bookDash_appShell` | `bookDash_jsonParserWorkerBridge` | Parses large payloads in a worker to keep UI responsive | Web Worker message |
| `bookDash_authWorkflow` | `continuumUniversalMerchantApi` | Redirects and exchanges internal OAuth tokens | HTTPS / OAuth2 |
| `bookDash_partnerServiceClient` | `continuumPartnerService` | Calls partner-service dashboard and merchant endpoints | HTTPS / REST |
| `bookDash_investigationClient` | `continuumPartnerService` | Calls investigation history and update endpoints | HTTPS / REST |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumBookabilityDashboardWeb`
- Component: `components-continuum-bookability-dashboard-web-components`
- Dynamic view (data fetch flow): `dynamic-bookability-dashboard-data-fetch`
