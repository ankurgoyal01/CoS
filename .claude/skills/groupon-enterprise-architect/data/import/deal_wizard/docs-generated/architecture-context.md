---
service: "deal_wizard"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumDealWizardWebApp]
---

# Architecture Context

## System Context

Deal Wizard is a container within the `continuumSystem` (Continuum Platform) — Groupon's core commerce engine. It serves internal sales representatives who use a browser-based wizard UI to create deals sourced from Salesforce Opportunities. The service sits at the boundary between Salesforce CRM data and Groupon's internal deal lifecycle, translating Opportunity data into structured deal records that flow into deal management and inventory systems.

External actors: Salesforce (SOR for Opportunities and Accounts), and internal Continuum services (Deal Management API, Voucher Inventory Service).

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Deal Wizard Web App | `continuumDealWizardWebApp` | Web Application | Ruby on Rails / Unicorn | Rails 3.2.22.5, Unicorn 6.1.0 | Rails application providing the Deal Wizard UI and API endpoints for guided deal creation |

## Components by Container

### Deal Wizard Web App (`continuumDealWizardWebApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `dealWizardWebUi` | Rails controllers, views, and assets that implement the wizard flows, form rendering, and routing for all deal creation steps | Rails MVC |
| `salesforceClient` | SalesforceBuffet-based client for Salesforce API calls and OAuth authentication; handles Opportunity reads and deal data persistence to Salesforce | Ruby (salesforce-buffet, databasedotcom) |
| `dealManagementClient` | Service discovery client for Deal Management API; fetches deal UUIDs and looks up inventory products | Ruby (service_discovery_client) |
| `dealBookClient` | Client for Deal Book structures used in deal pricing calculators | Ruby |
| `dealGuideClient` | Client for Deal Guide structures and wizard question templates | Ruby |
| `redisCache` | Redis adapter for caching locale flags and session data | Redis |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumDealWizardWebApp` | `salesForce` | Authenticates users and persists deal data via Salesforce APIs | REST / OAuth 2.0 |
| `continuumDealWizardWebApp` | `continuumDealManagementApi` | Looks up deals and updates inventory products | REST |
| `continuumDealWizardWebApp` | `continuumVoucherInventoryService` | Updates inventory products and redemption windows | REST |
| `dealWizardWebUi` | `salesforceClient` | Reads/writes Salesforce deals and merchants via REST | Direct (in-process) |
| `dealWizardWebUi` | `dealManagementClient` | Fetches deal UUIDs and inventory products | Direct (in-process) |
| `dealWizardWebUi` | `dealBookClient` | Loads Deal Book structures for pricing calculators | Direct (in-process) |
| `dealWizardWebUi` | `dealGuideClient` | Loads Deal Guide structures and templates | Direct (in-process) |
| `dealWizardWebUi` | `redisCache` | Caches locale flags and session data | Direct (in-process) |
| `salesforceClient` | `salesForce` | Uses Salesforce APIs for CRM data | REST / APEX |
| `dealManagementClient` | `continuumDealManagementApi` | Calls deal management endpoints | REST |

> Note: Relationships to `dealBookService_7f1b`, `dealGuideService_24d9`, `dealWizardRedisCache_8a31`, `m3MerchantWriteApi_9c02`, and `selfServicesServiceEngine_1f6e` are modeled as stubs only — those targets are not present in the current federated model.

## Architecture Diagram References

- System context: `contexts-dealWizard`
- Container: `containers-dealWizard`
- Component: `dealWizardWebAppComponents`
