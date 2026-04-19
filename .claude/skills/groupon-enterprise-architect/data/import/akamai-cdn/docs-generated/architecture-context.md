---
service: "akamai-cdn"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumAkamaiCdn"]
---

# Architecture Context

## System Context

`akamai-cdn` sits within the `continuumSystem` (Continuum Platform) as the operational ownership unit for Groupon's Akamai CDN usage. It acts as a configuration management boundary between Groupon's internal infrastructure and the external Akamai SaaS platform (`akamai` external software system). Groupon's web properties and API surfaces are served through Akamai edge nodes; this service controls the rules and policies that govern how those requests are handled at the edge.

There are no direct human users of this service — it is operated by the SRE cloud-routing team through the Akamai Control Center web UI and APIs. The `continuumAkamaiCdn` container communicates with the external `akamai` system via HTTPS to apply and verify configuration changes.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Akamai CDN Service | `continuumAkamaiCdn` | Container | Akamai CDN | N/A | Operational ownership and configuration management for Groupon's Akamai CDN usage |

## Components by Container

### Akamai CDN Service (`continuumAkamaiCdn`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Configuration Management | Defines and applies CDN property rules, caching behavior, and routing policies | Akamai Property Manager / Control Center |
| Observability | Collects status and operational signals for CDN changes and runtime delivery health | Akamai DataStream / telemetry |

**Internal component relationship**: The `akamaiCdnConfiguration` component publishes CDN change and health telemetry to the `akamaiCdnObservability` component. This ensures that every configuration change applied through the Configuration Management component generates observable signals that the Observability component can track.

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumAkamaiCdn` | `akamai` | Manages CDN policies and delivery settings via | HTTPS |
| `akamaiCdnConfiguration` | `akamaiCdnObservability` | Publishes CDN change and health telemetry | Internal |

## Architecture Diagram References

- Component: `components-akamai-cdn`
- Dynamic (operations flow): `dynamic-akamai-cdn-operations-flow`
