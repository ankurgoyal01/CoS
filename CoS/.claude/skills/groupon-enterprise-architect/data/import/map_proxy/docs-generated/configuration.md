---
service: "map_proxy"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, properties-file]
---

# Configuration

## Overview

MapProxy is configured through two mechanisms:

1. **`MapProxy.properties`** — A Java properties file loaded at startup via Groupon's `app-config` library (`com.groupon.common.app_config.AppConfig`). This file contains all application-level settings including provider URLs, API keys, server tuning, and log paths. In Kubernetes cloud deployments the file path is provided via the `CONFIG_FILE` environment variable. In legacy on-prem deployments a symlink to `/usr/local/mapproxy_service/MapProxy.properties` is used.
2. **Environment variables** — JVM heap sizing (`MIN_HEAP_SIZE`, `MAX_HEAP_SIZE`) and the config file path (`CONFIG_FILE`) are set as container environment variables.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `MIN_HEAP_SIZE` | JVM minimum heap size (`-Xms`) | No | `512m` (cloud), `1G` (Dockerfile default) | `Dockerfile` / `.meta/deployment/cloud/components/app/common.yml` |
| `MAX_HEAP_SIZE` | JVM maximum heap size (`-Xmx`) | No | `1G` | `Dockerfile` / `common.yml` |
| `CONFIG_FILE` | Path to the `MapProxy.properties` (or YAML-equivalent) config file | Yes (cloud) | — | `.meta/deployment/cloud/components/app/production-*.yml` |
| `MALLOC_ARENA_MAX` | Limits glibc memory arena count to prevent virtual memory explosion | No | `4` | `common.yml` |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found in codebase. No feature flag system (e.g. LaunchDarkly, Togglz) is used.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/MapProxy.properties` | Java properties | Primary application configuration (server port, log paths, provider URLs, API keys, Yandex country list) |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Kubernetes deployment defaults: replica counts, probes, log config, heap sizes, ports |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production US (GCP us-central1) overrides: replicas 2–15, VIP, resource requests |
| `.meta/deployment/cloud/components/app/production-eu-west-1.yml` | YAML | Production EU (AWS eu-west-1) overrides: replicas 2–15, VIP, EU Kafka endpoint |
| `.meta/deployment/cloud/components/app/production-europe-west1.yml` | YAML | Production EU (GCP europe-west1) overrides |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging US (GCP us-central1) overrides: replicas 2–5, stable VIP |
| `.meta/deployment/cloud/components/app/staging-europe-west1.yml` | YAML | Staging EU (GCP europe-west1) overrides |
| `doc/openapi.yml` | OpenAPI 3.0.1 | API contract specification |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `MapProxy.google.signingKey` | HMAC-SHA1 private key for signing Google Maps for Business URL requests | App config / Kubernetes secret (path managed by Raptor; `secret_path` in `.meta/.raptor.yml`) |
| `MapProxy.google.clientID` | Google Maps for Business client ID (e.g. `gme-grouponinc1`), appended to all Google outbound URLs | App config / Kubernetes secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Key `MapProxy.properties` Settings (names inferred from codebase)

| Property Key | Purpose | Referenced In |
|---|---|---|
| `MapProxy.serverPort` | Jetty HTTP listen port (typically 8080) | `MapsServletContext.java` |
| `MapProxy.requestBufferSize` | Jetty connector request buffer size | `MapsServletContext.java` |
| `MapProxy.requestHeaderSize` | Jetty connector request header size | `MapsServletContext.java` |
| `MapProxy.logPath` | Directory path for NCSA request log output | `MapsServletContext.java` |
| `MapProxy.logFormatFile` | Log file name appended to `logPath` | `MapsServletContext.java` |
| `MapProxy.heartbeatFile` | Filesystem path of the heartbeat marker file | `StatusServlet.java` |
| `MapProxy.staticFilesBaseUrl` | Base URL for serving static JS library files to browser clients | `MapProvider.java` |
| `MapProxy.google.signingKey` | HMAC-SHA1 signing key for Google Maps requests | `StaticMapsServlet.java`, `GoogleV3Provider.java` |
| `MapProxy.google.clientID` | Google Maps for Business client identifier | `GoogleV3Provider.java`, `CommonMapsServlet.java` |
| `MapProxy.google.domain` | Base domain for Google Maps API calls (e.g. `https://maps.googleapis.com`) | `GoogleV3Provider.java` |
| `MapProxy.google.staticLibraryPath` | URL path for Google Static Maps API (e.g. `/maps/api/staticmap`) | `GoogleV3Provider.java` |
| `MapProxy.google.dynamicLibraryPath` | URL path for Google Maps JS API loader (e.g. `/maps/api/js`) | `GoogleV3Provider.java` |
| `MapProxy.yandex.countryList` | Comma-separated list of ISO country codes that route to Yandex (e.g. `RU,UA,BY,KZ`) | `MapProvider.java` |
| `MapProxy.yandex.staticLibraryUrl` | Full base URL of the Yandex Static Maps API | `YandexV2Provider.java` |
| `MapProxy.yandex.dynamicLibraryUrl` | Full URL of the Yandex Maps JS library | `YandexV2Provider.java` |

## Per-Environment Overrides

- **Staging (GCP us-central1 / europe-west1)**: `CONFIG_FILE` points to staging-specific config; replicas 2–5; reduced CPU/memory resource requests; VIP on the `stable` VPC.
- **Production US (GCP us-central1)**: `CONFIG_FILE` points to production config; replicas 2–15; VIP `map-proxy.us-central1.conveyor.prod.gcp.groupondev.com`.
- **Production EU (AWS eu-west-1)**: `CONFIG_FILE` points to EU production config; replicas 2–15; separate EU Kafka endpoint (`kafka-elk-broker.dub1`) for log shipping; VIP `map-proxy.prod.eu-west-1.aws.groupondev.com`.
- **Production EU (GCP europe-west1)**: Separate GCP EU cluster deployment with equivalent config.
