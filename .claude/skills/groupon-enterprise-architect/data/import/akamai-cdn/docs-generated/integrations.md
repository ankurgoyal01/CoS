---
service: "akamai-cdn"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 0
---

# Integrations

## Overview

This service has one external dependency: the Akamai SaaS platform, accessed via HTTPS. There are no internal Groupon service dependencies — `akamai-cdn` is a leaf node in the dependency graph that communicates exclusively outward to the Akamai platform. Upstream consumers are Groupon web properties and API gateways that rely on Akamai edge delivery, but those relationships are tracked at the central architecture model level.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Akamai | HTTPS | Manages CDN policies, delivery settings, property rules, and caching behavior | yes | `akamai` |

### Akamai Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: `https://control.akamai.com` (Control Center UI and OPEN API gateway)
- **Auth**: EdgeGrid API key authentication (Akamai-proprietary HMAC-based signing for API calls)
- **Purpose**: Apply and verify CDN property configurations, caching rules, routing policies, and WAF settings on the Akamai edge network. This is Groupon's primary CDN and edge delivery platform serving consumer and merchant traffic globally.
- **Failure mode**: If the Akamai Control Center API is unavailable, configuration changes cannot be applied. Existing CDN configurations already deployed to edge nodes continue to serve traffic — delivery is unaffected by a Control Center outage. Only change operations are blocked.
- **Circuit breaker**: Not applicable — this is an operational management integration, not a runtime request path. Configuration changes are applied manually or via automation; retries are handled at the operator level.

## Internal Dependencies

> No evidence found of internal Groupon service dependencies for this service.

## Consumed By

> Upstream consumers are tracked in the central architecture model. All Groupon web properties and API surfaces that route traffic through Akamai edge nodes are consumers of the CDN configuration managed by this service.

## Dependency Health

The Akamai Control Center provides its own health and status dashboard. The SRE team (cloud-routing@groupon.com) monitors the Akamai portal at `https://control.akamai.com` for configuration change status and delivery health signals. No Groupon-side circuit breaker or retry logic is implemented for this management integration, as it is an operational tooling interface rather than a runtime service dependency.
