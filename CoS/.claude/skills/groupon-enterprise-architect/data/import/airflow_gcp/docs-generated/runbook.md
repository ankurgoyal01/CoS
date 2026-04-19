---
service: "airflow_gcp"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Airflow DAGs UI (per-environment) | HTTP (browser) | On demand | — |
| Cloud Logging | GCP log stream | On demand | — |
| Email alert on DAG failure | SMTP notification | Per failure event | — |

- **DEV Airflow UI**: https://d134c969a7dc418dba6e877f8f4fa5b0-dot-us-central1.composer.googleusercontent.com/home
- **STABLE Airflow UI**: https://4952faa6ee0242268293dfe488980af0-dot-us-central1.composer.googleusercontent.com/home
- **PROD Airflow UI**: https://91c76cae09ac40609460f5e26460e6e8-dot-us-central1.composer.googleusercontent.com/home
- **Cloud Logging**: https://cloudlogging.app.goo.gl/zJ2xKMW2iRirKKSk6
- **Google Chat**: https://chat.google.com/room/AAAAViiQs_Q

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| DAG run status | gauge | Pass/fail state of each DAG run in Airflow UI | Failure triggers email to `sfint-dev-alerts@groupon.com` |
| Task instance duration | gauge | Execution time of individual Airflow tasks | No configured threshold — monitor via Airflow UI graph view |
| Bulk upload failure count | counter | Number of records failing Salesforce bulk upload | Logged to GCS `bulk_upload_failed_results.csv`; no automated threshold alert |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Airflow DAGs UI (Production) | Google Cloud Composer | https://91c76cae09ac40609460f5e26460e6e8-dot-us-central1.composer.googleusercontent.com/home |
| Cloud Logging | Google Cloud Logging | https://cloudlogging.app.goo.gl/zJ2xKMW2iRirKKSk6 |
| SRE Dashboard | n/a | `.service.yml` states `sre.dashboards: n/a` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| DAG task failure email | Any Airflow task raises an exception | warning | Check logs in Airflow DAG UI graph view; investigate source system availability |
| Hive SSL certificate error | Hive DAG fails with SSL/certificate error | warning | Follow SSL Certificate Rotation procedure (see below) |
| EDW password expiry | Teradata DAG fails with authentication error | warning | Reset `ab_SalesForceDC` account password at https://tss.groupondev.com/accounts |

## Common Operations

### Pause / Unpause a DAG

1. Navigate to the appropriate Airflow UI (dev/staging/prod).
2. Locate the DAG in the DAGs list view.
3. Toggle the on/off switch next to the DAG name to pause or resume it.

### Trigger a DAG Manually

1. Navigate to the Airflow UI.
2. Find the DAG and click the "Trigger DAG" (play) button.
3. Monitor task execution in the Graph view.

### Restart a Failed Task

1. Navigate to the DAG run in the Airflow UI.
2. Click on the failed task in the Graph view.
3. Select "Clear" to reset the task state and allow it to re-run.

### Deploy New DAGs

1. Add the new DAG as a Python script in the `orchestrator/` directory.
2. Push changes to the `release` or `main` branch.
3. Cloud Jenkins automatically builds and deploys to dev.
4. Use Deploybot to promote to staging and production.
5. Verify the DAG appears in the Airflow UI.

### Rollback a Deployment

1. Go to https://deploybot.groupondev.com/salesforce/airflow_gcp.
2. Find the previous successful deployment.
3. Click "Revert" to redeploy the previous commit.
4. Verify in the Airflow UI that DAGs reflect the reverted state.

### Update EDW Password

1. Obtain account owner access for the `ab_SalesForceDC` account.
2. Navigate to https://tss.groupondev.com/accounts.
3. Locate the `ab_SalesForceDC` account and perform "Reset Password".
4. Update the corresponding Airflow Variable or GCS secrets blob with the new password.
5. Trigger the `secrets_reloader_dag` to propagate the updated secret.

### Reload Secrets Manually

1. Navigate to the Airflow UI.
2. Trigger the `secrets_reloader_dag` manually.
3. This reads `secrets/variable-secrets.json` from the GCS working bucket and sets the corresponding Airflow Variables.

## SSL Certificate Rotation (Hive JDBC Truststore)

When Hive DAGs fail with SSL/certificate errors, the Hive server certificate has likely been rotated without updating the JKS truststore. Certificates use Let's Encrypt and expire every 90 days.

### Step 1: Check Current Certificate Expiry

```bash
openssl s_client -connect analytics.data-comp.prod.gcp.groupondev.com:8443 \
  -servername analytics.data-comp.prod.gcp.groupondev.com </dev/null 2>/dev/null | \
  openssl x509 -noout -dates
```

### Step 2: Extract the New Certificate

```bash
openssl s_client -connect analytics.data-comp.prod.gcp.groupondev.com:8443 \
  -servername analytics.data-comp.prod.gcp.groupondev.com \
  -showcerts </dev/null 2>/dev/null | \
  openssl x509 -outform PEM > hive-server-cert.pem
```

### Step 3: Update the Truststore

```bash
keytool -import -noprompt \
  -alias hive-server-cert \
  -file hive-server-cert.pem \
  -keystore DigiCertGlobalRootG2.jks \
  -storetype JKS \
  -storepass <store_pass>
```

> Acquire the actual truststore password before running this command. Do not document the password value.

### Step 4: Deploy the Updated Truststore

1. Replace `orchestrator/certificates/DigiCertGlobalRootG2.jks` with the updated file.
2. Commit and push to trigger the normal deployment pipeline.
3. Verify by running any Hive DAG to confirm SSL connections succeed.

**Set a calendar reminder** before the `notAfter` expiry date shown in Step 1.

## Troubleshooting

### DAG Fails with Salesforce Bulk API Error

- **Symptoms**: `submit_sf_bulk_update_request` or `save_sf_bulk_update_results_in_gcs` task fails; email alert received at `sfint-dev-alerts@groupon.com`
- **Cause**: Salesforce API unavailability, credential expiry (`sfdc_etl_sf_conn_password`), or invalid data in the staging CSV
- **Resolution**: Check Cloud Logging for the full stack trace; verify Salesforce connection credentials are current; inspect the staging CSV file in GCS for data issues; retry by clearing the failed task in Airflow UI

### DAG Fails with Teradata Connection Error

- **Symptoms**: `save_edw_data_to_gcs` task fails with authentication or connection error
- **Cause**: EDW password for `ab_SalesForceDC` has expired, or Teradata host `teradata.groupondev.com` is unreachable
- **Resolution**: Reset the `ab_SalesForceDC` password at https://tss.groupondev.com/accounts; update the secret in the GCS secrets blob; trigger `secrets_reloader_dag`

### Hive DAG Fails with SSL Certificate Error

- **Symptoms**: Hive-based DAG task fails with SSL handshake or certificate validation error
- **Cause**: Hive server SSL certificate has been rotated; JKS truststore in `orchestrator/certificates/DigiCertGlobalRootG2.jks` is outdated
- **Resolution**: Follow the SSL Certificate Rotation procedure above

### GCS Access Denied

- **Symptoms**: Any task that reads or writes GCS fails with permissions error
- **Cause**: `sfdc_etl_gcloud_connection` service account credentials have expired or lost bucket permissions
- **Resolution**: Check the GCP IAM permissions for the service account; rotate credentials if needed; update the Airflow connection

### DAG Not Appearing in Airflow UI After Deployment

- **Symptoms**: Newly deployed DAG file is not visible in the Airflow DAGs list
- **Cause**: DAG file may have a Python syntax error preventing import, or the file was not deployed to the correct GCS bucket path
- **Resolution**: Check Cloud Logging for import errors; verify the file exists at `us-central1-grp-shared-comp-9260309b-bucket/dags/salesforce/airflow_gcp/`; fix any syntax errors and redeploy

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | All DAGs failing; Salesforce data not updating | Immediate | sfint-dev@groupon.com; Google Chat: https://chat.google.com/room/AAAAViiQs_Q |
| P2 | Subset of DAGs failing; specific Salesforce fields stale | 30 min | sfint-dev@groupon.com |
| P3 | Single DAG failure; minor data freshness impact | Next business day | sfint-dev@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Salesforce | Test via Airflow UI manual trigger of any SF-writing DAG | Pause affected DAGs; investigate SF status page |
| Teradata EDW | Run a test SQL query via `teradatasql` from a Composer worker | Pause affected DAGs; contact Data Engineering team |
| Hive Cluster | Check SSL connectivity using `openssl s_client` command | Follow SSL Certificate Rotation procedure |
| Google Secret Manager | Check `secrets_reloader_dag` run status | Manually set Airflow Variables from known-good values |
| GCS | Check bucket accessibility via GCP Console | Contact SRE / Platform team for bucket permission issues |
