---
service: "api-lazlo-sox"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["config-files", "env-vars"]
---

# Configuration

## Overview

API Lazlo and API Lazlo SOX are configured through a combination of JSON configuration files (Lazlo convention), environment variables, and per-environment configuration overlays. The Lazlo framework loads configuration from a hierarchy of files and environment-specific overrides at startup, with Redis-backed feature flags providing runtime configurability.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ENVIRONMENT` | Target environment identifier (dev, staging, production) | Yes | None | env |
| `PORT` | HTTP server listening port | No | 8080 | env |
| `SSL_ENABLED` | Whether to enable SSL/TLS termination | No | false | env |
| `REDIS_HOST` | Redis cluster hostname for cache connectivity | Yes | None | env |
| `REDIS_PORT` | Redis cluster port | No | 6379 | env |
| `LOG_LEVEL` | SLF4J/Logback log level | No | INFO | env |
| `JVM_OPTS` | JVM tuning parameters (heap, GC, etc.) | No | Defaults | env |
| `METRICS_ENABLED` | Enable/disable metrics-vertx collection | No | true | env |
| `JOLOKIA_PORT` | Jolokia JMX-over-HTTP port | No | 8778 | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| Feature flags (various) | Runtime feature gating for A/B tests, rollouts, and market-specific behavior | Per-flag | per-region, per-market |

Feature flag state is stored in Redis (`continuumApiLazloRedisCache`) and read on each request by the common filters layer (`continuumApiLazloService_commonFiltersAndViews`). Flag names and configurations are managed externally and loaded into Redis by the feature flag management system.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `lazloConf.json` | JSON | Primary Lazlo application configuration (server, routing, modules) |
| `lazloConfRedis.json` | JSON | Redis connection and caching configuration |
| `metricsConf.json` | JSON | Metrics collection and export configuration (metrics-vertx) |
| `logback.xml` | XML | Logging configuration (SLF4J/Logback) |
| `controllers.json` | JSON | Controller routing and endpoint registration |
| `clients.json` | JSON | Downstream service client configuration (URLs, timeouts, retries) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Redis credentials | Authentication for the managed Redis cluster | Environment-specific secret management |
| SSL certificates | TLS certificates for HTTPS termination (where applicable) | Environment-specific secret management |
| Downstream service credentials | API keys or tokens for authenticated downstream service calls | Environment-specific secret management |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Configuration differs between environments via environment-specific configuration file overlays:

- **Development**: Local or shared-dev Redis, relaxed timeouts, debug logging, mock downstream clients where needed
- **Staging**: Staging Redis cluster, staging downstream service endpoints, production-like configuration for integration testing
- **Production**: Production Redis (GCP MemoryStore), production downstream service endpoints, optimized JVM settings, INFO-level logging, full metrics and alerting enabled
- **SOX Production**: Same as production but with SOX-specific routing restrictions, separate deployment, and additional audit logging for compliance

The Lazlo framework resolves configuration by loading the base `lazloConf.json` and then merging environment-specific overrides (e.g., `lazloConf-production.json`) based on the `ENVIRONMENT` variable.
