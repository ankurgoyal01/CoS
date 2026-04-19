---
service: "goods-promotion-manager"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumGoodsPromotionManagerService"
  containers: ["continuumGoodsPromotionManagerService", "continuumGoodsPromotionManagerDb"]
---

# Architecture Context

## System Context

Goods Promotion Manager sits within the **Continuum** platform's Goods/Inventory domain. It acts as an internal tool service: merchandise and pricing team members interact with it directly via authenticated REST calls to create and manage promotions. The service reads and writes its own PostgreSQL database (`continuumGoodsPromotionManagerDb`) and calls two downstream services — the Deal Management API for deal and inventory product data, and the Core Pricing Service for established price lookups — via Retrofit2 HTTP clients.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Goods Promotion Manager Service | `continuumGoodsPromotionManagerService` | Service | Java, JTier, Dropwizard | 0.4-SNAPSHOT | REST API and Quartz scheduler service managing promotions, eligibility, and ILS pricing workflows |
| Goods Promotion Manager DB | `continuumGoodsPromotionManagerDb` | Database | PostgreSQL | 9.4 (local dev) | Stores promotions, deals, metrics, countries, eligibility, and inventory product data |

## Components by Container

### Goods Promotion Manager Service (`continuumGoodsPromotionManagerService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Goods Promotion Manager Resource | Root and health/status endpoints | Jersey Resource |
| Promotion Resource | Promotion CRUD, query, CSV export, and metrics endpoints | Jersey Resource |
| Promotion Deal Resource | Create, update, and delete promotion deal associations | Jersey Resource |
| Promotion Ineligibility Resource | Create and update promotion ineligibility records | Jersey Resource |
| Promotion Inventory Product Resource | Retrieve and update promotion inventory product data | Jersey Resource |
| Deal Promotion Eligibility Resource | Evaluate deal eligibility for a given promotion | Jersey Resource |
| Country Resource | Retrieve supported country reference data | Jersey Resource |
| Metric Resource | Retrieve promotion metric reference data | Jersey Resource |
| Quartz Job Resource | Manually trigger import product background jobs | Jersey Resource |
| Promotion Handler | Orchestrates promotion creation, update, status transitions, and CSV streaming | Service |
| Promotion Deal Handler | Orchestrates promotion deal create/update/delete operations | Service |
| Promotion Ineligibility Handler | Orchestrates ineligibility record writes | Service |
| Promotion Inventory Product Handler | Orchestrates inventory product update operations | Service |
| Deal Promotion Eligibility Handler | Evaluates eligibility and pre-qualification flags including ILS 50% Rule and Resting Rule | Service |
| Country Handler | Country reference data retrieval | Service |
| Metric Handler | Metric reference data retrieval | Service |
| Quartz Job Handler | Schedules and monitors Quartz jobs | Service |
| Import Product Job | Quartz job that imports inventory products from the Deal Management API | Quartz Job |
| Update Established Price Job | Quartz job that updates established prices from the Core Pricing Service | Quartz Job |
| Deal Management API Client | Retrofit2 HTTP client calling `GET /v2/deals/{id}?expand[0]=full` | Retrofit Client |
| Core Pricing API Client | Retrofit2 HTTP client calling `GET /pricing_service/v2.0/product/{id}/established_price/{at}` | Retrofit Client |
| Promotion DAO Manager | Coordinates multi-table promotion queries | JDBI DAO |
| Promotion DAO | Promotion table persistence | JDBI DAO |
| Promotion Deal DAO | Promotion deal table persistence | JDBI DAO |
| Promotion Ineligibility DAO | Promotion ineligibility table persistence | JDBI DAO |
| Promotion Inventory Product DAO Manager | Coordinates inventory product multi-table queries | JDBI DAO |
| Promotion Inventory Product DAO | Promotion inventory product table persistence | JDBI DAO |
| Promotion Metric DAO | Promotion metric table persistence | JDBI DAO |
| Promotion CSV DAO | Promotion CSV data query persistence | JDBI DAO |
| Metric DAO | Metric reference table persistence | JDBI DAO |
| Country DAO | Country reference table persistence | JDBI DAO |
| Deal DAO | Deal table persistence | JDBI DAO |
| Deal Promotion Eligibility DAO | Deal promotion eligibility table persistence | JDBI DAO |
| ILS Deal Selection Log Raw DAO | ILS deal selection log persistence for 50% and resting rule checks | JDBI DAO |
| Feature Flag DAO | Feature flag table persistence | JDBI DAO |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumGoodsPromotionManagerService` | `continuumGoodsPromotionManagerDb` | Reads and writes promotion, deal, metric, and eligibility data | JDBC |
| `continuumGoodsPromotionManagerService` | `continuumDealManagementApi` | Fetches deal details and inventory product data during product import | HTTPS/REST |
| `continuumGoodsPromotionManagerService` | `corePricingServiceSystem` | Fetches established pricing for inventory products during price update jobs | HTTPS/REST |

## Architecture Diagram References

- System context: `contexts-goods-promotion-manager`
- Container: `containers-goods-promotion-manager`
- Component: `components-goods-promotion-manager-service` (view defined in `architecture/views/components/goods-promotion-manager-service.dsl`)
