---
service: "seo-local-proxy"
title: "Sitemap Request Serving Flow"
generated: "2026-03-03"
type: flow
flow_name: "sitemap-request-serving"
flow_type: synchronous
trigger: "HTTP GET /sitemap.xml or /sitemaps/*.xml.gz from routing-service"
participants:
  - "routingService"
  - "continuumSeoLocalProxyNginx"
  - "continuumSeoLocalProxyS3Bucket"
architecture_ref: "dynamic-seoLocalProxyRequestFlow"
---

# Sitemap Request Serving Flow

## Summary

When a search engine crawler or any HTTP client requests a sitemap URL from a Groupon TLD, the `routing-service` forwards the request to `continuumSeoLocalProxyNginx`. Nginx inspects the `X-Forwarded-Host` header to determine the requesting country and brand, constructs the correct S3 path, and proxies the file from `continuumSeoLocalProxyS3Bucket` via the Hybrid Boundary endpoint. The crawler receives the XML sitemap file without any application logic layer.

## Trigger

- **Type**: api-call
- **Source**: `routing-service` forwarding requests matching `/sitemap.xml` or `/sitemaps/*.xml.gz` from `https://www.groupon.{tld}/`
- **Frequency**: per-request (on demand by search engine crawlers and any HTTP client)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| routing-service | Routes sitemap requests to the Nginx proxy | `routingService` |
| SEO Local Proxy Nginx | Resolves country/brand; constructs S3 proxy path | `continuumSeoLocalProxyNginx` |
| Request Router | Nginx map directives that derive `$country`, `$website`, `$environment` | `requestRouter` |
| S3 Proxy | Nginx `proxy_pass` to Hybrid Boundary endpoint | `s3Proxy` |
| SEO Local Proxy S3 Bucket | Serves the sitemap file | `continuumSeoLocalProxyS3Bucket` |

## Steps

1. **Search engine requests sitemap**: A crawler sends a GET request to `https://www.groupon.de/sitemap.xml`.
   - From: Search engine crawler
   - To: Groupon TLD edge / `routing-service`
   - Protocol: HTTPS

2. **routing-service forwards to Nginx**: `routing-service` routes the request to `seo-local-proxy--nginx`, setting the `X-Forwarded-Host: www.groupon.de` header.
   - From: `routingService`
   - To: `continuumSeoLocalProxyNginx`
   - Protocol: HTTP

3. **Nginx resolves country and brand**: The `requestRouter` component applies two Nginx `map` directives:
   - `map $http_x_forwarded_host $country` — resolves `DE` from `www.groupon.de`
   - `map $http_x_forwarded_host $website` — resolves `https` (default for groupon.* domains)
   - `map $host $environment` — resolves `production`
   - From: `requestRouter`
   - To: internal Nginx variable resolution
   - Protocol: Nginx map

4. **Nginx matches location block and proxies**: For `/sitemap.xml`, Nginx matches the location block:
   ```
   location /sitemap.xml {
     proxy_pass http://seo-local-proxy.$environment.service/$country/$website/sitemap.xml;
   }
   ```
   The resolved proxy URL becomes: `http://seo-local-proxy.production.service/DE/https/sitemap.xml`
   - From: `s3Proxy`
   - To: `continuumSeoLocalProxyS3Bucket` (via Hybrid Boundary endpoint)
   - Protocol: HTTP (proxy_pass)

5. **For individual sitemap files** (`/sitemaps/*.xml.gz`): Nginx matches:
   ```
   location ~ ^/sitemaps/(.*\.xml.gz) {
     proxy_pass http://seo-local-proxy.$environment.service/$country/$website$uri;
   }
   ```
   Adds `Content-Encoding: gzip`, `Content-Type: application/xml`, `Accept-Ranges: bytes` headers.
   - From: `s3Proxy`
   - To: `continuumSeoLocalProxyS3Bucket`
   - Protocol: HTTP (proxy_pass)

6. **S3 returns file**: The Hybrid Boundary endpoint serves the file from the S3 bucket. Nginx returns the response to the crawler. Cookies are stripped (`proxy_set_header Cookie ""`).
   - From: `continuumSeoLocalProxyS3Bucket`
   - To: `continuumSeoLocalProxyNginx`
   - Protocol: HTTP

7. **Nginx returns response to caller**: The file is streamed back through `routing-service` to the crawler.
   - From: `continuumSeoLocalProxyNginx`
   - To: Search engine crawler
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| File not found in S3 | S3 returns 404; Nginx forwards 404 to caller | Crawler receives 404; may de-index sitemap |
| Hybrid Boundary / S3 unreachable | Nginx returns 502/504 | Crawler receives 5xx; retries on next crawl cycle |
| Unrecognised `X-Forwarded-Host` | Nginx defaults: `$country=US`, `$website=https` | US Groupon sitemap served (may serve wrong content) |
| Missing `X-Forwarded-Host` header | Nginx defaults apply | Same as above |

## Sequence Diagram

```
SearchEngineCrawler -> RoutingService: GET https://www.groupon.de/sitemap.xml
RoutingService -> NginxProxy: GET /sitemap.xml (X-Forwarded-Host: www.groupon.de)
NginxProxy -> RequestRouter: Resolve $country=DE, $website=https, $environment=production
RequestRouter -> S3Proxy: Build proxy URL: /DE/https/sitemap.xml
S3Proxy -> S3Bucket: GET http://seo-local-proxy.production.service/DE/https/sitemap.xml
S3Bucket --> S3Proxy: 200 OK (XML content)
S3Proxy --> NginxProxy: 200 OK (strip cookies)
NginxProxy --> RoutingService: 200 OK
RoutingService --> SearchEngineCrawler: 200 OK (sitemap.xml)
```

## Related

- Architecture dynamic view: `dynamic-seoLocalProxyRequestFlow`
- Related flows: [Robots.txt Serving Flow](robots-txt-serving.md), [Sitemap Generation Flow](sitemap-generation.md)
