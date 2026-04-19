---
service: "seo-local-proxy"
title: "EMEA Sitemap Generation Flow"
generated: "2026-03-03"
type: flow
flow_name: "emea-sitemap-generation"
flow_type: scheduled
trigger: "Daily Kubernetes CronJob at 11:59–13:59 UTC (EMEA region)"
participants:
  - "continuumSeoLocalProxyCronJob"
  - "continuumSeoLocalProxyS3Bucket"
architecture_ref: "dynamic-seoLocalProxyGenerationFlow"
---

# EMEA Sitemap Generation Flow

## Summary

A dedicated Kubernetes CronJob runs daily in the EMEA regions (GCP europe-west1 and AWS eu-west-1) to generate sitemaps and robots.txt for all EMEA countries (DE, GB, IE, ES, FR, IT, NL, BE, AE, PL, AU, NZ, HK, SG, MY, JP, CO, CL, MX, PE) plus Canada. The EMEA flow uses `daily_emea.sh` instead of `daily_us.sh`, targeting EMEA-specific data sources and configuration files. Generated artefacts are uploaded to EMEA-specific cloud storage buckets.

## Trigger

- **Type**: schedule
- **Source**: Kubernetes CronJob (`seo-local-proxy--cron-job--default`) schedules:
  - GCP europe-west1: `59 11 * * *`
  - AWS eu-west-1: `59 13 * * *`
- **Frequency**: Daily

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SEO Local Proxy Cron Job (EMEA) | Runs EMEA generation and upload scripts | `continuumSeoLocalProxyCronJob` |
| Sitemap Generator | Executes `daily_emea.sh` with EMEA country configuration | `sitemapGenerator` (component of `continuumSeoLocalProxyCronJob`) |
| Sitemap Uploader | Uploads generated files to EMEA S3/GCP bucket | `sitemapUploader` (component of `continuumSeoLocalProxyCronJob`) |
| SEO Local Proxy S3 Bucket (EMEA) | Receives EMEA sitemaps and robots.txt | `continuumSeoLocalProxyS3Bucket` |

## Steps

1. **Kubernetes triggers EMEA CronJob pod**: The Kubernetes scheduler creates a new pod according to the EMEA cron schedule.
   - From: Kubernetes scheduler
   - To: `continuumSeoLocalProxyCronJob`
   - Protocol: Kubernetes CronJob

2. **Executes EMEA generation script**: The pod runs:
   ```
   cd ~/local_proxy/groupon-site-maps/current && ./scripts/daily_emea.sh
   ```
   The EMEA script reads country-specific configuration from `config/emea_sources.coffee` and `emea_config.coffee`, applying country-specific `excludes` for custom sitemaps not applicable to certain EMEA countries.
   - From: `sitemapGenerator`
   - To: Hadoop/Hive (external data source)
   - Protocol: HiveQL / HDFS

3. **Applies country-specific sitemap exclusions**: For countries that do not support certain sitemap channels (e.g., `browsePages` enabled only for GB and FR), the generator applies per-country exclusion lists from `emea_config.coffee`.
   - From: `sitemapGenerator`
   - To: local configuration (file system)
   - Protocol: process-internal

4. **Generates EMEA artefacts**: Produces per-country XML sitemap files and robots.txt for all supported EMEA countries. Configuration file naming:
   - robots.txt template: `robots.production.{country}.{brand}.txt` in `groupon-site-maps/config/`
   - Custom sitemap CSVs in `groupon-site-maps/data/{country}/`
   - From: `sitemapGenerator`
   - To: `sitemapUploader`
   - Protocol: process handoff (file system)

5. **Uploads to EMEA storage bucket**: The `sitemapUploader` copies generated files to:
   - GCP europe-west1: `con-prod-euw1-seo-local-proxy-emea`
   - AWS eu-west-1: `497256801702-grpn-cc-euw1-grpn-xml-sitemap-dbbbdd50` (legacy bucket, role: `arn:aws:iam::497256801702:role/grpn-conveyor-seo-sitemap-s3-production-eu-west-1`)
   - From: `sitemapUploader`
   - To: `continuumSeoLocalProxyS3Bucket`
   - Protocol: AWS S3 API or GCP Storage API

6. **Pod exits**: Pod exits 0 on success; all output logged to `/tmp/sitemap_cron.log`.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Hive/Hadoop query failure for EMEA country | Script exits non-zero | No EMEA upload; stale files remain |
| robots.txt template missing for country | Script fails with file not found | That country's robots.txt not updated |
| Custom CSV sitemap missing | Sitemap channel skipped | Affected sitemap channel not generated |
| EMEA bucket IAM role failure | Upload fails with auth error | No upload; check IAM role ARN in deployment config |

## Sequence Diagram

```
KubernetesScheduler -> CronJobPod: Create pod (EMEA schedule)
CronJobPod -> SitemapGenerator: Execute daily_emea.sh
SitemapGenerator -> Hadoop/Hive: Query EMEA country URL datasets
Hadoop/Hive --> SitemapGenerator: URL lists per EMEA country and channel
SitemapGenerator -> SitemapUploader: Hand off EMEA .xml.gz and robots.txt files
SitemapUploader -> S3Bucket(EMEA): Upload all EMEA artefacts
S3Bucket(EMEA) --> SitemapUploader: Upload acknowledgement
SitemapUploader --> CronJobPod: Exit 0
```

## Related

- Architecture dynamic view: `dynamic-seoLocalProxyGenerationFlow`
- Related flows: [Sitemap Generation Flow (US/Canada)](sitemap-generation.md), [Sitemap Request Serving Flow](sitemap-request-serving.md), [Robots.txt Serving Flow](robots-txt-serving.md)
