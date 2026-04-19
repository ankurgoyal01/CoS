---
service: "bling"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumBlingWebApp, blingNginx]
---

# Architecture Context

## System Context

`continuumBlingWebApp` is an internal-only Ember.js SPA within the Continuum platform, accessed exclusively by Groupon finance and accounting staff. The application is served by an Nginx reverse proxy (`blingNginx`) which also proxies API requests to the Accounting Service backend and the File Sharing Service. Authentication is handled through the Hybrid Boundary OAuth/Okta proxy. bling has no own database; all state is owned by the Accounting Service. The application provides UI views onto data that also lives in or flows to/from Salesforce, NetSuite, and Merchant Center, but bling does not directly integrate with those systems — the Accounting Service mediates those relationships.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| bling Web Application | `continuumBlingWebApp` | WebApp (SPA) | Ember.js | 0.2.7 / Node.js 6.9.4 | Single-page application for finance and accounting operations; compiled static assets served by Nginx |
| bling Nginx | `blingNginx` | Reverse Proxy | Nginx | — | Serves static SPA assets; reverse-proxies API calls to Accounting Service and File Sharing Service; handles SSL termination |

## Components by Container

### bling Web Application (`continuumBlingWebApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Invoice Module | Invoice list, detail, and approval workflow views | Ember.js routes + components |
| Contract Module | Contract line item listing and management views | Ember.js routes + components |
| Payment Module | Payment processing and batch management views | Ember.js routes + components |
| Paysource File Module | Paysource file upload and tracking views | Ember.js routes + components |
| Search Module | Cross-entity batch search views | Ember.js routes + ember-select-2 |
| User Auth Module | Okta login/logout via Hybrid Boundary OAuth proxy | Ember.js + ember-ajax |
| Data Table Component | Reusable high-performance table for all list views | ember-table 0.5.0 |
| API Service Layer | ember-ajax service configured for Accounting Service and File Sharing Service endpoints | ember-ajax 2.3.2 |

### bling Nginx (`blingNginx`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Static Asset Server | Serves compiled Ember.js SPA bundle | Nginx static serving |
| API Proxy | Forwards `/api/v1-v3/*` to Accounting Service; `/file-sharing-service/*` to File Sharing Service | Nginx proxy_pass |
| OAuth Redirect Handler | Routes OAuth callback to Hybrid Boundary | Nginx location rules |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumBlingWebApp` | `continuumAccountingService` | Fetches and mutates all finance data (invoices, contracts, payments, batches, paysource files, users, system errors) | REST/HTTP via Nginx proxy |
| `continuumBlingWebApp` | `fileSharingService` | Downloads and manages files associated with accounting records | REST/HTTP via Nginx proxy |
| `continuumBlingWebApp` | Hybrid Boundary | OAuth/Okta authentication and session management | HTTPS OAuth2 |
| `continuumBlingWebApp` | `salesForce` | Read view onto Salesforce-originated data surfaced through Accounting Service | Indirect (via Accounting Service) |
| `continuumBlingWebApp` | `merchantCenter` | Read view onto Merchant Center data surfaced through Accounting Service | Indirect (via Accounting Service) |
| `continuumBlingWebApp` | `legacyWeb` | Integration with legacy Groupon web systems where applicable | REST/HTTP |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-bling`
- Dynamic view (finance operations): `dynamic-finance-operations-flow`
