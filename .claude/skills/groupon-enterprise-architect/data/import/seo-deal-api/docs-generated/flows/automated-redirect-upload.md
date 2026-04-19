---
service: "seo-deal-api"
title: "Automated Redirect Upload"
generated: "2026-03-03"
type: flow
flow_name: "automated-redirect-upload"
flow_type: batch
trigger: "seo-deal-redirect Airflow DAG scheduled at 0 5 15 * * (monthly, 15th day)"
participants:
  - "seo-deal-redirect"
  - "continuumSeoDealApiService"
  - "seoDealApi_apiResources"
  - "orchestrator"
  - "seoDataDao"
  - "continuumSeoDealPostgres"
architecture_ref: "components-seoDealApiServiceComponents"
---

# Automated Redirect Upload

## Summary

The `seo-deal-redirect` Airflow pipeline runs monthly on GCP Dataproc to compute expired-to-live deal redirect mappings and upload them to SEO Deal API. The pipeline computes which expired deal URLs should redirect to which live deal URLs by analyzing deal performance data, geographic proximity, and category matching. It then sends one HTTP PUT request per expired deal to `PUT /seodeals/deals/{dealId}/edits/attributes/redirectUrl` using mTLS certificate authentication (rate-limited to 1,250 calls per 60 seconds). SEO Deal API persists each redirect mapping to `continuumSeoDealPostgres`.

## Trigger

- **Type**: schedule
- **Source**: GCP Cloud Composer (Airflow) DAG `redirect-workflow` — `seo-deal-redirect` pipeline
- **Frequency**: Monthly (cron: `0 5 15 * *`); also supports manual DAG re-run

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `seo-deal-redirect` pipeline | Computes redirect mappings and drives the upload loop | External batch pipeline |
| GCP Dataproc cluster | Executes PySpark jobs for data processing and upload | Infrastructure |
| Hive Metastore | Stores intermediate redirect mapping tables | Infrastructure |
| `continuumSeoDealApiService` | Receives redirect PUT requests and persists mappings | `continuumSeoDealApiService` |
| API Resources (`seoDealApi_apiResources`) | Handles inbound HTTP PUT requests from the pipeline | `seoDealApi_apiResources` |
| Orchestrator (`orchestrator`) | Delegates redirect data writes | `orchestrator` |
| SEO Data DAO (`seoDataDao`) | Persists redirect URL updates to PostgreSQL | `seoDataDao` |
| SEO Deal Database | Stores updated redirect mappings | `continuumSeoDealPostgres` |

## Steps

1. **Airflow DAG triggered**: Cloud Composer starts the `redirect-workflow` DAG on schedule or manual trigger
   - From: Cloud Composer
   - To: `seo-deal-redirect` pipeline
   - Protocol: Airflow task execution

2. **Creates Dataproc cluster**: DAG creates a GCP Dataproc cluster (`seo-deal-redirect`) with Hive metastore and initialization scripts
   - From: Airflow DAG operator
   - To: GCP Dataproc
   - Protocol: GCP API

3. **Loads reference data**: Pipeline loads PDS blacklist, exclusion list, and manual redirects from GCS CSV files into Hive external tables
   - From: Dataproc Hive jobs
   - To: Hive Metastore / GCS
   - Protocol: Hive SQL

4. **Computes daily deal mappings**: Pipeline runs Hive queries to identify expired deals and live candidate deals, filtering by merchant, geography, and category, applying deduplication and cycle detection
   - From: Dataproc Hive jobs
   - To: Hive Metastore
   - Protocol: Hive SQL

5. **Populates final redirect mapping**: PySpark job `api_upload_table_population` generates the `final_redirect_mapping` Parquet table with `expired_uuid`, `expired_deal_permalink`, and `live_deal_url` columns
   - From: Dataproc PySpark job
   - To: GCS Parquet / Hive Metastore
   - Protocol: Spark/Parquet

6. **Reads new or changed redirects**: PySpark `api_upload` job reads the `final_redirect_mapping` parquet, compares with previously processed redirects to identify only new or changed deals
   - From: Dataproc PySpark job (`Mover.get_new_or_changed_deals`)
   - To: GCS Parquet
   - Protocol: Spark/Parquet

7. **Loads mTLS certificates**: Pipeline reads the PKCS12 keystore from GCS (`seo-deal-redirect-keystore.jks`), extracts the private key and certificate chain, and writes PEM files to local disk
   - From: `Mover.load_keystore_and_generate_pem_files`
   - To: Local filesystem
   - Protocol: OpenSSL/PKCS12

8. **Uploads redirects to SEO Deal API**: For each new or changed redirect, the pipeline sends a rate-limited `PUT /seodeals/deals/{expired_uuid}/edits/attributes/redirectUrl?source=seo-deal-redirect` with `{ "redirectUrl": "{live_deal_url}" }` body and mTLS cert
   - From: `Mover.make_api_request` (rate limited: 1250 calls/60s)
   - To: `continuumSeoDealApiService`
   - Protocol: REST/HTTP with mTLS (PKCS12 cert)

9. **API persists redirect**: SEO Deal API routes the PUT request through API Resources -> Orchestrator -> SEO Data DAO to update the redirect URL in PostgreSQL
   - From: `seoDealApi_apiResources`
   - To: `seoDataDao` -> `continuumSeoDealPostgres`
   - Protocol: JDBC/SQL

10. **Pipeline validates response**: For each PUT, the pipeline checks `res.status_code == 200` and verifies the response body contains `seoData.brands.groupon.attributes.redirectUrl` equal to the submitted URL
    - From: `Mover.make_api_request`
    - To: Log output
    - Protocol: In-process

11. **Saves processed redirects**: After upload, the pipeline overwrites the `previously_processed_redirects` Hive table for incremental diff on the next run
    - From: `Mover.save_processed_redirects`
    - To: Hive Metastore
    - Protocol: Spark/Hive

12. **Deletes Dataproc cluster**: DAG deletes the cluster to release GCP resources
    - From: Airflow DAG operator
    - To: GCP Dataproc
    - Protocol: GCP API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| HTTP non-200 response from SEO Deal API | Logged with status code, reason, and response body; processing continues | Individual redirect not persisted; pipeline does not retry |
| Response body mismatch (URL not reflected) | Logged as error with `json response error`; processing continues | Redirect write not confirmed; manual re-run needed |
| mTLS certificate expiry | `requests` library raises SSL error; pipeline logs exception | Entire upload batch fails; certificate must be renewed in GCS Secret Manager |
| Rate limit exceeded | Client-side rate limiter (`ratelimit` library) sleeps and retries | Automatic backoff; upload continues after rate window resets |
| `save_processed_redirects` failure | Logged as warning; pipeline continues execution | Incremental diff on next run falls back to full dataset |
| No previous redirects available | Pipeline processes all current redirects as new | Full upload performed |

## Sequence Diagram

```
Airflow -> DataprocCluster: Create cluster
DataprocCluster -> HiveMetastore: Load reference tables (blacklist, exclusion, manual redirects)
DataprocCluster -> HiveMetastore: Compute daily deal mappings (expired->live)
DataprocCluster -> GCS: Write final_redirect_mapping Parquet
DataprocCluster -> GCS: Read final_redirect_mapping Parquet
DataprocCluster -> GCS: Load PKCS12 keystore -> generate PEM files
loop [For each new or changed redirect, rate-limited at 1250/60s]
  DataprocCluster -> continuumSeoDealApiService: PUT /seodeals/deals/{expired_uuid}/edits/attributes/redirectUrl?source=seo-deal-redirect (mTLS)
  continuumSeoDealApiService -> continuumSeoDealPostgres: UPDATE redirect_url WHERE deal_id = expired_uuid
  continuumSeoDealPostgres --> continuumSeoDealApiService: Write confirmed
  continuumSeoDealApiService --> DataprocCluster: HTTP 200 { seoData: { brands: { groupon: { attributes: { redirectUrl: "..." } } } } }
end
DataprocCluster -> HiveMetastore: Save previously_processed_redirects
Airflow -> DataprocCluster: Delete cluster
```

## Related

- Architecture dynamic view: `components-seoDealApiServiceComponents`
- Related flows: [Deal SEO Attribute Update](deal-seo-attribute-update.md)
