---
service: "tracky-rest"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 0
---

# Integrations

## Overview

Tracky REST has one external downstream dependency: the `tracky_json_nginx` Kafka topic (consumed by the Bloodhound analytics pipeline). The service itself has no outbound HTTP calls and makes no calls to other internal services. It is a pure ingestion leaf node. Upstream callers are any HTTP client (browser or server) that knows the endpoint URL.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Kafka topic `tracky_json_nginx` | Log shipping (filesystem-to-Kafka) | Transport of enriched JSON events to the Bloodhound user-interaction pipeline | yes | `kafkaTrackyJsonNginxTopic` (stub) |

### Kafka `tracky_json_nginx` Detail

- **Protocol**: Log shipping — Tracky REST writes to local disk; an external agent ships to Kafka. No direct Kafka client library is present in this service.
- **Base URL / SDK**: Not applicable — integration is indirect via filesystem log files at `/var/groupon/log/tracky_json/rotated/`.
- **Auth**: Managed by the external log-shipping agent (not visible in this repository).
- **Purpose**: Deliver all ingested Tracky events to downstream analytics consumers (Bloodhound user-interaction pipeline).
- **Failure mode**: If Kafka or the log shipper is unavailable, events accumulate in local rotated log files until the shipper recovers. Disk usage will grow until the 7-day retention cron purges old files.
- **Circuit breaker**: No — the service does not have a direct Kafka connection and therefore has no circuit breaker.

## Internal Dependencies

> No evidence found in codebase. Tracky REST makes no outbound calls to other internal Groupon services.

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Client applications (browsers, server-side services) | HTTP POST | Submit structured analytics and tracking event payloads |

> Upstream consumers are tracked in the central architecture model. The service discovery base URL is `http://tracky-internal-vip.snc1` (internal) and `http://na.groupondata.com/tracky` (external).

## Dependency Health

- There is no direct Kafka connection in this service — health of the `tracky_json_nginx` topic delivery depends entirely on the external log-shipping pipeline.
- Nginx's `/nginx_status` endpoint (stub status) provides basic worker and connection counts for infrastructure monitoring.
- Service dashboards are available at `https://groupon.wavefront.com/dashboard/tracky` and related Wavefront dashboards listed in `.service.yml`.
- PagerDuty service: `P4VBAQS` (data-systems-pager@groupon.com).
