---
service: "booster"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "booster"
  containers: ["continuumBoosterService"]
---

# Architecture Context

## System Context

Booster is modeled as an external `softwareSystem` in the Groupon architecture (`booster`). It sits outside the Continuum and Encore platforms and is called by both `continuumSystem` and `encoreSystem` for primary search relevance ranking. Within Continuum, the integration is encapsulated by the `continuumBoosterService` container, which acts as the Groupon-owned boundary between internal Continuum services and the Booster external API.

The critical consumer request path flows as follows: consumer request reaches `apiProxy`, which routes to `continuumRelevanceApi`, which calls `booster` (external SaaS) for ranked deal recommendations. Additionally, `continuumApiLazloService` routes proxied search requests through `continuumRelevanceApi`, which in turn calls Booster.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Booster 3rd Party Relevance Integration | `continuumBoosterService` | Service | Service Metadata and Integration | N/A | Continuum-owned integration boundary for using Booster relevance capabilities provided by Data Breakers. |
| Booster (external SaaS) | `booster` | External SaaS | N/A | N/A | External SaaS providing primary search and relevance ranking for Groupon discovery experiences. |

## Components by Container

### Booster 3rd Party Relevance Integration (`continuumBoosterService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Booster API Contract (`boosterSvc_apiContract`) | Defines the interface and data schemas for interacting with the Booster relevance API; emits integration health signals and error context to the health monitor | Integration Contract |
| Support Runbook (`boosterSvc_supportRunbook`) | Operational support documentation and procedures for Booster integration incidents; consumes integration health state to guide incident response | Operational Knowledge |
| Integration Health Monitoring (`boosterSvc_integrationHealth`) | Monitors Booster API availability, latency, and error rates; receives signals from the API contract component | Monitoring |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumBoosterService` | `booster` | Uses Booster relevance APIs for ranked deal recommendations | HTTPS |
| `continuumRelevanceApi` | `booster` | Primary relevance and ranking calls on the critical consumer path | API / SyncAPI, CriticalPath |
| `apiProxy` | `continuumRelevanceApi` | Routes consumer relevance requests | REST / SyncAPI, CriticalPath |
| `continuumApiLazloService` | `continuumRelevanceApi` | Proxies search requests | REST / SyncAPI, CriticalPath |
| `continuumRelevanceApi` | `continuumApiLazloService` | Uses Lazlo APIs for enrichment | REST |
| `continuumRelevanceApi` | `continuumMarketingDealService` | Marketing deal enrichment | Internal |
| `continuumSystem` | `booster` | External relevance (primary) | API |
| `encoreSystem` | `booster` | External relevance (primary) | API |
| `boosterSvc_apiContract` | `boosterSvc_integrationHealth` | Emits integration health signals and error context | Internal |
| `boosterSvc_supportRunbook` | `boosterSvc_integrationHealth` | Consumes health state to guide incident response | Internal |

## Architecture Diagram References

- Component view: `components-continuum-booster-service`
- Dynamic view: `dynamic-booster-relevance-request`
