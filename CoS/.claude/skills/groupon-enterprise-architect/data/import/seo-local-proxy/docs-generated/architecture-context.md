---
service: "seo-local-proxy"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - continuumSeoLocalProxyNginx
    - continuumSeoLocalProxyCronJob
    - continuumSeoLocalProxyS3Bucket
---

# Architecture Context

## System Context

SEO Local Proxy is a component of the `continuumSystem` (Continuum Platform). It sits at the intersection of Groupon's web-crawl visibility layer and its core commerce infrastructure. External search engines access `/robots.txt` and `/sitemap.xml` via the public Groupon TLD, which is routed through the `routingService` into `continuumSeoLocalProxyNginx`. The Nginx container resolves the correct S3 path and proxies the file from `continuumSeoLocalProxyS3Bucket`. Separately, a Kubernetes CronJob (`continuumSeoLocalProxyCronJob`) runs daily, generates all sitemaps and robots.txt files using the `groupon-site-maps` Node.js scripts, and uploads results to the same S3 bucket. There are no direct user-facing browser interactions with this service.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| SEO Local Proxy Nginx | `continuumSeoLocalProxyNginx` | WebApp / Proxy | Nginx | alpine (0.0.03 image) | Serves robots.txt and sitemaps by proxying to the S3 hybrid boundary endpoint; determines country and brand from `X-Forwarded-Host` header |
| SEO Local Proxy Cron Job | `continuumSeoLocalProxyCronJob` | Batch | Kubernetes CronJob / Node.js | 12.6 | Runs the sitemap generator and uploads robots.txt and sitemaps to S3 on a daily schedule |
| SEO Local Proxy S3 Bucket | `continuumSeoLocalProxyS3Bucket` | Database | Amazon S3 | — | Stores all generated sitemap and robots.txt files; accessed via Hybrid Boundary endpoint |

## Components by Container

### SEO Local Proxy Nginx (`continuumSeoLocalProxyNginx`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Request Router (`requestRouter`) | Receives incoming `/robots.txt`, `/sitemap.xml`, and `/sitemaps/*.xml.gz` requests; resolves `$country`, `$website`, and `$environment` variables from the `X-Forwarded-Host` header; builds the correct S3 proxy path | Nginx `map` directives |
| S3 Proxy (`s3Proxy`) | Proxies the resolved file path to the `seo-local-proxy` Hybrid Boundary endpoint which points to the S3 bucket; strips cookies from upstream requests | Nginx `proxy_pass` |

### SEO Local Proxy Cron Job (`continuumSeoLocalProxyCronJob`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Sitemap Generator (`sitemapGenerator`) | Executes `groupon-site-maps` generation scripts (`daily_us.sh`, `daily_emea.sh`) to produce XML sitemaps and robots.txt per country and brand | Node.js / Makefile scripts |
| Sitemap Uploader (`sitemapUploader`) | Uploads generated sitemap and robots.txt artefacts to the designated S3 bucket via AWS CLI or GCP SDK; hands off from generator on completion | Node.js / AWS CLI / GCP SDK |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `routingService` | `continuumSeoLocalProxyNginx` | Routes requests for `/robots.txt` and `/sitemap.xml` paths | HTTP |
| `continuumSeoLocalProxyNginx` | `continuumSeoLocalProxyS3Bucket` | Fetches sitemap and robots files via Hybrid Boundary endpoint | HTTP (proxy_pass) |
| `continuumSeoLocalProxyCronJob` | `continuumSeoLocalProxyS3Bucket` | Uploads generated sitemap and robots files | AWS S3 API / GCP Storage API |
| `requestRouter` | `s3Proxy` | Proxies resolved sitemap and robots requests | Nginx internal |
| `sitemapGenerator` | `sitemapUploader` | Hands off generated artefacts for upload | process handoff |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component (Nginx): `components-seoLocalProxyNginxComponents`
- Component (CronJob): `components-seoLocalProxyCronJobComponents`
- Dynamic (generation flow): `dynamic-seoLocalProxyGenerationFlow`
- Dynamic (request flow): `dynamic-seoLocalProxyRequestFlow`
