---
service: "booster"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 1
---

# Integrations

## Overview

The Booster integration landscape consists of one external dependency (the Booster SaaS API provided by Data Breakers) and one internal Groupon integration boundary (`continuumBoosterService`). Booster itself is a leaf external service with no further downstream Groupon-owned dependencies. The integration is synchronous over HTTPS and sits on the critical consumer request path.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Booster (Data Breakers) | REST / HTTPS | Primary search relevance ranking for consumer deal discovery | yes | `booster` |

### Booster (Data Breakers) Detail

- **Protocol**: REST over HTTPS
- **Base URL / SDK**: Vendor-managed; not discoverable from this repository. Refer to https://groupondev.atlassian.net/wiki/spaces/RAPI/pages/80466641012/Data+Breakers+-+Booster
- **Auth**: Vendor-managed API key or credential (details in vendor agreement)
- **Purpose**: Provides ranked and personalized deal recommendations to power Groupon's consumer discovery experience on the critical request path
- **Failure mode**: Degraded or failed deal ranking for consumer search and discovery; impacts consumer-facing deal listing quality
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `continuumBoosterService` | Internal | Groupon-owned integration boundary encapsulating calls to the Booster external API | `continuumBoosterService` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| `continuumRelevanceApi` | API / SyncAPI, CriticalPath | Primary relevance and ranking calls on the critical consumer request path |
| `continuumSystem` | API | System-level external relevance dependency |
| `encoreSystem` | API | System-level external relevance dependency |

> Upstream consumers are also tracked in the central architecture model (`structurizr/model/relations.dsl` and `structurizr/model/continuum-relations.dsl`).

## Dependency Health

The `boosterSvc_integrationHealth` component within `continuumBoosterService` is responsible for monitoring Booster API availability, latency, and error rates. The `boosterSvc_apiContract` component emits health signals and integration error context to `boosterSvc_integrationHealth`. The `boosterSvc_supportRunbook` component consumes these health signals to guide incident response procedures.

- **Health monitoring**: `boosterSvc_integrationHealth` component within `continuumBoosterService`
- **Dashboard**: https://groupon.wavefront.com/u/lVgXTqptGN?t=groupon
- **PagerDuty**: https://groupon.pagerduty.com/service-directory/PPPC7X8
- **Retry / circuit breaker**: No evidence found in codebase
