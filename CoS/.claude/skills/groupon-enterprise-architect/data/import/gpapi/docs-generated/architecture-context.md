---
service: "gpapi"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumGpapiService, continuumGpapiDb]
---

# Architecture Context

## System Context

`continuumGpapiService` sits within the Continuum platform as the central orchestration layer for all Goods Vendor Portal operations. Vendor users interact with the Vendor Portal UI, which routes all API calls through gpapi. gpapi then fans out synchronous HTTP requests to 15+ downstream Continuum services to fulfill vendor workflows. It also receives inbound webhooks from NetSuite for accounting events and integrates with Google reCAPTCHA Enterprise for session security. The service owns a PostgreSQL database (`continuumGpapiDb`) for storing vendor-specific entities that are not owned by downstream services.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Goods Product API | `continuumGpapiService` | Backend API | Ruby on Rails | 5.2.8 / Puma 6.3.1 | Rails API application serving the Goods Vendor Portal; proxy and orchestrator for vendor workflows |
| Goods Product API Database | `continuumGpapiDb` | Database | PostgreSQL | — | Relational store for products, items, vendors, users, contracts, features, validations, inventory, approvals, and bank information |

## Components by Container

### Goods Product API (`continuumGpapiService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| V0 API (goods_stores) | Legacy goods stores endpoints | Rails routing + controllers |
| V1 API | Products, items, contracts, vendors, users, sessions, vendor_compliance, tickets, bank_info, categories | Rails routing + controllers |
| V2 API | Promotions, co_op_agreements, external_files, vendor items/pricing, Avalara tax proxy | Rails routing + controllers |
| V3 API | Deal instances, inventory item instances | Rails routing + controllers |
| NetSuite Webhook Receiver | Ingests inbound accounting events from NetSuite | Rails controller + webhook auth |
| Session / Auth Controller | Handles login, logout, 2FA via reCAPTCHA Enterprise | oauthenticator + google-cloud-recaptcha_enterprise |
| Downstream HTTP Clients | Fan-out HTTP calls to Continuum microservices | rest-client, typhoeus, schema_driven_client |
| Metrics / Tracing Agent | Emits StatsD metrics and Elastic APM traces | sonoma-metrics, elastic-apm |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumGpapiService` | `continuumGpapiDb` | Reads and writes vendor, product, item, and contract records | PostgreSQL |
| `continuumGpapiService` | `continuumGoodsPromotionManager` | Creates and manages promotions and co-op agreements | REST/HTTP |
| `continuumGpapiService` | `continuumVendorComplianceService` | Orchestrates vendor compliance onboarding | REST/HTTP |
| `continuumGpapiService` | `continuumGoogleRecaptcha` | Verifies reCAPTCHA tokens for session 2FA | HTTPS SDK |
| `continuumGpapiService` | Goods Stores Service | Retrieves and manages legacy goods store data (V0) | REST/HTTP |
| `continuumGpapiService` | Goods Inventory Service | Manages inventory item instances | REST/HTTP |
| `continuumGpapiService` | Goods Product Catalog | Retrieves and updates product catalog entries | REST/HTTP |
| `continuumGpapiService` | Deal Catalog | Retrieves deal instance data | REST/HTTP |
| `continuumGpapiService` | DMAPI | Merchant data lookup and management | REST/HTTP |
| `continuumGpapiService` | Pricing Service | Vendor pricing data retrieval | REST/HTTP |
| `continuumGpapiService` | Taxonomy Service | Category and taxonomy lookups | REST/HTTP |
| `continuumGpapiService` | Users Service | User account management and linking | REST/HTTP |
| `continuumGpapiService` | Commerce Interface | Commerce workflow integration | REST/HTTP |
| `continuumGpapiService` | Geo Details Service | Geographic details lookup | REST/HTTP |
| `continuumGpapiService` | Accounting Service | Accounting and financial data integration | REST/HTTP |
| `continuumGpapiService` | Amazon S3 | External file storage for vendor documents | HTTPS SDK |
| NetSuite | `continuumGpapiService` | Sends accounting event webhooks | HTTPS webhook |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-gpapi`
- Dynamic view (vendor onboarding): `dynamic-vendorOnboardingFlow`
