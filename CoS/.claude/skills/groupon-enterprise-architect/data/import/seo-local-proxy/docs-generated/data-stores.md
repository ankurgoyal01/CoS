---
service: "seo-local-proxy"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumSeoLocalProxyS3Bucket"
    type: "s3"
    purpose: "Stores generated sitemaps and robots.txt files"
---

# Data Stores

## Overview

SEO Local Proxy uses AWS S3 as its sole persistent store. All generated sitemap XML files (compressed as `.xml.gz`) and robots.txt files are written to regional S3 buckets by the cron job and read back by the Nginx proxy at request time. There is no relational database, cache, or message store. GCP Cloud Storage buckets serve as the equivalent store in GCP-hosted regions.

## Stores

### SEO Local Proxy S3 Bucket (`continuumSeoLocalProxyS3Bucket`)

| Property | Value |
|----------|-------|
| Type | Amazon S3 |
| Architecture ref | `continuumSeoLocalProxyS3Bucket` |
| Purpose | Stores all generated XML sitemaps and robots.txt files per country and brand |
| Ownership | owned |
| Migrations path | Not applicable (object storage, no schema migrations) |

#### Key Entities

| Entity / Object | Purpose | Key Fields / Path Pattern |
|----------------|---------|--------------------------|
| `robots.txt` | Crawl directives for search engine bots per country/brand | `/robots/{country}/{brand}/robots.txt` |
| `sitemap.xml` | Sitemap index file listing all channel sitemaps | `/{country}/{brand}/sitemap.xml` |
| `{channel}N.xml.gz` | Individual compressed sitemap channel file | `/{country}/{brand}/sitemap/{channel}{N}.xml.gz` |

#### Access Patterns

- **Read**: Nginx proxies individual file requests from S3 via the Hybrid Boundary endpoint at request time (one file per HTTP request). No batching or listing.
- **Write**: CronJob uploads all generated files once daily via AWS CLI (`aws s3 cp` / upload scripts). Overwrites existing files in place.
- **Indexes**: Not applicable (object storage).

#### Production Bucket Names

| Region | Bucket Name |
|--------|------------|
| US (AWS eu-west-1 legacy) | `497256801702-grpn-cc-euw1-grpn-xml-sitemap-dbbbdd50` |
| US (GCP us-central1) | `con-prod-usc1-seo-local-proxy` (project: `con-grp-seo-proxy-prod-c1b3`) |
| EMEA (GCP europe-west1) | `con-prod-euw1-seo-local-proxy-emea` (project: `con-grp-seo-proxy-prod-c1b3`) |

### GCP Cloud Storage Buckets

| Environment | Bucket | Project |
|-------------|--------|---------|
| Staging US (us-central1) | `con-stable-usc1-seo-local-proxy` | `con-grp-seo-proxy-stable-b3f4` |
| Production US (us-central1) | `con-prod-usc1-seo-local-proxy` | `con-grp-seo-proxy-prod-c1b3` |
| Production EMEA (europe-west1) | `con-prod-euw1-seo-local-proxy-emea` | `con-grp-seo-proxy-prod-c1b3` |

## Caches

> No evidence found in codebase. No Redis, Memcached, or in-memory caching layer is used. Nginx does not cache S3 responses locally.

## Data Flows

The cron job generates all sitemap and robots.txt files and pushes them to S3 once daily. Nginx reads files on demand from S3 via the Hybrid Boundary endpoint at HTTP request time. There is no CDC, ETL pipeline, or replication between stores. Data in S3 is replaced in-place on each cron job run; there is no versioning or archival strategy documented in the codebase.
