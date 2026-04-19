---
service: "deals-cluster"
title: "Cluster Decoration Pipeline"
generated: "2026-03-03"
type: flow
flow_name: "cluster-decoration-pipeline"
flow_type: batch
trigger: "Sub-flow invoked by ClustersGenerator per country, per rule, within DealsClusterJob"
participants:
  - "continuumDealsClusterSparkJob"
  - "edwProdDatabase_9c1f"
architecture_ref: "dynamic-dealsClusterJob"
---

# Cluster Decoration Pipeline

## Summary

The decoration pipeline is a sequential data enrichment stage within `ClustersGenerator` that augments the raw deal dataset with additional dimensions and metrics before clustering rules are applied. Each decorator joins or enhances the active deal DataFrame using Spark SQL temp views. Decorators are applied only when the active rule's `decorations` list includes the corresponding decorator key. The order of decorator application is fixed and determines which decorations are available to downstream decorators.

## Trigger

- **Type**: sub-flow (invoked programmatically)
- **Source**: `ClustersGenerator.createClustersForRule()` — called once per rule per country within `DealsClusterJob`
- **Frequency**: Per rule per country per daily job run

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| ClustersGenerator | Orchestrates decorator application based on rule `decorations` list | `continuumDealsClusterSparkJob` |
| EDWDecorator | Joins deals with 30-day EDW performance metrics | `continuumDealsClusterSparkJob` |
| CityDecorator | Adds city-level geographic dimensions to deals | `continuumDealsClusterSparkJob` |
| NationalDecor | Adds national-level dimensions for UNION with city-level results | `continuumDealsClusterSparkJob` |
| GPDecorator | Adds Groupon Points (GP) data to deals | `continuumDealsClusterSparkJob` |
| SoldGiftsDecorator | Adds sold gifts display data to deals | `continuumDealsClusterSparkJob` |
| GiftPDSDecorator | Applies PDS tag mapping for gift-type deals | `continuumDealsClusterSparkJob` |
| DealScoreDecorator | Adds algorithmic deal score signals to deals | `continuumDealsClusterSparkJob` |
| InstalilyDealScoreDecorator | Adds Instalily-sourced deal score signals | `continuumDealsClusterSparkJob` |
| IlsCampingDecorator | Applies ILS campaign price override data | `continuumDealsClusterSparkJob` |
| PromoPriceDiscountDecorator | Calculates promotional price discount fields | `continuumDealsClusterSparkJob` |
| Hive / EDW tables | Data sources for decorator enrichment | `edwProdDatabase_9c1f` |

## Steps

All decorators run as Spark SQL operations that produce named temp views. The `finalTableName` variable is updated after each decoration, so subsequent decorators operate on the progressively enriched view.

1. **EDW base decoration (always applied per country)**: `EDWDecorator.decorate()` LEFT JOINs `deals` with `edw_deals` on `country + uuid/deal_id`. Result registered as `edwDeals` temp view. This is applied once per country (cached; reused across all rules for that country).
   - From: `continuumDealsClusterSparkJob`
   - To: `edwProdDatabase_9c1f` (via Spark SQL against the cached `edw_deals` view)
   - Protocol: Spark SQL (in-process)

2. **National decoration** (if `decorations` contains `"national"`): `NationalDecor.decorate()` adds national-level dimension fields to the deals table. Used for UNION with city-level results in multi-level clustering rules.
   - From: `continuumDealsClusterSparkJob`
   - To: `continuumDealsClusterSparkJob` (Spark in-process)
   - Protocol: Spark SQL

3. **City decoration** (if `decorations` contains `"city"`): `CityDecorator.decorate()` enriches deals with city-level geographic data (EMEA cities or US cities, based on country). Updates `finalTableName`.
   - From: `continuumDealsClusterSparkJob`
   - To: `continuumDealsClusterSparkJob` (Spark in-process; reads city data from configured `cities_source.*` path)
   - Protocol: Spark SQL

4. **Sold gifts decoration** (if `decorations` contains `"display_sold_gifts_decoration"`): `SoldGiftsDecorator.decorate()` joins with the sold gifts Hive table (`cerebro.sold_gifts_table`), adds display sold gifts fields. Updates `finalTableName`. Deduplication by `uuid` applied after clustering.
   - From: `continuumDealsClusterSparkJob`
   - To: Cerebro Hive (sold gifts table)
   - Protocol: Spark SQL

5. **GP decoration** (if `decorations` contains `"gp_decoration"`): `GPDecorator.decorate()` joins with Groupon Points data. Updates `finalTableName`. Deduplication by `uuid` applied after clustering.
   - From: `continuumDealsClusterSparkJob`
   - To: Cerebro Hive (GP data source)
   - Protocol: Spark SQL

6. **Gift PDS tag mapping** (if `decorations` contains `"giftPDSMapping"`): `GiftPDSDecorator.decorate()` joins with the PDS tag mapping table (`pds_tag_mapping_table`) to categorize gift deals by product taxonomy. Updates `finalTableName`. Deduplication by `uuid` applied.
   - From: `continuumDealsClusterSparkJob`
   - To: Cerebro Hive (PDS tag mapping table)
   - Protocol: Spark SQL

7. **Deal scores decoration** (if `decorations` contains `"dealScores"`): `DealScoreDecorator.decorate()` joins with the deal score table (`deal_score_table`) to add algorithmic score fields. Updates `finalTableName`.
   - From: `continuumDealsClusterSparkJob`
   - To: Cerebro Hive (deal score table)
   - Protocol: Spark SQL

8. **Instalily deal scores decoration** (if `decorations` contains `"instalilyDealScores"`): `InstalilyDealScoreDecorator.decorate()` joins with Instalily deal score data (`instalily_deal_score_table`). Updates `finalTableName`.
   - From: `continuumDealsClusterSparkJob`
   - To: Cerebro Hive (Instalily deal score table)
   - Protocol: Spark SQL

9. **ILS campaign decoration** (if `decorations` contains `"ilsCampaign"`): `IlsCampingDecorator.decorate()` joins with ILS campaign pricing data for today's date from the configured ILS schema and table. Updates `finalTableName`. Deduplication by `uuid` applied.
   - From: `continuumDealsClusterSparkJob`
   - To: Cerebro Hive (ILS campaign table via `ils_schema` / `ils_campaign_deals` config)
   - Protocol: Spark SQL

10. **Promo price discount decoration** (if `decorations` contains `"promoPriceDiscount"`): `PromoPriceDiscountDecorator.decorate()` calculates promotional price discount fields. Updates `finalTableName`.
    - From: `continuumDealsClusterSparkJob`
    - To: `continuumDealsClusterSparkJob` (Spark in-process)
    - Protocol: Spark SQL

11. **Buy-it-again filter** (if `decorations` contains `"filterBuyItAgain"`): Filters the result Dataset typed as `Deal` to only include deals where at least one option has `maximumPurchaseQuantity > 1`.
    - From: `continuumDealsClusterSparkJob`
    - To: `continuumDealsClusterSparkJob` (Spark in-process Java filter)
    - Protocol: Spark (in-process)

12. **Execute clustering SQL**: After all applicable decorators are applied, the final `SELECT + FROM + WHERE + GROUP BY` query is executed against `finalTableName` to produce the cluster DataFrame.
    - From: `continuumDealsClusterSparkJob`
    - To: `continuumDealsClusterSparkJob` (Spark SQL in-process)
    - Protocol: Spark SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Decorator data source unavailable (Hive table missing) | Exception propagates to `ClustersGenerator`; caught by outer try/catch | `FailedCreateClusters` event logged; `failed` metric incremented; next rule processed |
| EDW join produces no data | `na().fill(0)` applied; empty metrics default to 0 | Clustering continues with zero-filled performance metrics |
| Decorator data missing for a specific country | City/GP/etc. decorators produce empty joins; null-safe fills applied | Clustering proceeds with incomplete enrichment |

## Sequence Diagram

```
ClustersGenerator -> EDWDecorator: decorate(dealsTable, country) [always]
EDWDecorator -> EDW_Hive: SELECT aggregated metrics (cached edw_deals view)
EDWDecorator --> ClustersGenerator: "edwDeals" temp view
alt rule.decorations contains "national"
  ClustersGenerator -> NationalDecor: decorate(dealsTable, country)
end
alt rule.decorations contains "city"
  ClustersGenerator -> CityDecorator: decorate(dealsTable, country)
  CityDecorator --> ClustersGenerator: city-enriched temp view
end
alt rule.decorations contains "display_sold_gifts_decoration"
  ClustersGenerator -> SoldGiftsDecorator: decorate(finalTableName, country)
end
alt rule.decorations contains "gp_decoration"
  ClustersGenerator -> GPDecorator: decorate(finalTableName, country)
end
alt rule.decorations contains "giftPDSMapping"
  ClustersGenerator -> GiftPDSDecorator: decorate(finalTableName, country, ruleName)
end
alt rule.decorations contains "dealScores"
  ClustersGenerator -> DealScoreDecorator: decorate(finalTableName, country, ruleName)
end
alt rule.decorations contains "instalilyDealScores"
  ClustersGenerator -> InstalilyDealScoreDecorator: decorate(finalTableName, country, ruleName)
end
alt rule.decorations contains "ilsCampaign"
  ClustersGenerator -> IlsCampingDecorator: decorate(finalTableName, country, today)
end
alt rule.decorations contains "promoPriceDiscount"
  ClustersGenerator -> PromoPriceDiscountDecorator: decorate(finalTableName, country)
end
ClustersGenerator -> Spark: spark.sql(SELECT ... FROM finalTableName WHERE ... GROUP BY ...)
Spark --> ClustersGenerator: clusters Dataset<Row>
```

## Related

- Architecture dynamic view: `dynamic-dealsClusterJob`
- Related flows: [Deals Cluster Job Execution](deals-cluster-job-execution.md)
