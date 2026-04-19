---
service: "seo-deal-redirect"
title: Overview
generated: "2026-03-03"
type: overview
domain: "SEO / Computational SEO"
platform: "GCP (Cloud Composer + Dataproc)"
team: "SEO"
status: active
tech_stack:
  language: "Python"
  language_version: "3"
  framework: "Apache Airflow"
  framework_version: "GCP Composer (managed)"
  runtime: "GCP Dataproc"
  runtime_version: "1.5.63-debian10"
  build_tool: "Jenkins"
  package_manager: "pip"
---

# SEO Deal Redirect Overview

## Purpose

SEO Deal Redirect is a scheduled data pipeline that automatically maps expired Groupon deal URLs to active deals from the same merchant. It runs daily at 5:00 AM UTC on GCP Cloud Composer (Airflow), executing a series of Hive ETL steps and PySpark jobs to compute redirect mappings, then publishes those mappings to the SEO Deal API so deal pages and search engines receive 301-style redirects. The service prevents 404 errors on expired deal pages, preserving Groupon's search engine rankings and directing users to purchasable content.

## Scope

### In scope

- Daily computation of expired-to-live deal redirect mappings via Hive ETL
- Algorithmic matching of expired deals to active deals from the same merchant, location, and category
- Support for manually defined redirect overrides via `data/prod/manual_redirects.csv`
- Deal exclusion handling via `data/prod/exclusion_list.csv` and PDS ID blacklist
- Deduplication and redirect cycle detection and removal
- Publication of redirect mappings to the SEO Deal API via authenticated HTTPS PUT requests
- Non-active merchant deal identification and redirect generation (separate PySpark job)
- Coverage for 15 country domains (US, CA, UK, FR, DE, IT, ES, PL, NL, BE, IE, AE, AU, NZ, JP)
- International deal redirect handling

### Out of scope

- Serving the actual HTTP 301 redirects to end users (handled by deal pages and the Deal Catalog service)
- Storing deal content or SEO metadata beyond redirect URLs
- Real-time redirect lookups
- Crawling or indexing of search engines

## Domain Context

- **Business domain**: SEO / Computational SEO
- **Platform**: GCP Cloud Composer (Airflow) + Dataproc (Spark/Hive)
- **Upstream consumers**: SEO Deal API service; Deal Catalog service (receives redirect attribute updates); deal page rendering services
- **Downstream dependencies**: `seo-deal-api` (primary target), Hive metastore (`grp_gdoop_seo_db`, `svc_goods_bundling_db`, `grp_gdoop_gods_db`, `edwprod`), GCP Cloud Storage, LPAPI (location data enrichment)

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | bleitemarquespereira (SEO team) |
| Engineering Team | jahill, joeliu, rlynch, sutekar |
| On-Call / SRE | #computational-seo Slack channel |
| Consumers | SEO / Product teams relying on redirect accuracy |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 3 | `api_upload/api_upload.py`, `non_active_merchant_deals/python/` |
| Orchestration | Apache Airflow (GCP Composer) | Managed | `orchestrator/redirect_workflow.py`, `WORKFLOW.md` |
| Batch processing | Apache Spark (PySpark) | YARN mode | `api_upload/api_upload.py`, `api_upload_table_population/python/` |
| Query engine | Apache Hive | HiveQL | `exclusion/hql/`, `manual_redirects/hql/`, `source_table_population/hql/` |
| Infrastructure | GCP Dataproc | 1.5.63-debian10 | `orchestrator/config/prod/dag_properties.json` |
| CI/CD | Jenkins | — | `Jenkinsfile` |
| Deployment | DeployBot (GCS) | v3.0.0 | `.deploy_bot.yml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `pyspark` | (Dataproc bundled) | batch | Distributed Spark processing and Hive integration |
| `requests` | 2.28.2 | http-client | HTTP PUT calls to SEO Deal API |
| `ratelimit` | 2.2.1 | scheduling | Rate-limits API upload to 1,250 calls/60 s |
| `pyOpenSSL` | 23.0.0 | auth | Loads JKS keystore and generates PEM files for mTLS |
| `pyjks` | 20.0.0 | auth | Reads PKCS12/JKS keystores for client certificate auth |
| `google-cloud-secret-manager` | 1.0.1 | auth | Retrieves TLS secrets from GCP Secret Manager |
| `pandas` | (test dependency) | testing | Local test data manipulation |
| `pyarrow` | (test dependency) | serialization | Parquet read/write in tests |
| `croniter` | 1.4.1 | scheduling | Schedule-based execution gating for NA/INTL jobs |
| `pendulum` | 2.1.2 | scheduling | Date/time utilities for Airflow DAGs |
| `pytest` | (test) | testing | PySpark and enrichment pipeline unit/integration tests |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
