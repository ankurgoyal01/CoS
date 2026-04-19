---
service: "web-metrics"
title: Overview
generated: "2026-03-03"
type: overview
domain: "SEO / Web Performance"
platform: "Continuum"
team: "SEO"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "ES2022 (CommonJS)"
  framework: "nilo"
  framework_version: "4.0.11"
  runtime: "Node.js"
  runtime_version: ">=18"
  build_tool: "npm / nlm"
  package_manager: "npm"
---

# Web Metrics Overview

## Purpose

Web Metrics is a scheduled Kubernetes CronJob owned by the SEO team that periodically audits Groupon web pages for performance quality. It calls the Google PageSpeed Insights API to collect CrUX (Chrome User Experience Report) field data and Lighthouse lab data for configured page paths across multiple environments and regions, then publishes normalized metric data points to the Telegraf/Wavefront observability stack. The service exists to give engineering teams an automated, continuous signal on real-user web performance (Core Web Vitals) and lab-measured Lighthouse scores without manual intervention.

## Scope

### In scope

- Loading per-service `webmetrics.config.json` configurations that specify which page paths to audit
- Fetching CrUX data (field data from real Chrome users) via the Google PageSpeed Insights v5 API
- Running Lighthouse lab audits via headless Chrome (currently disabled in production; framework retained)
- Transforming raw PSI/Lighthouse audit payloads into normalized Influx-compatible data points
- Publishing metric points to Telegraf using the Influx Line Protocol
- Supporting multi-environment runs: `production-us`, `production-gb`, `production-de`, `production-fr`, `production-it`, `production-pl`, `production-au`, `production-nl`, `production-br`, `production-ie`, `staging-us`
- Supporting per-run platform selection (`mobile`, `desktop`)
- Enforcing configurable performance budgets per resource type per platform
- Dry-run mode for local development (suppresses Telegraf writes)

### Out of scope

- Serving HTTP traffic — this is a batch job, not a web service
- Real-time user monitoring (RUM) — CrUX is aggregated historical data
- Alerting rule management — alerts are configured in Wavefront dashboards
- Storing historical raw audit results — only aggregated metric points are published

## Domain Context

- **Business domain**: SEO / Web Performance
- **Platform**: Continuum
- **Upstream consumers**: This service has no upstream callers; it is triggered by Kubernetes CronJob schedule
- **Downstream dependencies**: Google PageSpeed Insights API (external), Telegraf/Wavefront metrics gateway (internal)

## Stakeholders

| Role | Description |
|------|-------------|
| SEO Engineering Team | Owns and operates the service (seo-dev@groupon.com) |
| Service owners (onboarding) | Register their page paths via `webmetrics.config.json` to get performance data |
| SRE / Platform | Monitors job health via Wavefront dashboards and Splunk logs |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript (CommonJS) | ES2022 | `package.json` |
| Runtime | Node.js | >=18 | `package.json` engines field, `Dockerfile` `FROM node:18` |
| Framework | nilo | 4.0.11 | `package.json` dependencies |
| Package manager | npm | | `.npmrc`, `package.json` |
| Build / release tool | nlm | 5.5.1 | `package.json` devDependencies |
| Containerization | Docker | node:18 base | `Dockerfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `lighthouse` | ^12.3.0 | metrics | Runs headless Lighthouse audits against URLs |
| `chrome-launcher` | ^1.1.2 | metrics | Spawns headless Chrome instances for Lighthouse |
| `gofer` | ^5.2.4 | http-client | HTTP client for fetching PSI API and remote config URLs |
| `influx` | ^5.9.3 | db-client | Writes metric data points to Telegraf using Influx Line Protocol |
| `itier-instrumentation` | ^9.13.4 | metrics | Groupon internal instrumentation/telemetry |
| `itier-tracing` | ^1.9.1 | logging | Structured trace logging throughout service |
| `keldor-config` | ^4.22.0 | config | Groupon internal config loading |
| `groupon-steno` | ^4.1.0 | logging | Structured log format (steno) parser |
| `@grpn/pretty-steno` | ^1.1.3 | logging | Pretty-prints steno log lines for local TTY output |
| `piscina` | ^4.7.0 | scheduling | Worker thread pool for dispatching measurement work |
| `promise-retry` | ^2.0.1 | http-client | Retry wrapper for PSI API calls and Lighthouse runs |
| `napistrano` | ^2.181.8 | deployment | Groupon deployment tooling / Helm chart generation |
| `nilo` | ^4.0.11 | http-framework | CLI application framework (command registration, lifecycle) |
