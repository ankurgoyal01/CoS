---
service: "seo-local-proxy"
title: "Sitemap Generation Flow (US/Canada)"
generated: "2026-03-03"
type: flow
flow_name: "sitemap-generation"
flow_type: scheduled
trigger: "Daily Kubernetes CronJob at 11:59 UTC"
participants:
  - "continuumSeoLocalProxyCronJob"
  - "continuumSeoLocalProxyS3Bucket"
architecture_ref: "dynamic-seoLocalProxyGenerationFlow"
---

# Sitemap Generation Flow (US/Canada)

## Summary

The Kubernetes CronJob `continuumSeoLocalProxyCronJob` runs once daily at 11:59 UTC in the US production environment. It executes the `groupon-site-maps` Node.js scripts to generate XML sitemap files and robots.txt for US and Canada, then uploads all generated artefacts to the designated S3 or GCP Cloud Storage bucket. This ensures search engine crawlers always receive up-to-date sitemaps within one day of content changes.

## Trigger

- **Type**: schedule
- **Source**: Kubernetes CronJob (`seo-local-proxy--cron-job--default`) schedule: `59 11 * * *`
- **Frequency**: Daily at 11:59 UTC

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SEO Local Proxy Cron Job | Runs generation and upload scripts | `continuumSeoLocalProxyCronJob` |
| Sitemap Generator | Executes `groupon-site-maps` Node.js generation scripts | `sitemapGenerator` (component of `continuumSeoLocalProxyCronJob`) |
| Sitemap Uploader | Uploads generated files to cloud storage | `sitemapUploader` (component of `continuumSeoLocalProxyCronJob`) |
| SEO Local Proxy S3 Bucket | Receives and stores generated artefacts | `continuumSeoLocalProxyS3Bucket` |

## Steps

1. **Kubernetes triggers CronJob pod**: The Kubernetes scheduler creates a new pod for `seo-local-proxy--cron-job--default` according to the `59 11 * * *` schedule.
   - From: Kubernetes scheduler
   - To: `continuumSeoLocalProxyCronJob`
   - Protocol: Kubernetes CronJob

2. **Executes generation script**: The pod runs `mainContainerCommand`:
   ```
   cd ~/local_proxy/groupon-site-maps/current && ./scripts/daily_us.sh
   ```
   The `sitemapGenerator` component runs `groupon-site-maps` scripts, which query Apache Hive/Hadoop data sources and generate per-channel XML sitemaps (`.xml.gz`) and robots.txt files for US and Canada. Output is written to `/var/groupon/local_proxy/`.
   - From: `sitemapGenerator`
   - To: Hadoop/Hive (external data source)
   - Protocol: HiveQL / HDFS

3. **Generates sitemap artefacts**: The generator produces the following file types per supported brand (`https`, `livingsocial`, `speedgroupon`) and country (`US`, `CA`):
   - `/{country}/{brand}/sitemap.xml` — sitemap index
   - `/{country}/{brand}/sitemap/{channel}N.xml.gz` — per-channel compressed files
   - `/robots/{country}/{brand}/robots.txt` — crawl directives
   - From: `sitemapGenerator`
   - To: `sitemapUploader`
   - Protocol: process handoff (file system)

4. **Uploads artefacts to cloud storage**: The `sitemapUploader` component runs upload scripts (`upload.sh`) which use AWS CLI or GCP SDK to copy generated files to the configured bucket:
   - GCP us-central1: `con-prod-usc1-seo-local-proxy`
   - From: `sitemapUploader`
   - To: `continuumSeoLocalProxyS3Bucket`
   - Protocol: AWS S3 API or GCP Storage API

5. **Pod exits and logs output**: On successful completion, the pod exits with code 0. All output is logged to `/tmp/sitemap_cron.log`. The `trap "touch /tmp/signals/terminated" EXIT` signal handler ensures Kubernetes can detect completion.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Hive/Hadoop query failure | Script exits with non-zero code | Pod exits with error; no upload occurs; stale files remain in S3 |
| Upload failure (AWS/GCP) | Script exits with non-zero code | Partial upload possible; stale files may remain |
| CronJob pod OOMKilled | Kubernetes terminates pod | No upload; cron job not automatically retried until next schedule; manual one-off job required |
| Kubernetes scheduling failure | Pod not created | No generation; stale files remain |

## Sequence Diagram

```
KubernetesScheduler -> CronJobPod: Create pod (schedule: 59 11 * * *)
CronJobPod -> SitemapGenerator: Execute daily_us.sh
SitemapGenerator -> Hadoop/Hive: Query sitemap URL datasets
Hadoop/Hive --> SitemapGenerator: URL lists per channel
SitemapGenerator -> SitemapUploader: Hand off generated .xml.gz and robots.txt files
SitemapUploader -> S3Bucket: Upload all artefacts (AWS CLI / GCP SDK)
S3Bucket --> SitemapUploader: Upload acknowledgement
SitemapUploader --> CronJobPod: Exit 0
```

## Related

- Architecture dynamic view: `dynamic-seoLocalProxyGenerationFlow`
- Related flows: [EMEA Sitemap Generation Flow](emea-sitemap-generation.md), [Sitemap Request Serving Flow](sitemap-request-serving.md)
