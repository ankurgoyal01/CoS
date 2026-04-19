---
service: "image-service-config"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for image-service-config.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Image Request Cache Hit](image-request-cache-hit.md) | synchronous | HTTP GET from client to CDN hostname | Client requests an image that is already in the Nginx proxy cache; served from disk without contacting backend |
| [Image Request Cache Miss](image-request-cache-miss.md) | synchronous | HTTP GET from client to CDN hostname | Client requests an image not in cache; Nginx forwards to Python app backend which fetches and transforms from S3 |
| [S3 Proxy Request](s3-proxy-request.md) | synchronous | HTTP GET from client using S3-proxy server name | Client or internal service sends image request via the S3-proxy hostname; Nginx tunnels to S3 origin with Host header override |
| [Configuration Deployment](configuration-deployment.md) | batch | Manual Capistrano task execution | Operator runs Capistrano tasks to distribute nginx and app configuration to all cache and app nodes |
| [Rolling App Node Restart](rolling-app-node-restart.md) | batch | Manual operator action | Safe rolling restart of Python app nodes with upstream drain/restore to avoid dropping in-flight requests |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

The image request flows span the `continuumImageServiceNginxCacheProxy`, `continuumImageServiceAppRuntime`, and `continuumImageServiceProxyCacheStore` containers, as well as the external AWS S3 dependency. No dynamic views are currently modeled in the architecture DSL for this service. See [Architecture Context](../architecture-context.md) for container and component relationship details.
