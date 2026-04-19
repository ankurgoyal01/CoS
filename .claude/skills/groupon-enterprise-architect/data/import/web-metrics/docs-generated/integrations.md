---
service: "web-metrics"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 1
---

# Integrations

## Overview

Web Metrics has two runtime dependencies: one external (Google PageSpeed Insights API) and one internal (Telegraf/Wavefront metrics gateway). Both are outbound-only. The service fetches performance data from Google and writes metric points to the internal metrics stack. No Groupon service calls web-metrics at runtime.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google PageSpeed Insights API | HTTPS REST | Retrieves CrUX field data and Lighthouse lab data for configured page URLs | Yes | `googlePageSpeedInsights` |

### Google PageSpeed Insights API Detail

- **Protocol**: HTTPS REST (JSON response)
- **Base URL**: `https://www.googleapis.com/pagespeedonline/v5/runPagespeed` (sourced from `lib/defaultConfigs.js`)
- **Auth**: API key — `key` query parameter. The default key is embedded in `defaultPSIConfig.apiKey` in `lib/defaultConfigs.js`. Secret values are not documented here.
- **Purpose**: For each configured `cruxRun` entry, the service POSTs a query with the target URL and platform (mobile/desktop). The response contains `loadingExperience` (CrUX field data with Core Web Vitals distributions) and `lighthouseResult` (Lighthouse audit scores).
- **Failure mode**: If the API call fails, the error is caught, `hasFailed` is set to `true`, and the run is skipped. The error is logged via `itier-tracing`. The rest of the batch continues.
- **Circuit breaker**: No circuit breaker library is used. Retry is handled by `promise-retry` with up to 5 retries and a 5000 ms max timeout for config fetching. PSI API calls have a 300 s (30 s × 10) timeout with a 100 s (10 s × 10) connect timeout via `gofer`.
- **Environments queried**: CrUX runs are restricted to production environments only (`envs` that do not start with `staging`). Supported: `production-us` (groupon.com), `production-gb`, `production-de`, `production-fr`, `production-it`, `production-pl`, `production-au`, `production-nl`, `production-br`, `production-ie`.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Telegraf / Wavefront metrics gateway | Influx Line Protocol over HTTP | Receives performance metric data points for storage and visualization in Wavefront | `metricsStack` |

### Telegraf / Wavefront Metrics Gateway Detail

- **Protocol**: Influx Line Protocol over HTTP (via the `influx` npm client)
- **Default host**: `metrics-gateway-vip.snc1` port `80` (on-premises); overridden by `TELEGRAF_URL` env var in Kubernetes deployments
- **Auth**: No explicit auth — network-level access control within the Groupon VPC
- **Purpose**: Metric data points (tagged with `appname`, `country`, `platform`, `path`, `env`, `perfrun`, `group`, `component`, etc.) are written to Telegraf, which routes them to Wavefront dashboards (`https://groupon.wavefront.com/dashboards/Web-Metrics`, `https://groupon.wavefront.com/dashboards/PagesSpeedInsight-Crux`)
- **Measurement naming convention**: `perf.<formatKey>.<runName>` (e.g., `perf.crux.lcpms`, `perf.lighthouse.performance`)
- **Failure mode**: Write errors are caught and logged. Bad tag/field data points are individually identified from error position hints in the Influx error message and logged separately.
- **Dry-run bypass**: When `--dryRun` CLI flag is set, Telegraf writes are suppressed entirely.

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Web Metrics is a CronJob; it is not called by any other service. Its outputs are consumed indirectly via Wavefront dashboards by the SEO engineering team and service owners who registered their page paths.

## Dependency Health

- **PSI API**: Errors are caught per-run and logged. Failed runs are skipped; the batch continues with remaining URLs. No explicit health endpoint is checked before starting.
- **Telegraf gateway**: Write errors are caught and logged via `itier-tracing`. The `influx` client does not implement automatic retry for write failures. If Telegraf is unavailable, data for that invocation is lost.
- **Chrome / Lighthouse** (currently disabled in production): `promise-retry` retries failed Lighthouse runs up to 5 times. Chrome is killed and re-spawned between retries. A 90-second per-run timeout (`LIGHTHOUSE_TIMEOUT`) is enforced.
