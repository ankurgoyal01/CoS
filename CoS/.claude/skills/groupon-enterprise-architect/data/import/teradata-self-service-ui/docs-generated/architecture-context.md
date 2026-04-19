---
service: "teradata-self-service-ui"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumTeradataSelfServiceUi"]
---

# Architecture Context

## System Context

The Teradata Self Service UI is a browser-hosted SPA within the Continuum platform. Authenticated Groupon employees access it over the internal network; corporate SSO injects identity headers (`X-GRPN-USERNAME`, `X-GRPN-EMAIL`, `X-GRPN-FIRSTNAME`, `X-GRPN-LASTNAME`) which Nginx converts into cookies consumed by the Vue.js application. All data-plane operations are proxied by Nginx to `continuumTeradataSelfServiceApi` (the backend service), which is the authoritative data source and Teradata integration layer. Analytics events are sent directly from the browser to Google Analytics.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Teradata Self Service UI | `continuumTeradataSelfServiceUi` | WebApp | Vue.js, Vuetify, Nginx | 2.6.11 / stable-alpine | Single-page web application for Teradata account and request management |

## Components by Container

### Teradata Self Service UI (`continuumTeradataSelfServiceUi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| SPA UI | Vue.js application shell, routing, and all views (Accounts, Requests, History) | Vue.js 2.6, Vuetify 2.4, Vue Router 3.2 |
| API Client | Wraps all outbound calls to `teradata-self-service-api`; classifies and propagates errors; records API timing in GA | Axios 0.24, Vuex 3.4 |
| Analytics Adapter | Instruments user interactions, API timings, exceptions, and Core Web Vitals to Google Analytics | `gtag`, `web-vitals` 2.1.3 |
| Mock Service Worker | Provides local development API mocking without needing the real backend | MSW 0.35 |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumTeradataSelfServiceUi` | `teradataSelfServiceApi` (stub) | Proxies all `/api/` requests to the Teradata Self Service API backend | HTTPS (Nginx reverse proxy) |
| `continuumTeradataSelfServiceUi` | `googleAnalytics` | Sends page view, interaction, timing, exception, and web vital events | HTTPS (`gtag`) |

> Note: The direct relationship to `teradataSelfServiceApi` is marked `stub_only` in the DSL because that container is defined in a separate federated module not yet merged into the central model. The proxy is confirmed in `nginx.conf` → `proxy_pass https://teradata-self-service-api.${ENV}.service`.

## Architecture Diagram References

- System context: `contexts-continuumTeradataSelfServiceUi`
- Container: `containers-continuumTeradataSelfServiceUi`
- Component: `components-teradataSelfServiceUiComponents`
