---
service: "ads-jobframework"
title: "Uplift Model Prediction"
generated: "2026-03-03"
type: flow
flow_name: "uplift-model-prediction"
flow_type: batch
trigger: "Scheduled via Airflow (Cloud Composer)"
participants:
  - "continuumAdsJobframeworkSpark"
  - "continuumAdsJobframeworkHiveWarehouse"
architecture_ref: "dynamic-ads-jobframework"
---

# Uplift Model Prediction

## Summary

This flow runs Spark ML Random Forest inference to score Groupon users on their predicted uplift from receiving a sponsored listing ad impression. It joins 180-day order history from `user_edwprod.fact_gbl_transactions` with user behavioral attributes from `cia_realtime.user_attrs` and deal taxonomy from `user_edwprod.dim_gbl_deal_lob`, applies feature preprocessing, loads a pre-trained PipelineModel from HDFS, runs inference, and writes the bottom-decile (lowest uplift) users to a Hive blocklist table. The blocklist is subsequently used to suppress sponsored ad impressions for users unlikely to convert.

## Trigger

- **Type**: schedule
- **Source**: Airflow DAG (Cloud Composer) — external to this service
- **Frequency**: Scheduled (period not specified in codebase; model path uses first-day-of-month granularity)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Ads Spark Job Framework | Executes inference job; loads model; writes blocklist | `continuumAdsJobframeworkSpark` |
| Groupon Data Lake / Hive | Source of order, user attribute, and deal taxonomy data; sink for blocklist table | `continuumAdsJobframeworkHiveWarehouse` |

## Steps

1. **Resolve model path**: Constructs HDFS model path as `/user/{user}/uplift_model/receipt/desktop/ml_model/{algorithm}/{numTrees}/{firstDayOfMonth}` from config (`uplift.US.*`). Accepts `--modelPath` override.
   - From: `continuumAdsJobframeworkSpark`
   - To: local computation using `UpliftModelUtil`

2. **Read order data**: Queries `user_edwprod.fact_gbl_transactions` for `capture` actions within the last `daysWindow` (default 180) days, grouped by `deal_uuid` and `order_id` to compute NOR, transaction quantity.
   - From: `continuumAdsJobframeworkSpark`
   - To: `continuumAdsJobframeworkHiveWarehouse`
   - Protocol: Spark SQL

3. **Read user attributes**: Queries `cia_realtime.user_attrs` for user behavioral features (RFM metrics, affinities, contactability flags) at `record_date = startDate` for brand `groupon`; inner-joins to users present in order data.
   - From: `continuumAdsJobframeworkSpark`
   - To: `continuumAdsJobframeworkHiveWarehouse`
   - Protocol: Spark SQL

4. **Read deal taxonomy**: Queries `user_edwprod.dim_gbl_deal_lob` for `grt_l1_cat_name`, `grt_l2_cat_name`, `grt_l3_cat_name` for the configured country ID.
   - From: `continuumAdsJobframeworkSpark`
   - To: `continuumAdsJobframeworkHiveWarehouse`
   - Protocol: Spark SQL

5. **Compute GP and pre-purchase features**: Joins order data with deal taxonomy; applies category-based GP rate adjustments (`localOrdersRate`, `shoppingOrdersRate`, `travelOrdersRate`); computes window-aggregated pre-purchase order count, NOR, GP, and units per user per category using a 14-day attribution window.
   - From: `continuumAdsJobframeworkSpark`
   - To: local Spark transformation

6. **Preprocess features**: Invokes `UpliftPreprocessor.preProcess(finalData)` to apply feature engineering transformations required by the trained model.
   - From: `continuumAdsJobframeworkSpark`
   - To: `continuumAdsJobframeworkSpark_upliftPreprocessor`

7. **Load and run model inference**: Loads `PipelineModel` from the resolved HDFS path; calls `model.transform(finalDataProcessed)` to produce probability scores; extracts positive class probability with `VectorSlicer`.
   - From: `continuumAdsJobframeworkSpark`
   - To: HDFS model artifact (via Spark MLlib PipelineModel.load)

8. **Discretize into deciles and filter blocklist**: Applies `QuantileDiscretizer` with `numOfBuckets` (default 10) to bin users by uplift probability; filters to bottom decile (`quantile_bins == 0.0`) as the blocklist.
   - From: `continuumAdsJobframeworkSpark`
   - To: local Spark transformation

9. **Write blocklist to Hive**: Writes `user_uuid`, `frequency_9block`, `recency_9block`, `grt_l1_cat_name` for bottom-decile users to `{uplift.US.db}.{uplift.US.blocklist_table_name}` (e.g., `ai_reporting_na.blocklist_rokt_desktop`) using `SaveMode.Overwrite`.
   - From: `continuumAdsJobframeworkSpark`
   - To: `continuumAdsJobframeworkHiveWarehouse`
   - Protocol: Spark SQL (saveAsTable)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Model artifact missing from HDFS | Spark exception during `PipelineModel.load`; YARN app fails | Use `--modelPath` override to specify alternate path |
| Hive table partition unavailable | Spark SQL returns empty DataFrame; empty join propagates; blocklist may be empty | Monitor with output count check |
| Insufficient executor memory | YARN executor OOM; task retry then app failure | Increase `--executor-memory` at submit time |
| Missing country config | Falls back to `uplift.US.*` defaults configured in HOCON | Job runs with US defaults |

## Sequence Diagram

```
Airflow -> AdsJobFrameworkSpark: Trigger UpliftModelPrediction (--country US --modelPath optional)
AdsJobFrameworkSpark -> AdsJobFrameworkSpark: Resolve HDFS model path via UpliftModelUtil
AdsJobFrameworkSpark -> HiveWarehouse: SELECT order data FROM fact_gbl_transactions WHERE ds BETWEEN startDate AND endDate
HiveWarehouse --> AdsJobFrameworkSpark: Order DataFrame
AdsJobFrameworkSpark -> HiveWarehouse: SELECT user attributes FROM user_attrs WHERE record_date=startDate
HiveWarehouse --> AdsJobFrameworkSpark: User attributes DataFrame
AdsJobFrameworkSpark -> HiveWarehouse: SELECT deal taxonomy FROM dim_gbl_deal_lob
HiveWarehouse --> AdsJobFrameworkSpark: Deal taxonomy DataFrame
AdsJobFrameworkSpark -> AdsJobFrameworkSpark: Join orders + user_attrs + taxonomy; compute GP, pre-purchase window features
AdsJobFrameworkSpark -> UpliftPreprocessor: preProcess(finalData)
UpliftPreprocessor --> AdsJobFrameworkSpark: Processed feature DataFrame
AdsJobFrameworkSpark -> HDFS: PipelineModel.load({modelPath})
HDFS --> AdsJobFrameworkSpark: Loaded Random Forest PipelineModel
AdsJobFrameworkSpark -> AdsJobFrameworkSpark: model.transform -> VectorSlicer -> QuantileDiscretizer -> filter quantile_bins==0
AdsJobFrameworkSpark -> HiveWarehouse: saveAsTable(ai_reporting_na.blocklist_rokt_desktop, Overwrite)
HiveWarehouse --> AdsJobFrameworkSpark: Write success
```

## Related

- Architecture dynamic view: `dynamic-ads-jobframework`
- Blocklist table: `{uplift.US.db}.{uplift.US.blocklist_table_name}` (prod: `ai_reporting_na.blocklist_rokt_desktop`)
- Model path pattern: `/user/{user}/uplift_model/receipt/desktop/ml_model/{algorithm}/{numTrees}/{firstDayOfMonth}`
