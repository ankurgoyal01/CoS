---
service: "barcode-service-app"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 1
---

# Integrations

## Overview

Barcode Service has minimal integration dependencies. It has no outbound HTTP calls to external or internal services at runtime — all rendering logic is self-contained using embedded libraries. The only declared service dependency in `.service.yml` is `tsd_aggregator`, which is the Groupon internal metrics/telemetry aggregation service used passively by the JTier framework for operational metrics. The service is consumed by any internal system needing on-demand barcode image generation.

## External Dependencies

> No evidence found in codebase for outbound calls to external third-party systems.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `tsd_aggregator` | JTier framework (UDP/metrics) | Time-series metrics aggregation; receives JVM and HTTP metrics emitted by the JTier platform instrumentation | Groupon internal platform service |

### `tsd_aggregator` Detail

- **Protocol**: JTier metrics emission (UDP-based TSD aggregator client, managed by the JTier framework automatically)
- **Base URL / SDK**: Managed by JTier platform; no explicit configuration in application code
- **Auth**: None (internal network)
- **Purpose**: Receives JVM heap, GC, and HTTP request rate/latency metrics for dashboards and alerting
- **Failure mode**: Metric loss only — barcode generation is unaffected if aggregator is unavailable
- **Circuit breaker**: Not applicable (fire-and-forget metrics emission)

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known consumers based on service description and URL pattern analysis include:
>
> - Voucher print services (requesting barcode images for print layouts)
> - Mobile redemption clients (using `/fubar/v1/barcode/mobile/` endpoints)
> - Merchant center redemption portals (using `/fubar/v3/barcode/{codeType}/{width}/{height}/https:/{domain}/merchant/center/redeem/{payload}.*` endpoints)
> - Any Continuum service requiring on-demand barcode rendering

## Dependency Health

The service has a built-in Dropwizard health check (`BarcodeServiceHealthCheck`). The JTier framework provides automatic health endpoint exposure at `/grpn/status` (port 8080). No circuit breaker or retry logic is needed given the service has no outbound HTTP dependencies.
