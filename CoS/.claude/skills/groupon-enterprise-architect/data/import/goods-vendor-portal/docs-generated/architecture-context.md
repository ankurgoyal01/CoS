---
service: "goods-vendor-portal"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumGoodsVendorPortalWeb]
---

# Architecture Context

## System Context

The Goods Vendor Portal sits within the `continuumSystem` (Continuum Platform) as a merchant-facing web application. Goods merchants interact directly with it through a browser. The portal itself holds no data — it acts as a thin orchestration layer that proxies all API calls to the GPAPI backend (`gpapiApi_unk_1d2b`) through an Nginx gateway. Financial data flows onward to `continuumAccountingService`. The portal is stateless at the container level; all state lives in GPAPI and downstream Continuum services.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Goods Vendor Portal | `continuumGoodsVendorPortalWeb` | WebApp | Ember.js SPA served by Nginx | Ember 3.14.0 / Nginx | Unified goods UI for merchants and internal users to manage catalog, inventory, pricing, and deals |

## Components by Container

### Goods Vendor Portal (`continuumGoodsVendorPortalWeb`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `emberApp` | Client-side application for all vendor portal workflows — routing, views, state management, and user interaction | Ember.js 3.14.0 |
| `goodsVendorPortal_apiClient` | Adapters and services that proxy HTTP calls to GPAPI on behalf of the Ember application | ember-ajax |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `emberApp` | `goodsVendorPortal_apiClient` | Uses API client adapters to communicate with backend | ember-ajax (in-process) |
| `continuumGoodsVendorPortalWeb` | `gpapiApi_unk_1d2b` | Proxies API calls for backend data access | HTTPS |
| `continuumGoodsVendorPortalWeb` | `continuumAccountingService` | Transmits financial data (via GPAPI) | HTTPS |

> Note: `gpapiApi_unk_1d2b` and `goodsStoresApi_unk_7c11` are referenced as external stubs in the local architecture model. Their canonical container IDs in the federated central model are pending resolution.

## Architecture Diagram References

- System context: `contexts-goods-vendor-portal`
- Container: `goods-vendor-portal-container`
- Component: `goods-vendor-portal-components`
