---
service: "goods-promotion-manager"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumGoodsPromotionManagerDb"
    type: "postgresql"
    purpose: "Primary operational store for all promotion, deal, metric, and eligibility data"
---

# Data Stores

## Overview

Goods Promotion Manager owns a single PostgreSQL database (`continuumGoodsPromotionManagerDb`) managed via Groupon's DaaS (Database-as-a-Service) platform. Schema migrations are handled by Flyway via the `jtier-migrations` bundle. No external caches or secondary stores are used; all data is read from and written to this single database.

## Stores

### Goods Promotion Manager DB (`continuumGoodsPromotionManagerDb`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumGoodsPromotionManagerDb` |
| Purpose | Stores all promotions, promotion-deal associations, promotion inventory products, eligibility data, metrics, countries, feature flags, and Quartz scheduler state |
| Ownership | owned |
| Migrations path | `src/main/resources/db/migration` (Flyway versioned migrations, naming `Vx.x__description.sql`) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `promotion` | Core promotion record; drives the promotion lifecycle | `uuid`, `name`, `status` (CREATED/LOCKED/SUBMITTED/DONE), `start_time`, `end_time`, `due_time`, `created_by`, `updated_by` |
| `promotion_deal` | Associates deals with a promotion | `id`, `promotion_uuid`, `deal_uuid` |
| `promotion_inventory_product` | Tracks inventory products within a promotion deal, including ILS pricing | `promotion_deal_id`, `inventory_product_uuid`, `ils_price`, `offer_buy_price` |
| `promotion_metric` | Associates metric targets with a promotion | `promotion_uuid`, `metric_id` |
| `promotion_metric_detail` | Stores detailed metric configuration per promotion/metric | — |
| `promotion_country` | Associates target countries with a promotion | `promotion_uuid`, `country_id` |
| `promotion_ineligibility` | Records ineligibility reasons for promotion-deal combinations | `promotion_uuid`, `deal_uuid`, status fields |
| `deal_promotion_eligibility` | Per-deal eligibility flags used by the eligibility evaluation engine | `deal_uuid`, `less_28_reg_days_flag`, `star_rating`, `last_ils_day`, `competitive_pricing`, `prior_ils_performance`, `negative_gp_flag`, `inventory_flag`, `constraints_flag`, `metal_tier_rating`, `no_ils_hist_deal_perf`, `new_deal_days` |
| `deal` | Deal reference data imported from Deal Management API | `uuid`, `deal_permalink`, `purchasability_region` |
| `inventory_product` | Inventory product reference data imported from Deal Management API | `uuid`, `unit_sell_price`, `unit_buy_price` |
| `metric` | Reference data for promotion metrics | `id`, `name`, `description`, `default_value`, `show_when_create_promotion_flag`, `category_uuid`, `division_uuid`, `subcategory_uuid` |
| `country` | Reference data for supported countries | `id`, `code`, `region` |
| `feature_flag` | Runtime feature flag configuration | `name`, `enabled`, `detail` (JSON with months for archive behavior) |
| `ils_deal_selection_log_raw` | Historical ILS deal selection log; used for 50% Rule and Resting Rule eligibility checks | `inventory_product_uuid`, `sale_start`, `sale_end` |
| Quartz tables (`qrtz_*`) | Quartz job scheduler state (triggers, job details, fired triggers) | managed by `jtier-quartz-postgres-migrations` |

#### Access Patterns

- **Read**: Promotions are read individually by UUID or in bulk with optional status and recency filters (controlled by the `ARCHIVE` feature flag limiting results to a configurable number of months). Promotion deals are queried by `promotionUuid` with optional filters for division, category, subcategory, and user. CSV export queries join across `promotion`, `promotion_deal`, `promotion_inventory_product`, `deal`, and `inventory_product` tables.
- **Write**: All write operations go through handler validation before DAO persistence. Status transitions on `promotion` are enforced (e.g., `SUBMITTED` promotions are read-only). Monetary values are stored as `INTEGER` (cents) in the database but exposed as `Double` in the API layer.
- **Indexes**: Not discoverable from the codebase at this level of detail; defined within Flyway migration SQL files.

## Caches

> No evidence found in codebase. No caching layer is used; all reads go directly to PostgreSQL.

## Data Flows

Data enters the database primarily through two paths:
1. **API writes** — internal users create and update promotions, deals, and pricing data via REST endpoints.
2. **Quartz job imports** — the `Import Product Job` pulls deal and inventory product data from the Deal Management API and writes it to the `deal` and `inventory_product` tables. The `Update Established Price Job` calls the Core Pricing Service and writes established prices back to `promotion_inventory_product`.

No CDC, ETL pipeline, or replication to an analytics store is evidenced in the codebase.
