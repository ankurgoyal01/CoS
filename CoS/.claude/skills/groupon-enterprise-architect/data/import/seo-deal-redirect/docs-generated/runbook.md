---
service: "seo-deal-redirect"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Airflow DAG run status (Cloud Composer UI) | Airflow UI / GCP Console | Daily (DAG schedule) | — |
| GCP Dataproc jobs console | GCP Console | Per run | — |

> No programmatic health check endpoint exists — this is a batch pipeline, not a long-running service. DAG run health is monitored through the Airflow UI and GCP Dataproc job logs.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Airflow DAG run success/failure | gauge | Whether the `redirect-workflow` DAG completed successfully | Failure triggers Airflow alert |
| API upload HTTP response codes | counter | Count of 200 vs. non-200 responses during `api_upload` job | Non-200 responses logged per deal |
| Redirect records published | gauge | Count of new/changed redirect records uploaded per run | > No evidence found in codebase |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Production Airflow UI | GCP Cloud Composer | `https://91c76cae09ac40609460f5e26460e6e8-dot-us-central1.composer.googleusercontent.com/home` |
| Production Dataproc Jobs | GCP Console | `https://console.cloud.google.com/dataproc/jobs?project=prj-grp-c-common-prod-ff2b` |
| Stable Airflow UI | GCP Cloud Composer | `https://4952faa6ee0242268293dfe488980af0-dot-us-central1.composer.googleusercontent.com/home` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| DAG run failure | `redirect-workflow` DAG completes with `failed` state | critical | Check Dataproc job logs; identify failed task; see Troubleshooting section |
| Slack notification | DeployBot posts start/complete/override events to `#seo-deployments` | info | Review deployment success in DeployBot UI |

## Common Operations

### Restart / Re-trigger DAG Run

1. Navigate to the Airflow UI for the target environment (production or stable — see links above).
2. Search for the `redirect-workflow` DAG.
3. Click the DAG, select the failed or skipped run date, and use "Clear" to re-run from the failed task, or "Trigger DAG" to start a fresh run.
4. Monitor task progress in the Airflow task instance view.

### Manually Fix an Incorrect Redirect

Send an HTTP PUT request to the SEO Deal API to override a specific deal's `redirectUrl`:

```
PUT https://seo-deal-api.production.service.us-central1.gcp.groupondev.com/seodeals/deals/{DEAL_UUID}/edits/attributes?source=manual
Content-Type: application/json

{ "redirectUrl": "https://groupon.com/deals/some-live-deal-permalink" }
```

To clear a redirect (set to null):
```json
{ "redirectUrl": null }
```

Replace `{DEAL_UUID}` with the UUID of the deal requiring correction.

### Add a Manual Redirect Override

1. Edit `data/prod/manual_redirects.csv` — add a row with `expired_uuid,live_uuid`.
2. Verify no cycles are introduced (deal A → B → A).
3. Open a PR to the `main` branch.
4. After merge, deploy to production via DeployBot.
5. The next DAG run will load the updated CSV into `manual_redirects_raw` and include the override in the mapping.

### Exclude a Deal from Redirects

1. Edit `data/prod/exclusion_list.csv` — add a row with `deal_uuid,deal_permalink`.
2. Open a PR and deploy as above.
3. The next DAG run will load the exclusion and suppress redirect generation for that deal.

### Scale Up / Down

Dataproc cluster size is defined in `orchestrator/config/prod/dag_properties.json` under `cluster_config`. To scale:
1. Modify `worker_config.num_instances` or change `machine_type_uri`.
2. Deploy the updated config file via the standard CI/CD pipeline.
3. The change takes effect on the next DAG run (new cluster is provisioned per run).

### Accessing Logs

- **Dataproc job logs** (production): `https://console.cloud.google.com/dataproc/jobs?project=prj-grp-c-common-prod-ff2b`
- **Dataproc cluster logs** (Stackdriver): Enabled via `dataproc:dataproc.logging.stackdriver.enable: true`
- **Airflow task logs**: Available in the Cloud Composer UI → DAG → task instance → "Log" tab

## Troubleshooting

### DAG run fails at Hive ETL step

- **Symptoms**: Airflow task in `get_daily_deals`, `map_expired_to_live`, or similar shows `failed` status
- **Cause**: EDW source table unavailable, Dataproc cluster connectivity issue, or Hive metastore timeout
- **Resolution**: Check Dataproc job logs for the specific HQL error. Verify EDW source table availability in the GCP Hive console. Re-clear the failed task in Airflow to retry.

### API upload reports non-200 responses for all deals

- **Symptoms**: `api_upload` job logs show HTTP 4xx or 5xx errors for every PUT request
- **Cause**: SEO Deal API is unavailable, mTLS certificate has expired, or network route to `edge-proxy--production` is broken
- **Resolution**:
  1. Verify the SEO Deal API is healthy.
  2. Check that the TLS secret `tls--seo-seo-deal-redirect` in GCP Secret Manager is current and the keystore `seo-deal-redirect-keystore.jks` loads correctly.
  3. Re-run the `api_upload` Dataproc job after fixing the root cause.

### Redirect cycle detected / mapping table growing unexpectedly

- **Symptoms**: `daily_expired_to_live_no_cycles` table shows far fewer records than `daily_expired_to_live_deduped`, or cycle removal step takes unusually long
- **Cause**: Manual redirect or algorithmic match creates a circular chain (A → B → A)
- **Resolution**:
  1. Query `daily_expired_to_live_deduped` to find chains where `live_uuid` appears as `expired_uuid` for another row.
  2. Add the problematic deal to `data/prod/exclusion_list.csv` or correct `data/prod/manual_redirects.csv`.
  3. Deploy the fix and re-run.

### Missing redirects for a known expired deal

- **Symptoms**: An expired deal URL returns a 404 instead of redirecting
- **Cause**: Deal is in the exclusion list, the merchant has no active deals matching the criteria, or the redirect was not published due to a cycle
- **Resolution**:
  1. Verify the deal UUID is not in `data/prod/exclusion_list.csv` or `data/prod/pds_id_bl.csv`.
  2. Check `daily_deals` for an active deal from the same merchant with matching location/category.
  3. If no algorithmic match exists, add a manual redirect to `data/prod/manual_redirects.csv`.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Entire redirect pipeline down for multiple days; SEO rankings degrading | Immediate | SEO team lead; computational-seo@groupon.com; #computational-seo Slack |
| P2 | Single DAG run failed; redirects not updated for one day | 30 min | On-call SEO engineer; #computational-seo Slack |
| P3 | Individual deal redirect incorrect or missing | Next business day | SEO team via #computational-seo Slack |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `seo-deal-api` | Make a test PUT to the staging endpoint; check HTTP 200 | No automatic fallback; previous redirects remain in place from last successful run |
| GCP Dataproc | Check cluster creation in GCP Console | No fallback; DAG run fails |
| EDW Hive tables (`edwprod.*`) | Run a sample `SELECT COUNT(*)` query on `edwprod.ods_deal` in Dbeaver or beeline | DAG task fails; re-run when EDW is available |
| GCP Secret Manager | `gcloud secrets versions access latest --secret=tls--seo-seo-deal-redirect` | Cannot authenticate to SEO Deal API; block API upload until secret is restored |
