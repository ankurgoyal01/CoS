---
service: "seo-deal-redirect"
title: "API Upload"
generated: "2026-03-03"
type: flow
flow_name: "api-upload"
flow_type: batch
trigger: "Executed as tasks within the daily redirect pipeline DAG after final table population"
participants:
  - "continuumSeoDealRedirectJobs"
  - "continuumSeoHiveWarehouse"
  - "gcpCloudStorage"
  - "seoDealApi"
architecture_ref: "components-seoDealRedirectJobs"
---

# API Upload

## Summary

The API upload flow is the final publishing step of the redirect pipeline. It consists of two PySpark jobs: `api_upload_table_population` constructs fully-qualified live deal URLs and writes a partitioned Parquet output (`final_redirect_mapping`); then `api_upload` reads this output, diffs it against the previous run to find only new or changed redirects, and HTTP PUT's each update to the SEO Deal API. Rate limiting is enforced client-side at 1,250 calls per 60 seconds.

## Trigger

- **Type**: batch task (sub-flow within the daily pipeline)
- **Source**: Airflow DAG tasks `purge_final_redirect_table` → `api_upload_table_population` → `refresh_hive_table` → `api_upload`
- **Frequency**: Daily, as part of the [Daily Redirect Pipeline](daily-redirect-pipeline.md)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Upload Table Population Job | Builds `final_redirect_mapping` Parquet with insert/update/delete action rows | `apiUploadTablePopulation` (component of `continuumSeoDealRedirectJobs`) |
| API Upload Job | Diffs and uploads new/changed redirects to SEO Deal API | `apiUploadJob` (component of `continuumSeoDealRedirectJobs`) |
| SEO Hive Warehouse | Source for cycle-free mapping; target for Hive table repair | `continuumSeoHiveWarehouse` |
| GCP Cloud Storage | Storage for Parquet output at `{base_path}/final_redirect_mapping/dt={run_date}/` | `gcpCloudStorage` (stub) |
| SEO Deal API | Receives redirect URL updates for each expired deal UUID | `seoDealApi` (stub) |

## Steps

### Phase 1: Final Table Population (`api_upload_table_population`)

1. **Purge current partition**: Deletes the `final_redirect_mapping` partition for `run_date` to ensure idempotency.
   - From: `hiveEtlScripts`
   - To: `continuumSeoHiveWarehouse`
   - Protocol: HiveQL

2. **Identify new redirects (INSERT)**: Queries `daily_expired_to_live_no_cycles` for rows not already present in `final_redirect_mapping` from prior runs. Tags these rows with `action = 'create'`.
   - From: `apiUploadTablePopulation`
   - To: `continuumSeoHiveWarehouse`
   - Protocol: Spark SQL LEFT ANTI JOIN

3. **Identify changed redirects (UPDATE)**: Queries `daily_expired_to_live_no_cycles` joined against the most recent `final_redirect_mapping` partition, keeping rows where `live_uuid` has changed. Tags these rows with `action = 'update'`.
   - From: `apiUploadTablePopulation`
   - To: `continuumSeoHiveWarehouse`
   - Protocol: Spark SQL INNER JOIN + RANK window function

4. **Identify deletions (EXCLUDE)**: Queries deals newly added to `deal_exclusion_list` (present in `post` partition but not `pre` partition). Tags these rows with `action = 'delete'` and `live_deal_url = NULL`.
   - From: `apiUploadTablePopulation`
   - To: `continuumSeoHiveWarehouse`
   - Protocol: Spark SQL LEFT JOIN

5. **Construct full URLs**: Applies a PySpark UDF (`get_full_url`) to each row to build the complete live deal URL: `{env_url_prefix}{domain_from_country_map}{deal_suffix}{live_deal_permalink}`. For delete-action rows, URL remains `NULL`.
   - From: `apiUploadTablePopulation`
   - To: local Spark UDF
   - Protocol: PySpark UDF

6. **Write Parquet output**: Writes the final DataFrame (insert + update + delete rows) as partitioned Parquet to GCS at `{base_path}/final_redirect_mapping/dt={run_date}/`.
   - From: `apiUploadTablePopulation`
   - To: `gcpCloudStorage`
   - Protocol: Spark `write.parquet()`

7. **Repair Hive table**: Executes `MSCK REPAIR TABLE final_redirect_mapping` to register the new partition in the Hive metastore.
   - From: `hiveEtlScripts`
   - To: `continuumSeoHiveWarehouse`
   - Protocol: HiveQL

### Phase 2: API Upload (`api_upload`)

8. **Read current redirects**: Reads the `final_redirect_mapping` Parquet output for `run_date` from GCS. Selects `expired_uuid`, `expired_deal_permalink`, `live_deal_url`.
   - From: `apiUploadJob`
   - To: `gcpCloudStorage`
   - Protocol: Spark `read.parquet()`

9. **Read previous redirects**: Reads the `previously_processed_redirects` Hive table (snapshot of last successful upload). Returns an empty DataFrame if the table does not yet exist.
   - From: `apiUploadJob`
   - To: `continuumSeoHiveWarehouse`
   - Protocol: Spark SQL

10. **Diff against previous run**: Computes new/changed deals via:
    - **New**: records in current but not in previous (LEFT ANTI JOIN on `expired_uuid`)
    - **Changed**: records in both where `live_deal_url` differs (INNER JOIN + WHERE filter)
    - From: `apiUploadJob`
    - To: local Spark operation
    - Protocol: PySpark DataFrame

11. **Load TLS credentials**: Reads the PKCS12 keystore at `keystore_path`, extracts the private key and certificate chain, and writes them as PEM files to `key_file_path` and `cert_file_path`.
    - From: `apiUploadJob`
    - To: GCP Secret Manager (pre-mounted at cluster init)
    - Protocol: `pyOpenSSL` / file I/O

12. **HTTP PUT each redirect**: For each new/changed deal, makes an authenticated HTTPS PUT request to:
    `{api_host}/seodeals/deals/{expired_uuid}/edits/attributes/redirectUrl?source=seo-deal-redirect`
    with body `{"redirectUrl": "<live_deal_url>"}`. Rate-limited to 1,250 calls per 60 seconds.
    - From: `apiUploadJob`
    - To: `seoDealApi`
    - Protocol: HTTPS PUT with mTLS

13. **Save processed redirects snapshot**: Writes the new/changed deal DataFrame to the `previously_processed_redirects` Hive table (mode=overwrite) for use in the next run's diff.
    - From: `apiUploadJob`
    - To: `continuumSeoHiveWarehouse`
    - Protocol: Spark `write.saveAsTable()`

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| API returns non-200 for a deal | Error is logged with status, reason, and response body; loop continues to next deal | That deal's redirect is not updated; previous redirect (if any) remains |
| Response body `redirectUrl` does not match submitted URL | Logged as `'error', 'failed', 'json response error'` | Redirect may not have been applied correctly |
| `previously_processed_redirects` table missing | Empty DataFrame substituted; all current redirects treated as new | All current redirects are uploaded (full refresh behavior) |
| `save_processed_redirects` fails | Exception is caught and logged; job continues | Next run will do a full diff again (no snapshot to compare against) |
| keystore loading fails | Exception propagates; job exits with code 1 | No API calls are made; Airflow task fails |

## Sequence Diagram

```
apiUploadTablePopulation -> continuumSeoHiveWarehouse: SELECT insert/update/delete rows from daily_expired_to_live_no_cycles
apiUploadTablePopulation -> gcpCloudStorage: Write final_redirect_mapping Parquet (dt=run_date)
hiveEtlScripts -> continuumSeoHiveWarehouse: MSCK REPAIR TABLE final_redirect_mapping
apiUploadJob -> gcpCloudStorage: Read final_redirect_mapping Parquet (current run)
apiUploadJob -> continuumSeoHiveWarehouse: Read previously_processed_redirects
apiUploadJob -> apiUploadJob: Diff (LEFT ANTI JOIN + INNER JOIN WHERE url changed)
apiUploadJob -> apiUploadJob: Load JKS keystore, write cert.pem + key.pem
loop [for each new/changed deal, rate-limited 1250/60s]
  apiUploadJob -> seoDealApi: PUT /seodeals/deals/{uuid}/edits/attributes/redirectUrl
  seoDealApi --> apiUploadJob: HTTP 200 + updated deal SEO data
end
apiUploadJob -> continuumSeoHiveWarehouse: Overwrite previously_processed_redirects
```

## Related

- Parent flow: [Daily Redirect Pipeline](daily-redirect-pipeline.md)
- Previous flow: [Deduplication and Cycle Removal](deduplication-and-cycle-removal.md)
- Architecture refs: `apiUploadTablePopulation`, `apiUploadJob` components within `continuumSeoDealRedirectJobs`
- API endpoint: `PUT /seodeals/deals/{deal_uuid}/edits/attributes/redirectUrl` (see [API Surface](../api-surface.md))
