---
service: "raas_c1"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 0
internal_count: 1
---

# Integrations

## Overview

RAAS C1 declares one internal dependency: `raas_dns`, the DNS service that enables service discovery for C1 Redis nodes. No external integrations exist for this Service Portal registration entry. All Redis platform integrations (Redislabs API, AWS ElastiCache, Kubernetes API, GitHub Secrets) are managed by the `raas` platform containers, not by this entry.

## External Dependencies

> No evidence found — this service declares no external integrations.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| raas_dns | Internal DNS | Provides service discovery and DNS resolution for C1 Redis node routing | `.service.yml` dependency declaration |

### raas_dns Detail

- **Protocol**: Internal DNS
- **Base URL / SDK**: Groupon internal DNS infrastructure
- **Auth**: No evidence found
- **Purpose**: Enables the C1 Service Portal entry to route internal requests to the correct Redis nodes in the snc1, sac1, and dub1 colos
- **Failure mode**: C1 Redis node routing becomes unavailable; internal tooling cannot resolve endpoints
- **Circuit breaker**: No evidence found

## Consumed By

> Upstream consumers are tracked in the central architecture model. The RAAS C1 Service Portal entry is consumed by Groupon's OCT tooling and BASTIC ticketing system for C1-scoped Redis operational management.

## Dependency Health

> Operational procedures to be defined by service owner. For `raas_dns` health, contact the DNS infrastructure team. The `raas-team` is reachable at raas-pager@groupon.com for on-call incidents.
