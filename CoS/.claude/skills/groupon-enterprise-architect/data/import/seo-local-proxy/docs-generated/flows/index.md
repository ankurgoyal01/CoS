---
service: "seo-local-proxy"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for SEO Local Proxy.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Sitemap Generation Flow](sitemap-generation.md) | scheduled | Daily cron job at 11:59 UTC | Generates XML sitemaps for all US/Canada countries and uploads to S3 |
| [EMEA Sitemap Generation Flow](emea-sitemap-generation.md) | scheduled | Daily cron job at 11:59–13:59 UTC | Generates XML sitemaps and robots.txt for all EMEA countries and uploads to S3 |
| [Sitemap Request Serving Flow](sitemap-request-serving.md) | synchronous | HTTP GET from routing-service | Nginx resolves country/brand from X-Forwarded-Host and proxies the correct file from S3 |
| [Robots.txt Request Serving Flow](robots-txt-serving.md) | synchronous | HTTP GET from routing-service | Nginx resolves country/brand from X-Forwarded-Host and proxies robots.txt from S3 |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- The **sitemap and robots.txt serving flows** cross service boundaries: `routingService` routes the request to `continuumSeoLocalProxyNginx`, which in turn fetches from `continuumSeoLocalProxyS3Bucket`. See architecture dynamic view `dynamic-seoLocalProxyRequestFlow`.
- The **sitemap generation flow** is internal to the `continuumSeoLocalProxyCronJob` container but writes to the shared `continuumSeoLocalProxyS3Bucket`. See architecture dynamic view `dynamic-seoLocalProxyGenerationFlow`.
