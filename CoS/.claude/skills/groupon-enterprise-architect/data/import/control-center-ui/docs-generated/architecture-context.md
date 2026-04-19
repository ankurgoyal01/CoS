---
service: "control-center-ui"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumControlCenterUiWeb]
---

# Architecture Context

## System Context

Control Center UI is an internal tool within the **Continuum** platform used by Groupon pricing and commerce operations staff. It is an Ember.js SPA served behind an Nginx web server. All data operations are proxied through Nginx to two backend services: DPCC Service (sale and pricing CRUD) and Pricing Control Center Jtier Service (deal search and scheduling). Authentication is enforced via Doorman SSO before any internal route is accessible.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Control Center UI Web | `continuumControlCenterUiWeb` | WebApp | Ember.js + Nginx | 1.13.6 / — | Ember SPA served via Nginx; proxies API calls to DPCC Service and PCCJT Service |

## Components by Container

### Control Center UI Web (`continuumControlCenterUiWeb`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Ember Router | Manages client-side routes: /manual-sale/*, /sale/*, /sale-uploader/*, /search/* | Ember.js 1.13.6 |
| Ember Data Store | In-memory model store; adapters map models to DPCC / PCCJT REST endpoints | ember-data 1.13.9 |
| Sale Builder | UI for creating and editing manual sales; submits to DPCC Service | Ember components / jQuery UI |
| Price Changer | UI for adjusting prices on deals/divisions; submits to DPCC Service | Ember components / noUiSlider |
| Bulk Sale Uploader | CSV file parsing and upload via S3/AWS SDK; triggers DPCC sale batch | papaparse, aws-sdk |
| Deal / Division Search | Search interface querying PCCJT Service for deals and divisions | Ember components, jQuery |
| Doorman SSO Handler | Enforces authentication; redirects unauthenticated users to Doorman | Doorman SSO |
| Nginx Proxy | Serves static Ember assets; proxies API calls to DPCC and PCCJT | Nginx |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumControlCenterUiWeb` | `continuumPricingControlCenterJtierService` | Product search, deal lookup, scheduling queries | REST / HTTPS (Nginx proxy: `/__/proxies/pccjt-service`) |
| `continuumControlCenterUiWeb` | DPCC Service | Sale and pricing CRUD operations | REST / HTTPS (Nginx proxy: `/__/proxies/dpcc-service/v1.0/sales`) |
| `continuumControlCenterUiWeb` | Doorman SSO | Authentication and session enforcement | OAuth2 / SSO redirect |
| `continuumControlCenterUiWeb` | AWS S3 | Bulk sale file uploads (via aws-sdk) | HTTPS / AWS SDK |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-continuumControlCenterUiWeb`
