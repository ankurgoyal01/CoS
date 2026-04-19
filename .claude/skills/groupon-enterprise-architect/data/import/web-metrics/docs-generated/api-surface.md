---
service: "web-metrics"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> Not applicable

Web Metrics is a Kubernetes CronJob and does not expose any HTTP endpoints, gRPC services, or other network-accessible APIs. It is an outbound-only batch process: it consumes the Google PageSpeed Insights API and publishes metric data to Telegraf. There is no inbound API surface.

The service exposes a CLI interface for local development and operational use:

## CLI Interface

| Command | Flag | Required | Description |
|---------|------|----------|-------------|
| `web-metrics start` | `-c, --config <path>` | Yes | Path to a `webmetrics.config.json` file, or an HTTP URL to fetch config from |
| `web-metrics start` | `-a, --appName <name>` | No | Name of the service being tested; used as a metric tag |
| `web-metrics start` | `-o, --outputFile <path>` | No | Path to write dry-run output JSON file |
| `web-metrics start` | `-d, --dryRun` | No | Suppresses writes to Telegraf; prints data points to stdout instead |

## Request/Response Patterns

> No evidence found in codebase.

Not applicable — no HTTP server or API server is instantiated by this service.

## Rate Limits

> No rate limiting configured.

The service applies no rate limiting on inbound traffic because it accepts no inbound traffic. Outbound calls to the Google PageSpeed Insights API are implicitly rate-limited by the API key quota at Google's end.

## Versioning

> No evidence found in codebase.

Not applicable — no API versioning strategy is implemented.

## OpenAPI / Schema References

> No evidence found in codebase.

No OpenAPI spec, proto files, or GraphQL schema exist in this repository. The input schema is defined informally in the README and the `input-example*.json` files in the repository root.
