---
service: "image-service-config"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers:
    - "continuumImageServiceConfigBundle"
    - "continuumImageServiceNginxCacheProxy"
    - "continuumImageServiceAppRuntime"
    - "continuumImageServiceProxyCacheStore"
---

# Architecture Context

## System Context

The Image Service sits within Groupon's Continuum platform as the central media-delivery pipeline. External clients (browsers, mobile apps, partner APIs) request resized images via the CDN hostname `img.grouponcdn.com`. The Nginx cache proxy intercepts these requests, serves cache hits from disk, and on misses forwards requests to the Python app backend, which transforms images fetched from AWS S3. This repo (`image-service-config`) owns the configuration and deployment lifecycle of all three physical tiers: the Nginx cache layer, the Python app runtime, and the S3-proxy route.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Image Service Config Bundle | `continuumImageServiceConfigBundle` | Configuration | Ruby/Capistrano, YAML, Nginx config | N/A | Capistrano-managed configuration bundle containing nginx, upstream, and supervisord configs for image-service environments |
| Image Service Nginx Cache Proxy | `continuumImageServiceNginxCacheProxy` | Edge / Cache / Proxy | Nginx | N/A | Nginx layer serving CDN hostnames, caching image responses, and proxying to backend app and S3 proxy endpoints |
| Image Service App Runtime | `continuumImageServiceAppRuntime` | Application | Python, Supervisord | N/A | Python image-service processes managed by supervisord; serves image transformation and retrieval requests |
| Nginx Proxy Cache Store | `continuumImageServiceProxyCacheStore` | Datastore / Cache | Filesystem Cache | N/A | Filesystem-backed cache at `/var/nginx_proxy_cache` used by nginx proxy_cache |

## Components by Container

### Image Service Config Bundle (`continuumImageServiceConfigBundle`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Capistrano Deploy Pipeline (`capistranoDeployPipeline`) | Runs Capistrano tasks that template and distribute configuration to cache/app nodes | Ruby/Capistrano |
| Nginx Template Set (`nginxTemplateSet`) | Templated `nginx.conf` / upstream / s3-proxy definitions used by cache nodes | Nginx config / ERB |
| App Runtime Config Set (`appRuntimeConfigSet`) | `supervisord.conf` and `config.yml` payloads uploaded to app nodes | YAML/INI |

### Image Service Nginx Cache Proxy (`continuumImageServiceNginxCacheProxy`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Virtual Host Router (`nginxVirtualHostRouter`) | Nginx server blocks handling CDN and S3 hostnames with path-based routing | Nginx |
| Backend Proxy (`nginxBackendProxy`) | Forwards image requests to image-service backend upstream | Nginx upstream/proxy_pass |
| S3 Proxy Route (`nginxS3ProxyRoute`) | Proxies bucket-host requests through s3proxy upstream endpoints | Nginx upstream/proxy_pass |
| Proxy Cache Engine (`nginxProxyCacheEngine`) | Applies `proxy_cache` policy and keying (`$host$uri`) for image responses | Nginx proxy_cache |

### Image Service App Runtime (`continuumImageServiceAppRuntime`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Image Request Handler (`imageRequestHandler`) | Serves HTTP requests for image retrieval and transformation | Python |
| Image Resize Engine (`imageResizeEngine`) | Performs image resize and transformation operations for allowed dimensions | Python imaging libraries |
| Config Loader (`imageServiceConfigLoader`) | Loads API keys and allowed-size policies from `config.yml` | YAML |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumImageServiceConfigBundle` | `continuumImageServiceNginxCacheProxy` | Deploys nginx/upstream/s3-proxy configuration files | Capistrano SCP |
| `continuumImageServiceConfigBundle` | `continuumImageServiceAppRuntime` | Deploys supervisord and app config files | Capistrano SCP |
| `continuumImageServiceNginxCacheProxy` | `continuumImageServiceAppRuntime` | Proxies image requests to backend app upstream | HTTP |
| `continuumImageServiceNginxCacheProxy` | `continuumImageServiceProxyCacheStore` | Stores and retrieves cached responses | Filesystem I/O |
| `continuumImageServiceNginxCacheProxy` | AWS S3 (`image-service` bucket) | Proxies S3-host traffic to bucket origin | HTTP |
| `continuumImageServiceAppRuntime` | AWS S3 (`image-service` bucket) | Reads original image assets | S3 API |
| `capistranoDeployPipeline` | `nginxTemplateSet` | Renders and ships nginx templates | Capistrano |
| `capistranoDeployPipeline` | `appRuntimeConfigSet` | Uploads supervisord.conf and config.yml | Capistrano |
| `nginxBackendProxy` | `imageRequestHandler` | Forwards image requests to backend app ports | HTTP |
| `imageRequestHandler` | `imageResizeEngine` | Invokes image transformation pipeline | In-process call |
| `imageRequestHandler` | `imageServiceConfigLoader` | Validates client API key and size policy | In-process call |

## Architecture Diagram References

- Container: `containers-imageServiceConfig`
- Component (Config Bundle): `components-imageServiceConfigBundle`
- Component (Nginx Cache Proxy): `components-imageServiceNginxCacheProxy`
- Component (App Runtime): `components-imageServiceAppRuntime`

> No dynamic views are currently modeled for this repository (`// No dynamic views modeled for this repository yet.`).
