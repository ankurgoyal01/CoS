---
service: "seo-local-proxy"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 2
---

# Integrations

## Overview

SEO Local Proxy has four external dependencies (AWS S3, GCP Cloud Storage, Apache Hadoop/Hive for data sourcing, and Google Cloud SDK) and two internal Groupon dependencies (`routing-service` as an upstream consumer and `seo-platform-itier` as a declared dependency). The service is primarily data-driven by S3 object storage and its own cron-triggered generation pipeline.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| AWS S3 | AWS SDK / AWS CLI | Stores and serves generated sitemaps and robots.txt | yes | `continuumSeoLocalProxyS3Bucket` |
| GCP Cloud Storage | GCP SDK / gsutil | Alternative bucket storage in GCP-hosted regions (us-central1, europe-west1) | yes | `continuumSeoLocalProxyS3Bucket` |
| Apache Hadoop 2.7.4 | HDFS/MapReduce | Data source used by `groupon-site-maps` to produce sitemap URL lists | yes | — |
| Apache Hive 1.2.2 | JDBC/HiveQL | Query layer over Hadoop for sitemap URL generation | yes | — |

### AWS S3 Detail

- **Protocol**: AWS CLI v2 (`aws s3 cp`, `aws s3 ls`)
- **Base URL / SDK**: AWS CLI v2 installed in `.ci/Dockerfile`; bucket accessed via `$SEO_LOCAL_PROXY_S3_BUCKET_NAME` env var
- **Auth**: IAM Role (`arn:aws:iam::497256801702:role/grpn-conveyor-seo-sitemap-s3-production-eu-west-1`); GCP environments use `con-sa-seo-local-proxy@prj-grp-central-sa-prod-0b25.iam.gserviceaccount.com`
- **Purpose**: Primary storage for all generated sitemap and robots.txt files; also served via Hybrid Boundary endpoint to Nginx
- **Failure mode**: If S3 is unavailable, Nginx returns 5xx to crawlers; cron job upload fails and existing files remain stale
- **Circuit breaker**: No

### GCP Cloud Storage Detail

- **Protocol**: Google Cloud SDK (installed in `.ci/Dockerfile`)
- **Base URL / SDK**: `GCP_BUCKET_NAME` env var; `GCP_BUCKET_PROJECT_NAME` env var
- **Auth**: GCP Service Account `con-sa-seo-local-proxy@prj-grp-central-sa-prod-0b25.iam.gserviceaccount.com`
- **Purpose**: Cloud-native bucket used in GCP-hosted deployments (us-central1, europe-west1) as the primary upload target for the cron job
- **Failure mode**: Cron job upload fails; existing stale files remain in bucket
- **Circuit breaker**: No

### Apache Hadoop 2.7.4 Detail

- **Protocol**: HDFS / Hadoop MapReduce
- **Base URL / SDK**: Installed at `/root/local_proxy/hadoop-2.7.4`; `HADOOP_HOME` env var points to this location
- **Auth**: Cluster credentials (not documented in this repo)
- **Purpose**: Provides large-scale URL datasets consumed by `groupon-site-maps` scripts during sitemap generation
- **Failure mode**: Sitemap generation script fails; upload does not occur
- **Circuit breaker**: No

### Apache Hive 1.2.2 Detail

- **Protocol**: HiveQL / JDBC
- **Base URL / SDK**: Installed at `/root/local_proxy/apache-hive-1.2.2-bin`; `HIVE_HOME` env var points to this location
- **Auth**: Cluster credentials (not documented in this repo)
- **Purpose**: SQL-like query layer used by `groupon-site-maps` to extract URL lists from Hadoop for sitemap source data
- **Failure mode**: Sitemap generation script fails; upload does not occur
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `seo-platform-itier` | internal | Declared dependency in `.service.yml`; provides SEO ITA layer integration (EMEA CityDeals redirect targets) | — |
| `groupon-site-maps` | process (git submodule / npm) | Node.js application that generates sitemaps and robots.txt; cloned into the cron job image at build time | — |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| `routing-service` | HTTP | Routes `/robots.txt`, `/sitemap.xml`, and `/sitemaps/*` requests to `continuumSeoLocalProxyNginx` |
| Search engine crawlers (Googlebot, Bingbot, etc.) | HTTP | Consume robots.txt and sitemap files for indexing |

> Upstream consumers are tracked in the central architecture model (`routingService -> continuumSeoLocalProxyNginx` in `models/relations.dsl`).

## Dependency Health

- **AWS S3 / GCP Storage**: No automated health check from the service itself. Operators verify bucket contents with `aws s3 ls s3://$SEO_LOCAL_PROXY_S3_BUCKET_NAME/` from inside the pod.
- **Nginx to S3 (Hybrid Boundary)**: Nginx health is verified via `/grpn/healthcheck` (returns 200). If the Hybrid Boundary is down, Nginx returns 5xx.
- **Cron job to Hadoop/Hive**: No circuit breaker; failures surface as cron job exit codes logged to `/tmp/sitemap_cron.log`.
