---
service: "janus-yati"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["env-vars", "airflow-variables", "yaml-files", "gcp-secret-manager"]
---

# Configuration

## Overview

Janus Yati configuration is layered across four sources. Environment-level constants (project IDs, bucket names, Kafka endpoints, cluster sizes) are defined in Python config modules under `orchestrator/yati_config/config_<env>.py`. Per-job Spark arguments and cluster definitions are driven by YAML files (`dataproc_spark_job_config_<env>.yaml`, `dataproc_cluster_pool_config_<env>.yaml`). Secrets (Kafka keystores, Hive passwords) are provisioned on Dataproc nodes via the cluster initialisation script or retrieved at runtime from GCP Secret Manager. A single Airflow Variable `env` selects the active environment. The JAR artifact version is injected at CI deploy time via `PIPELINE_ARTIFACT_VERSION`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `PIPELINE_ARTIFACT_VERSION` | Janus Yati JAR version; embedded in GCS artifact path and Spark `--metricsAtomTagValue` | yes | none | CI/CD pipeline (Jenkins `dataPipeline`) |
| `env` | Airflow Variable that selects the config module (`config_prod`, `config_stable`, `config_sox`, etc.) | yes | none | Airflow Variable store |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found in codebase.

No runtime feature flags are configured in this repository. Behavioural variants are controlled by Spark job arguments (`--outputFormat`, `--messageFormat`, `--isAuditReplay`, `--junoCorruptRecordCheck`, `--junoExcludedEventsConditionExpr`, `--kafkaHeaderFilterConditionExpr`) defined in the YAML config files.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `orchestrator/yati_config/config.py` | Python | Base config module; merges env-specific module; defines cluster defaults, artifact URL, and DAG-level config for all non-streaming jobs |
| `orchestrator/yati_config/config_prod.py` | Python | Production-specific values: GCP project ID, bucket names, Kafka endpoints, cluster machine types, job arguments |
| `orchestrator/yati_config/config_stable.py` | Python | Stable (pre-prod) environment overrides |
| `orchestrator/yati_config/config_sox.py` | Python | SOX compliance configuration; uses separate service account and SOX-segregated GCS paths |
| `orchestrator/yati_config/config_prod_sox.py` | Python | Production SOX config variant |
| `orchestrator/yati_config/config_stable_sox.py` | Python | Stable SOX config variant |
| `orchestrator/yati_config/dataproc_spark_job_config_prod.yaml` | YAML | Per-DAG Spark job definitions (main class, JAR URI, Spark properties, Kafka args, GCS output paths, checkpoint locations) for non-GCP jobs |
| `orchestrator/yati_config/dataproc_spark_job_config_gcp_prod.yaml` | YAML | Per-DAG Spark job definitions for GCP-native Kafka cluster jobs |
| `orchestrator/yati_config/dataproc_spark_job_config_stable.yaml` | YAML | Stable environment Spark job config |
| `orchestrator/yati_config/dataproc_spark_job_config_gcp_stable.yaml` | YAML | Stable GCP Spark job config |
| `orchestrator/yati_config/dataproc_cluster_pool_config_prod.yaml` | YAML | Long-running Dataproc cluster pool definitions (machine types, worker counts, subnetwork, service accounts) |
| `orchestrator/yati_config/dataproc_cluster_pool_config_gcp_prod.yaml` | YAML | GCP-native long-running cluster pool config |
| `orchestrator/yati_config/dataproc_cluster_pool_default_config.yaml` | YAML | Default cluster config applied to all pools |
| `orchestrator/yati_config/dataproc_job_default_config.yaml` | YAML | Default Dataproc job submission config (region, labels) |
| `src/main/resources/metrics.yml` | YAML | Codahale metrics reporter config; destination URL `http://localhost:8186/`, flush interval 10s |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `/var/groupon/janus-yati-keystore.jks` | Kafka SSL client keystore for mutual TLS to Kafka brokers and Hybrid Boundary | Provisioned by Dataproc cluster init script (`gs://prod-us-janus-operational-bucket/initscript.sh`) |
| `/var/groupon/truststore.jks` | Kafka SSL truststore | Provisioned by Dataproc cluster init script |
| `janus-hive-credentials` | Hive Metastore JDBC password for `svc_gcp_janus` user | GCP Secret Manager (project `prj-grp-pipelines-prod-bb85`) |
| `sa-dataproc-nodes@prj-grp-janus-prod-0808.iam.gserviceaccount.com` | Service account for non-SOX Dataproc node identity | GCP IAM |
| `loc-sa-dataproc-nodes-sox@prj-grp-janus-prod-0808.iam.gserviceaccount.com` | Service account for SOX-scoped Dataproc node identity | GCP IAM |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

The active environment is selected by the Airflow Variable `env`. Each environment has a dedicated Python config module:

| Environment | Config module | GCP Project | Key differences |
|-------------|--------------|-------------|----------------|
| `prod` | `config_prod.py` | `prj-grp-janus-prod-0808` | Production Kafka endpoints; production GCS buckets; full cluster sizes (n1-highmem-8 workers, 10+ workers per job) |
| `stable` | `config_stable.py` | Stable GCP project | Pre-production Kafka endpoints; smaller cluster sizes; stable GCS buckets |
| `sox` (prod) | `config_prod_sox.py` | `prj-grp-janus-prod-0808` | SOX service account; SOX-segregated GCS output paths (`grpn-dnd-prod-etl-grp-gdoop-sox-db/`) |
| `sox` (stable) | `config_stable_sox.py` | Stable GCP project | Stable SOX variant |

Key production configuration values (from `config_prod.py`):
- GCP project: `prj-grp-janus-prod-0808`
- PDE bucket: `gs://grpn-dnd-prod-pipelines-pde`
- Raw bucket: `gs://grpn-dnd-prod-pipelines-yati-raw`
- Canonicals bucket: `gs://grpn-dnd-prod-pipelines-yati-canonicals`
- CDP bucket: `gs://grpn-dnd-prod-pipelines-cdp-nonsox`
- Operational bucket: `gs://prod-us-janus-operational-bucket`
- Dataproc region: `us-central1` / zone `us-central1-f`
- NA Kafka (GCP): `kafka-grpn.us-central1.kafka.prod.gcp.groupondev.com:9094`
- EMEA Kafka (Strimzi): `kafka-grpn-k8s.grpn-dse-prod.eu-west-1.aws.groupondev.com:9094`
- Janus metadata service: `janus-web-cloud.production.service`
- Hybrid Boundary endpoint: `https://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com`
- BigQuery project: `prj-grp-datalake-prod-8a19`, dataset `janus`
- Juno Delta retention: 70 days; Jupiter retention: 62 days
- Deduplicator lookback: 0 days (runs on previous day's data)
