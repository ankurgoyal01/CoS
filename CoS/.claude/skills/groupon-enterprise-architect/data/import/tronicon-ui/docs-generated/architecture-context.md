---
service: "tronicon-ui"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [troniconUiWeb, continuumTroniconUiDatabase]
---

# Architecture Context

## System Context

Tronicon UI is an internal web application within the **Continuum** platform. It is accessed exclusively by internal Groupon merchandising and campaign operations staff via a browser. It sits in the Merchant Tools domain and orchestrates campaign card data across multiple downstream Continuum services. It reads and writes its own MySQL database (`continuumTroniconUiDatabase`) for persistent state, and calls external Continuum services — Alligator, Groupon API, and Taxonomy Service — as active integrations, with additional stub-level dependencies on Campaign Service, CMS, Image Service, and others.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Tronicon UI Web App | `troniconUiWeb` | WebApp | Python, web.py, Gunicorn | web.py 0.37, Gunicorn 19.10.0 | Browser-served UI handling all campaign card, CMS, and theme management workflows |
| Tronicon UI Database | `continuumTroniconUiDatabase` | Database | MySQL | — | Primary relational store for cards, decks, campaigns, CMS content, themes, templates, geo_polygons, and permalinks |

## Components by Container

### Tronicon UI Web App (`troniconUiWeb`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Web Controllers (`troniconUi_webControllers`) | Handles all HTTP routing and request/response logic for card, deck, CMS, theme, and business group endpoints | web.py URL dispatcher |
| Bootstrap & Config Loader (`bootstrapService`) | Loads initial application configuration at startup from `.env`, `gconfig/cardatron.json`, and remote config services | python-dotenv, requests |
| Integration Clients (`troniconUi_integrationClients`) | HTTP client wrappers for calling Campaign Service, Alligator, Groupon API, Taxonomy Service, and other internal services | requests 2.7.0 |
| Data Access Layer (`troniconUi_dataAccess`) | SQLAlchemy ORM models and database query logic for all persisted entities | SQLAlchemy 0.9.4, mysql-python 1.2.5 |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `troniconUiWeb` | `continuumTroniconUiDatabase` | Reads/writes application data (cards, decks, campaigns, CMS, themes) | SQL over TCP |
| `troniconUiWeb` | `continuumAlligatorService` | Queries experiments service for A/B test configuration | REST/HTTP |
| `troniconUiWeb` | `continuumGrouponApi` | Calls Groupon public API for deal and offer data | REST/HTTP |
| `troniconUiWeb` | `continuumTaxonomyService` | Fetches taxonomy categories for campaign classification | REST/HTTP |
| `troniconUiWeb` | `campaignService` | Proxies campaign CRUD requests via `/c/` path | REST/HTTP (proxy) |
| `troniconUiWeb` | `troniconCms` | Reads and writes CMS content | REST/HTTP |
| `troniconUiWeb` | `cardUiPreview` | Renders card previews | REST/HTTP |
| `troniconUiWeb` | `geoTaxonomyApi` | Fetches geographic taxonomy data for geo-polygon targeting | REST/HTTP |
| `troniconUiWeb` | `grouponImageService` | Uploads and retrieves images for cards and CMS content | REST/HTTP |
| `troniconUiWeb` | `brandService` | Retrieves brand data for campaign attribution | REST/HTTP |
| `troniconUiWeb` | `gconfigService` | Reads remote configuration values | REST/HTTP |
| `troniconUiWeb` | `audienceService` | Fetches audience segment data | REST/HTTP |
| `troniconUiWeb` | `rocketmanRender` | Requests content rendering | REST/HTTP |

## Architecture Diagram References

- System context: `contexts-troniconUi`
- Container: `containers-troniconUi`
- Component: `components-troniconUiWeb`
