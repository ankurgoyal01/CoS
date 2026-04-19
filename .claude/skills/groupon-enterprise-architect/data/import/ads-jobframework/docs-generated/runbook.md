---
service: "ads-jobframework"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| YARN Application state | exec (YARN UI / CLI) | Per job run | Per job run |
| Airflow DAG status | http (Airflow UI) | Per DAG schedule | — |
| Wavefront dashboard | http | Continuous | — |

Airflow orchestrates job execution. Check Airflow DAG status first when a job is suspected not to have run:

| Environment | Airflow URL |
|-------------|------------|
| dev | `https://d134c969a7dc418dba6e877f8f4fa5b0-dot-us-central1.composer.googleusercontent.com/home` |
| stable | `https://4952faa6ee0242268293dfe488980af0-dot-us-central1.composer.googleusercontent.com/home` |
| prod | `https://91c76cae09ac40609460f5e26460e6e8-dot-us-central1.composer.googleusercontent.com/home` |

## Monitoring

### Metrics

All metrics are emitted to Telegraf under the `ads.spark` namespace with tags `env`, `service=ads-jobframework`, `source=ads`.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `impressions_report_web_mobile_count` | gauge | Count of distinct sponsored ad IDs with web/mobile impressions in reporting window | Unexpected zero |
| `impressions_report_email_count` | gauge | Count of distinct sponsored ad IDs with email impressions in reporting window | Unexpected zero |
| `clicks_report_web_mobile_count` | gauge | Count of distinct sponsored ad IDs with web/mobile clicks | Unexpected zero |
| `clicks_report_email_count` | gauge | Count of distinct sponsored ad IDs with email clicks | — |
| `citrus_impressions_report_success` | counter | CitrusAd impression callback successes | — |
| `citrus_impressions_report_exception` | counter | CitrusAd impression callback failures | Alert if non-zero |
| `citrus_clicks_report_success` | counter | CitrusAd click callback successes | — |
| `citrus_clicks_report_exception` | counter | CitrusAd click callback failures | Alert if non-zero |
| `citrus_impressions_report_response_code` | gauge | HTTP response code from CitrusAd impression endpoint | Alert if not 2xx |
| `citrus_clicks_report_response_code` | gauge | HTTP response code from CitrusAd click endpoint | Alert if not 2xx |
| `clarus_ad_impression_report_success` | counter | ClarusAd impression ping successes | — |
| `clarus_ad_impressions_report_exception` | counter | ClarusAd impression ping failures | Alert if non-zero |
| `customer_feed_record_count` | gauge | Number of customer records written to GCS customer feed | Unexpected zero |
| `order_feed_record_count` | gauge | Total order feed records written to GCS | Unexpected zero |
| `pv_with_impressions_dataframe_count` | gauge | Rows in PVWithImpressions output | Unexpected zero |
| `total_deals_max_cpc_count` | gauge | Deal count processed by ROASBasedDealMaxCPCJob | Unexpected zero |
| `sl_click_impression_web_job` | counter | Completion counter for SLClickImpressionWebJob | Must be 1 per run |
| `sl_citrus_ad_email_report` | counter | Completion counter for SLCitrusAdExceptionReportEmailJob | Must be 1 per run |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| AI Engineering Overview | Wavefront | `https://groupon.wavefront.com/dashboard/ai` |
| Sponsored Self-Serve | Wavefront | `https://groupon.wavefront.com/dashboards/Sponsored-Self-Serve` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Job not running | Airflow DAG paused or task failed | P2 | Check Airflow logs; verify DAG is enabled; re-trigger manually if safe |
| CitrusAd callback exceptions | `citrus_impressions_report_exception` or `citrus_clicks_report_exception` counter > 0 | P2 | Check CitrusAd endpoint reachability; run backfill job for missed window |
| ClarusAd ping failures | `clarus_ad_impressions_report_exception` counter > 0 | P2 | Check DoubleClick endpoint; run `ClarusAdImpressionsBackfillJob` for affected window |
| Zero impression/click counts | `impressions_report_web_mobile_count` gauge = 0 unexpectedly | P1 | Check Hive `junoHourly` data availability; verify event pipeline upstream |
| PagerDuty alert | `ad-inventory@groupon.pagerduty.com` | P1 | Page `ads-eng@groupon.com`; check YARN logs on production cluster |

## Common Operations

### Restart Service

ads-jobframework is a batch framework — there is no long-running service process to restart. To re-run a failed job:

1. Identify the failing Airflow DAG task in the Airflow UI
2. Clear the failed task in Airflow to trigger re-execution, or
3. Submit manually via `spark-submit` using the pattern in README.md:
   ```
   spark-submit --deploy-mode cluster --master yarn --queue <queue> \
     --executor-memory 30g --driver-memory 8g --executor-cores 4 \
     --conf spark.shuffle.service.enabled=true \
     --conf spark.dynamicAllocation.enabled=true \
     --conf spark.dynamicAllocation.minExecutors=10 \
     --conf spark.dynamicAllocation.maxExecutors=10 \
     --conf spark.yarn.appMasterEnv.env=prod \
     --conf spark.executorEnv.env=prod \
     --files /var/groupon/spark-2.4.0/conf/hive-site.xml \
     --class <MainClass> <jar-path>
   ```

### Scale Up / Down

Executor count is controlled by YARN dynamic allocation parameters at submit time:
- Modify `--conf spark.dynamicAllocation.minExecutors` and `--conf spark.dynamicAllocation.maxExecutors`
- Modify `--executor-memory` and `--driver-memory` for memory-intensive jobs like `UpliftModelPrediction`

### Database Operations

- **Hive table backfill**: Re-run `PVWithImpressions` or `SLClickImpressionWebJob` with adjusted `--startDate` / `--endDate` parameters
- **CitrusAd callback backfill**: Run `CitrusAdImpressionsReportBackfillJob` or `CitrusAdClicksReportBackfillJob` for the missed time window
- **GCS feed regeneration**: Re-run `CustomerFeedJob`, `OrderFeedJob`, or `PPIDAudienceJob` directly; GCS writes use `SaveMode.Overwrite` so re-runs are safe

### Check Airflow Permissions

If Airflow DAGs are not accessible, review GCP data pipeline access rights as documented in the Confluence page for GCP data pipelines (linked from `doc/trouble_shooting.md`).

## Troubleshooting

### Job is not running

- **Symptoms**: Expected GCS files not appearing; `ai_reporting` tables not updated; no metrics emitted
- **Cause**: Airflow DAG paused, task blocked, or YARN resource unavailability
- **Resolution**: (1) Check Airflow DAG enabled status and task logs in the appropriate environment's Airflow UI. (2) Check YARN Resource Manager for application state. (3) Verify upstream Hive data (`junoHourly` partitions) is available for the expected date.

### CitrusAd callbacks failing

- **Symptoms**: `citrus_impressions_report_exception` or `citrus_clicks_report_exception` metrics non-zero; CitrusAd reporting discrepancy
- **Cause**: CitrusAd API endpoint unreachable, ad ID invalid, or network issue from YARN executor nodes
- **Resolution**: (1) Verify `https://us-integration.citrusad.com` reachability from the YARN cluster. (2) Confirm `--isCitrusReportEnabled true` flag is set for the job. (3) Run the corresponding backfill job (`CitrusAdImpressionsReportBackfillJob` / `CitrusAdClicksReportBackfillJob`) to replay missed callbacks.

### Uplift model inference failing

- **Symptoms**: `UpliftModelPrediction` YARN application fails
- **Cause**: Model artifact missing from HDFS path, Hive table partition unavailable, or insufficient executor memory
- **Resolution**: (1) Verify the model artifact exists at the configured HDFS path (`/user/{user}/uplift_model/receipt/desktop/ml_model/{algorithm}/{numTrees}/{firstDayOfMonth}`). (2) Provide `--modelPath` override flag if path resolution fails. (3) Check `user_edwprod.fact_gbl_transactions` and `cia_realtime.user_attrs` partition availability for the `daysWindow` lookback period.

### PPID audience export failing

- **Symptoms**: `PPIDAudienceJob` YARN application fails with `SQLException`
- **Cause**: Teradata connectivity issue or `sandbox.ppid_export` table empty/locked
- **Resolution**: (1) Verify Teradata JDBC connectivity to `teradata.groupondev.com:1025` from YARN cluster. (2) Check `sandbox.ppid_export` data availability in Teradata. (3) Review YARN application logs for the specific `SQLException` message.

### Hive data missing upstream

- **Symptoms**: Jobs produce zero-count outputs; `pv_with_impressions_dataframe_count` gauge = 0
- **Cause**: Upstream `junoHourly` or `fact_gbl_transactions` partitions not yet available for the queried date
- **Resolution**: Verify Hive partition availability using `SHOW PARTITIONS grp_gdoop_pde.junoHourly` for the expected `eventdate`. Confirm upstream data pipeline SLAs with the data engineering team.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | CitrusAd/ClarusAd reporting completely down; all impression/click callbacks failing | Immediate | ads-eng@groupon.com; PagerDuty ad-inventory@groupon.pagerduty.com (service PS4HL4Y) |
| P2 | Individual job failures; partial reporting gaps | 30 min | ai-engineering Slack (CF8G3HBBP) |
| P3 | Delayed feeds; non-critical report discrepancies | Next business day | ads-eng@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Groupon Data Lake (Hive/junoHourly) | `SHOW PARTITIONS grp_gdoop_pde.junoHourly` | No fallback — jobs will produce zero output and alert |
| CitrusAd API | `curl https://us-integration.citrusad.com/v1/resource/first-i/test` | Run backfill job once endpoint is restored |
| DoubleClick/Clarus | `curl https://ad.doubleclick.net` | Run `ClarusAdImpressionsBackfillJob` once restored |
| MySQL (prod) | JDBC connectivity test | No automatic fallback — job will fail |
| Teradata | JDBC connectivity test | No automatic fallback — `PPIDAudienceJob` will fail |
| GCS | GCS connector availability | No automatic fallback — feed jobs will fail |
