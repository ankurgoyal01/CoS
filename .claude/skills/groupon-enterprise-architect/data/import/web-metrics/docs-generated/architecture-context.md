---
service: "web-metrics"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumWebMetricsCli", "continuumWebMetricsWorker"]
---

# Architecture Context

## System Context

Web Metrics is a component of the Continuum platform (`continuumSystem`). It operates as a self-contained Kubernetes CronJob with no inbound HTTP traffic. The service reads configuration files, calls the Google PageSpeed Insights API (`googlePageSpeedInsights`) to collect performance data, and pushes results to the internal Telegraf metrics gateway (`metricsStack`). No other Groupon services call web-metrics; it is purely an outbound-only, scheduled batch consumer of external performance data.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| Web Metrics CLI | `continuumWebMetricsCli` | CronJob entrypoint | Node.js, nilo | CLI entrypoint that loads run configuration, initializes telemetry context, and dispatches measurement work to worker threads |
| Web Metrics Worker | `continuumWebMetricsWorker` | Worker runtime | Node.js, Piscina worker threads | Worker execution runtime that calls PageSpeed Insights, transforms audits, and publishes metrics to the Telegraf gateway |

## Components by Container

### Web Metrics CLI (`continuumWebMetricsCli`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| CLI Command Adapter (`wmCliEntryCommand`) | Implements the `start` command, argument parsing (`-c`, `-a`, `-o`, `-d`), and optional pretty output flow via steno/pretty-steno | Node.js (nilo) |
| Configuration Resolver (`wmCliConfigResolution`) | Loads JSON config from an inline object, a local file path, or a remote HTTP URL with retry logic (up to 5 retries, 5000 ms max timeout) | Node.js configuration logic |
| Worker Dispatcher (`wmCliJobDispatcher`) | Coordinates per-service execution across all configured `cruxRuns` and `perfRuns`; sends jobs to Piscina worker threads | Piscina worker orchestration |

### Web Metrics Worker (`continuumWebMetricsWorker`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| PageSpeed Runner (`wmWorkerPageSpeedRunner`) | Builds query URLs and invokes the Google PageSpeed Insights v5 endpoint per configured run, platform, and environment | Node.js gofer HTTP client |
| Result Mapper (`wmWorkerResultMapper`) | Extracts CrUX loading experience fields and Lighthouse audit payloads; applies per-audit filter transforms; builds normalized Influx point payloads | Node.js mapping/filter pipeline |
| Telegraph Writer (`wmWorkerTelegraphWriter`) | Validates that points contain non-null fields; writes validated points to the configured Telegraf/Influx metrics gateway; handles tag/field parse error reporting | Influx client |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumWebMetricsCli` | `continuumWebMetricsWorker` | Dispatches service configs for execution | Piscina worker thread messages |
| `continuumWebMetricsWorker` | `googlePageSpeedInsights` | Requests CrUX and Lighthouse data for configured URLs | HTTPS JSON API |
| `continuumWebMetricsWorker` | `metricsStack` | Publishes performance points and run telemetry | Influx Line Protocol over HTTP |

## Architecture Diagram References

- Component (CLI): `components-continuum-web-metrics-cli`
- Component (Worker): `components-continuum-web-metrics-worker`
