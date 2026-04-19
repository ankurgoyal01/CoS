---
service: "sem-gcp-pipelines"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "gcsDagsBucket_c78c51"
    type: "gcs"
    purpose: "DAG artifacts and pipeline configuration"
  - id: "gcsArtifactsBucket_aedc8c"
    type: "gcs"
    purpose: "Job artifacts (ZIP bundles) deployed by CI/CD"
  - id: "gcsDataBucket_a28d89"
    type: "gcs"
    purpose: "SEM pipeline data (Parquet, Hive-partitioned)"
---

# Data Stores

## Overview

sem-gcp-pipelines does not own or maintain any persistent relational databases or caches. Its data storage strategy relies entirely on GCS (Google Cloud Storage) buckets acting as a distributed file system for pipeline data, artifacts, and configuration. Data is written to GCS by Dataproc Spark jobs in Parquet format (Snappy-compressed, Hive-partitioned), and read back by subsequent pipeline steps. The service also reads from a Dataproc Metastore (Hive-compatible) for schema and partition management during Spark job execution.

## Stores

### DAGs Bucket (`gcsDagsBucket_c78c51`)

| Property | Value |
|----------|-------|
| Type | GCS (Google Cloud Storage) |
| Architecture ref | `gcsDagsBucket_c78c51` |
| Purpose | Stores Airflow DAG Python files deployed by the CI/CD pipeline for GCP Composer to pick up |
| Ownership | external (managed by GCP Composer) |
| Migrations path | Not applicable |

#### Key Entities

| Path Pattern | Purpose | Key Fields |
|-------------|---------|-----------|
| `dags/transam/` | SEM/Display Marketing DAG definitions | DAG Python files |

#### Access Patterns

- **Read**: GCP Composer reads DAG files from this bucket automatically on a polling interval
- **Write**: CI/CD (deploy-bot) copies compiled DAG artifacts from the build to this bucket on each deployment

| Environment | Bucket |
|-------------|--------|
| dev | `us-central1-grp-shared-comp-155675d0-bucket` |
| stable | `us-central1-grp-shared-comp-03dba3de-bucket` |
| prod | `us-central1-grp-shared-comp-9260309b-bucket` |

---

### Artifacts Bucket (`gcsArtifactsBucket_aedc8c`)

| Property | Value |
|----------|-------|
| Type | GCS (Google Cloud Storage) |
| Architecture ref | `gcsArtifactsBucket_aedc8c` |
| Purpose | Stores ZIP artifact bundles downloaded by Dataproc cluster init scripts so that Python jobs can import `orchestrator.*` modules |
| Ownership | shared (used by multiple SEM pipelines) |
| Migrations path | Not applicable |

#### Key Entities

| Path Pattern | Purpose |
|-------------|---------|
| `/com/groupon/transam/sem-gcp-pipelines/{VERSION}/sem-gcp-pipelines-{VERSION}.zip` | Versioned Python job bundle fetched by Artifactory-backed GCS proxy |

#### Access Patterns

- **Read**: Dataproc cluster init script (`load-artifacts.sh`) downloads the ZIP bundle at cluster startup; `python_file_uris` in PySpark job definitions reference this path
- **Write**: Jenkins CI/CD publishes ZIP artifacts to Artifactory, which is then referenced at runtime

| Environment | Bucket |
|-------------|--------|
| dev | `grpn-dnd-dev-consumer-artifacts/grp-sem-group` |

---

### Data Bucket (`gcsDataBucket_a28d89`)

| Property | Value |
|----------|-------|
| Type | GCS (Google Cloud Storage) |
| Architecture ref | `gcsDataBucket_a28d89` |
| Purpose | Primary data storage for SEM pipeline inputs, intermediate results, and keyword generation outputs (Parquet, Hive-partitioned) |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Path Pattern | Purpose | Key Fields |
|-------------|---------|-----------|
| `gs://grpn-dnd-prod-analytics-grp-sem-group/` | Root production data bucket for SEM group | Parquet files, Hive partitions |
| `user/grp_gdoop_sem_group/jars/sem-common-jobs-{version}.jar` | Java Spark job JAR used by all common-jobs DAGs | Java bytecode |
| `{kwgen_hdfs_path}/region={region}/country={country}/target_date={date}` | Final keyword submission data (Parquet) | deal, country, keyword, user |

#### Access Patterns

- **Read**: `SubmitKeywords` PySpark job reads final keyword Parquet files, partitioned by region, country, and target_date; `GSUtils` class uses `gsutil ls` to check partition existence before reading
- **Write**: Upstream Spark jobs (keyword generation) write Parquet files to Hive-partitioned paths on this bucket; Dataproc jobs use Snappy compression (`spark.sql.parquet.compression.codec=snappy`)

| Environment | Bucket |
|-------------|--------|
| dev | `grpn-dnd-dev-analytics-grp-sem-group` |
| stable | `grpn-dnd-stable-analytics-grp-sem-group` |
| prod | `grpn-dnd-prod-analytics-grp-sem-group` |

---

### Dataproc Metastore (Hive)

| Property | Value |
|----------|-------|
| Type | Hive / Dataproc Metastore |
| Architecture ref | part of `gcpDataprocCluster_469e25` |
| Purpose | Hive metastore for Spark SQL schema resolution and partition management during job execution |
| Ownership | external (GCP managed) |

- **Prod metastore**: `projects/prj-grp-datalake-prod-8a19/locations/us-central1/services/grpn-dpms-prod-analytics`

## Caches

> No evidence found in codebase. No caching layer is used; each pipeline run reads fresh data from GCS.

## Data Flows

Data flows through GCS as the shared buffer between pipeline stages:

1. Upstream keyword generation Spark jobs write Parquet output to `gcsDataBucket_a28d89` partitioned by region/country/date.
2. The `SubmitKeywords` DAG reads those partitions and publishes messages to the Message Bus.
3. Feed generation Spark jobs (`sem-common-jobs` JAR) read deal data from internal APIs and GCS, produce feed files, and deliver them to external platforms via SFTP or direct API calls.
4. The `sem-common-jobs` JAR is stored in `gcsDataBucket_a28d89` under `user/grp_gdoop_sem_group/jars/`.
