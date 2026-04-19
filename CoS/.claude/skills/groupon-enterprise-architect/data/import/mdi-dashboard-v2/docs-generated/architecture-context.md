---
service: "mdi-dashboard-v2"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumMarketingDealServiceDashboard"
  containers: [continuumMarketingDealServiceDashboard, mdiDashboardPostgres]
---

# Architecture Context

## System Context

mdi-dashboard-v2 sits within the Continuum platform as an internal-facing web application in the Marketing / Merchandising domain. It is accessed directly by internal users (Marketing Analysts, Merchandising Managers) via browser and has no public-facing surface. The dashboard orchestrates calls to multiple downstream Continuum services — including the Marketing Deal Service, Relevance API, Deal Catalog, Voucher Inventory, Taxonomy Service, Deals Cluster API, and MDS Feed Service — to assemble deal intelligence views. It also integrates with external systems (Salesforce, JIRA) for CRM context and issue tracking. Outbound HTTP calls to downstream services are routed through the API Proxy.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| MDI Dashboard Web App | `continuumMarketingDealServiceDashboard` | WebApp | Node.js / Express / CoffeeScript | 4.14 / 6.12.2 | Server-rendered internal web application providing deal intelligence, feed management, and API key management UI |
| MDI Dashboard PostgreSQL | `mdiDashboardPostgres` | Database | PostgreSQL | — | Relational database storing feed configurations and API key records managed by Sequelize ORM |

## Components by Container

### MDI Dashboard Web App (`continuumMarketingDealServiceDashboard`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Deal Browser | Handles `/browser` routes; proxies deal search queries to Marketing Deal Service | Express router / CoffeeScript |
| Cluster Analytics | Handles `/clusters` routes; fetches and presents deal clustering data from Deals Cluster API | Express router / CoffeeScript |
| Merchant Insights | Handles `/merchantInsights` routes; aggregates merchant performance data | Express router / CoffeeScript |
| API Key Manager | Handles `/keys` routes; manages API key lifecycle in PostgreSQL | Express router / Sequelize |
| Feed Builder | Handles `/feeds` routes; provides CRUD for feed configurations and triggers feed generation via MDS Feed Service | Express router / Sequelize |
| Search Controllers | Handles `/search/*` routes; queries Taxonomy Service, city and location search | Express router / CoffeeScript |
| Relevance Controller | Handles `/rapi` routes; proxies relevance scoring requests to Relevance API | Express router / gofer |
| Options Controller | Handles `/options/:id` routes; looks up deal options from Deal Catalog | Express router / CoffeeScript |
| Auth Middleware | Enforces Groupon internal user authentication on all routes | itier-user-auth 4.3.1 |
| Template Engine | Renders server-side HTML views | hogan.js 3.0.2 |
| JIRA Integration | Creates JIRA tickets for deal-related issues | jira 0.9.2 |
| Salesforce Integration | Retrieves CRM merchant data from Salesforce | gofer / keldor |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMarketingDealServiceDashboard` | `mdiDashboardPostgres` | Reads and writes feed configurations and API key records | PostgreSQL / Sequelize |
| `continuumMarketingDealServiceDashboard` | `continuumMarketingDealService` | Fetches deal data for browser and insights views | REST / HTTP |
| `continuumMarketingDealServiceDashboard` | `continuumRelevanceApi` | Queries relevance scores for deals | REST / HTTP |
| `continuumMarketingDealServiceDashboard` | `continuumDealCatalogService` | Looks up deal options by ID | REST / HTTP |
| `continuumMarketingDealServiceDashboard` | `continuumVoucherInventoryService` | Retrieves voucher inventory data for deal views | REST / HTTP |
| `continuumMarketingDealServiceDashboard` | `continuumTaxonomyService` | Queries taxonomy categories and location data | REST / HTTP |
| `continuumMarketingDealServiceDashboard` | `apiProxy` | Routes outbound API calls to downstream services | REST / HTTP |
| `continuumMarketingDealServiceDashboard` | `salesForce` | Retrieves merchant CRM data | REST / HTTP |

## Architecture Diagram References

- System context: `contexts-continuum-marketing`
- Container: `containers-mdi-dashboard-v2`
- Component: `components-mdi-dashboard-v2`
