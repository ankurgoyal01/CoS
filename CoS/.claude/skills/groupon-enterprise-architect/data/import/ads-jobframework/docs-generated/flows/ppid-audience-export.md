---
service: "ads-jobframework"
title: "PPID Audience Export"
generated: "2026-03-03"
type: flow
flow_name: "ppid-audience-export"
flow_type: batch
trigger: "Scheduled via Airflow (Cloud Composer)"
participants:
  - "continuumAdsJobframeworkSpark"
  - "continuumAdsJobframeworkTeradata"
  - "continuumAdsJobframeworkGcsBucket"
architecture_ref: "dynamic-ads-jobframework"
---

# PPID Audience Export

## Summary

This flow reads Publisher Provided Identifier (PPID) audience membership data from a Teradata sandbox table, SHA-256 hashes the encrypted cookie identifiers to produce anonymized PPIDs, and writes the result as a timestamped CSV to GCS. The GCS file is then consumed by Google's DFP (DoubleClick for Publishers) for audience-based ad targeting. The flow handles large audience sets by automatically partitioning output files at 10 million records each.

## Trigger

- **Type**: schedule
- **Source**: Airflow DAG (Cloud Composer) — external to this service
- **Frequency**: Scheduled (frequency not specified in codebase)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Ads Spark Job Framework | Executes the job; reads Teradata; hashes; writes to GCS | `continuumAdsJobframeworkSpark` |
| Teradata Sandbox | Source of PPID audience export table (`sandbox.ppid_export`) | `continuumAdsJobframeworkTeradata` |
| GCS Analytics Bucket | Destination for PPID audience CSV files | `continuumAdsJobframeworkGcsBucket` |

## Steps

1. **Read PPID export from Teradata**: Executes a JDBC query via the CDE `TeraDataSparkConnection` to read all rows from `sandbox.ppid_export` with columns `cookie_encrypted`, `list_id`, `delete`, `process_consent`.
   - From: `continuumAdsJobframeworkSpark`
   - To: `continuumAdsJobframeworkTeradata`
   - Protocol: Teradata JDBC (`jdbc:teradata://teradata.groupondev.com/DATABASE=sandbox,DBS_PORT=1025,COP=OFF`)

2. **Validate result**: Checks if the returned DataFrame is empty. If empty, logs a warning and exits without writing to GCS.
   - From: `continuumAdsJobframeworkSpark`
   - To: local check

3. **Filter and hash**: Filters rows to non-null `cookie_encrypted` and `list_id`; applies SHA-256 hash UDF to `cookie_encrypted` to produce the `ppid` column; clears `process_consent` to empty string.
   - From: `continuumAdsJobframeworkSpark`
   - To: local Spark transformation

4. **Partition for output**: Calculates number of file partitions as `ceil(total_count / 10,000,000)` to stay within DFP upload limits. Repartitions the DataFrame accordingly. Disables Hadoop write checksum.
   - From: `continuumAdsJobframeworkSpark`
   - To: local Spark transformation

5. **Write CSV to GCS**: Writes the partitioned DataFrame as CSV with header to `gs://gdfp_cookieupload_21693248851/PPID_audience_export_{yyyy-MM-dd_HH-mm-ss}.csv` using `SaveMode.Overwrite` with null/empty values written as null bytes.
   - From: `continuumAdsJobframeworkSpark`
   - To: `continuumAdsJobframeworkGcsBucket`
   - Protocol: GCS connector (Hadoop FileSystem)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Teradata `SQLException` | Caught; logged; `RuntimeException` thrown; YARN app fails | Job marked failed in Airflow; no GCS write |
| Teradata connection failure | Caught as `Exception`; logged; `RuntimeException` thrown; YARN app fails | Same |
| Empty PPID export table | Early return with warning log | No GCS file written; no error |
| GCS write failure | Spark exception propagates; YARN app fails | Retry is safe (timestamped file path is unique per run) |

## Sequence Diagram

```
Airflow -> AdsJobFrameworkSpark: Trigger PPIDAudienceJob
AdsJobFrameworkSpark -> TeradataSandbox: JDBC SELECT cookie_encrypted, list_id, delete, process_consent FROM sandbox.ppid_export
TeradataSandbox --> AdsJobFrameworkSpark: PPID audience DataFrame
AdsJobFrameworkSpark -> AdsJobFrameworkSpark: Filter non-null; SHA-256 hash cookie_encrypted -> ppid; clear process_consent
AdsJobFrameworkSpark -> AdsJobFrameworkSpark: Repartition to ceil(count / 10M) partitions
AdsJobFrameworkSpark -> GCSBucket: Write CSV to gs://gdfp_cookieupload_21693248851/PPID_audience_export_{timestamp}.csv
GCSBucket --> AdsJobFrameworkSpark: Write success
```

## Related

- Architecture dynamic view: `dynamic-ads-jobframework`
- Related flows: [Customer Feed Export](customer-feed-export.md)
- GCS output path: `gs://gdfp_cookieupload_21693248851/PPID_audience_export_{datetime}.csv`
