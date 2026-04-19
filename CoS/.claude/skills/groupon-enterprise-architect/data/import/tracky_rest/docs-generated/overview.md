---
service: "tracky-rest"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Data Systems / Structured Logging"
platform: "Continuum"
team: "Data Systems"
status: active
tech_stack:
  language: "Perl / Ruby"
  language_version: ""
  framework: "Nginx embedded Perl (ngx_http_perl_module)"
  framework_version: ""
  runtime: "Nginx"
  runtime_version: ""
  build_tool: "Roller (git-package / pkgup)"
  package_manager: "Roller ops-config"
---

# Tracky REST Overview

## Purpose

Tracky REST provides a lightweight, high-throughput HTTP endpoint that accepts structured JSON payloads from any client application and durably logs them for downstream transport to Kafka. The service exists to decouple event producers from Kafka, allowing browser and server-side clients to submit analytics events over plain HTTP without requiring direct Kafka access. All ingested events are forwarded to the `tracky_json_nginx` Kafka topic, which serves as the primary Bloodhound user-interaction pipeline.

## Scope

### In scope

- Accepting HTTP POST requests containing a single JSON object or a JSON array of objects at `/tracky`.
- Enriching each event with HTTP metadata: timestamp (`__http_timestamp`), virtual host name (`__http_vhost_name`), `X-Forwarded-For` header (`__http_xff`), client IP (`__http_client_ip`), request ID (`__http_x_request_id`), and Repsheet header (`__http_xrepsheet`).
- Writing enriched events to hourly-rotated log files using `cronolog`.
- Injecting a marker event (`_tracky_hourly_canary_event_2`) at the end of each log file upon rotation via the post-rotate hook.
- Responding to CORS preflight (`OPTIONS`) requests and setting permissive CORS headers.

### Out of scope

- Kafka publishing — log shipping from the local filesystem to the `tracky_json_nginx` topic is handled by an external log-shipping pipeline, not by this service.
- Event validation or schema enforcement beyond JSON parsing.
- Authentication or authorization of callers.
- Consumer-side event processing or analytics.

## Domain Context

- **Business domain**: Data Systems / Structured Logging
- **Platform**: Continuum
- **Upstream consumers**: Any client application (browser, server-side service) that sends structured analytics or tracking events via HTTP POST.
- **Downstream dependencies**: Local filesystem log files (`continuumTrackyJsonLogFiles`); external log shipper transports to the Kafka topic `tracky_json_nginx`.

## Stakeholders

| Role | Description |
|------|-------------|
| Service owner | Data Systems team (data-systems-team@groupon.com); owner: pcammarano |
| On-call / SRE | data-systems-pager@groupon.com; PagerDuty service P4VBAQS |
| Announce list | data-systems-announce@groupon.com |
| Slack channel | CF7HY7XLY |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language (handler) | Perl | unspecified | `lib/tracky_perl_modules/tracky.pm` |
| Language (hook) | Ruby | unspecified | `lib/tracky/bin/post-rotate-hook` |
| Framework | Nginx embedded Perl (ngx_http_perl_module) | unspecified | `etc/nginx.conf` |
| Runtime | Nginx | unspecified | `etc/nginx.conf` |
| Build tool | Roller (git-package / pkgup) | unspecified | `README.md` |
| Package manager | Roller ops-config | unspecified | `README.md` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `nginx` (Perl module) | unspecified | http-framework | Provides Nginx request/response bindings for the embedded Perl handler |
| `JSON::XS` | unspecified | serialization | High-performance JSON encoding and decoding of incoming event payloads |
| `Time::HiRes` | unspecified | logging | High-resolution timestamp injection (`__http_timestamp`) |
| `Scalar::Util` | unspecified | logging | File-handle openness check before opening cronolog pipe |
| `IO::Handle` | unspecified | logging | `autoflush` on the cronolog output handle to prevent buffering |
| `cronolog` | unspecified | scheduling | Hourly log file rotation with symlink management |
| `json` (Ruby gem) | unspecified | serialization | JSON serialization in the post-rotate hook marker event |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
