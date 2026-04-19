---
service: "zendesk"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 3
---

# Integrations

## Overview

Zendesk integrates with one external SaaS system (Salesforce) and three internal Continuum Platform services (OgWall, Cyclops, Global Support Systems). All relationships are declared in the architecture DSL and sourced from the `.service.yml` dependencies list. All interactions are outbound from `continuumZendesk` to these dependencies; no upstream callers are declared within this service's own architecture model.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | API | Synchronizes support and CRM information between Zendesk and Salesforce | yes | `salesForce` |

### Salesforce Detail

- **Protocol**: API (SaaS-to-SaaS integration)
- **Base URL / SDK**: Salesforce REST or Bulk API — no Groupon-owned client code found in repository
- **Auth**: Managed within Zendesk's Salesforce integration configuration
- **Purpose**: Keeps Salesforce CRM records in sync with Zendesk support case data to give support agents and sales teams a unified view of customer interactions
- **Failure mode**: CRM sync may become stale; ticket data remains in Zendesk; Salesforce records may not reflect latest case status
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| OgWall | API | Identity and user management integration | `continuumOgwallService` |
| Cyclops | API | Internal tooling integration | `cyclops` |
| Global Support Systems | API | Supports global support workflows | `continuumGlobalSupportSystems` |

### OgWall (`continuumOgwallService`) Detail

- **Protocol**: API
- **Purpose**: OgWall provides identity and user account data consumed by Zendesk support workflows. Declared as a dependency in `.service.yml`.
- **Failure mode**: Support workflows requiring user identity data may be impacted if OgWall is unavailable
- **Circuit breaker**: No evidence found in codebase

### Cyclops Detail

- **Protocol**: API
- **Purpose**: Internal Groupon tooling integration, declared as a dependency in `.service.yml`. Exact usage not further specified in the codebase.
- **Failure mode**: No evidence found in codebase
- **Circuit breaker**: No evidence found in codebase

### Global Support Systems (`continuumGlobalSupportSystems`) Detail

- **Protocol**: API
- **Purpose**: Zendesk supports the Global Support Systems service by providing ticket and case management capabilities as part of the broader GSS workflow
- **Failure mode**: GSS agent workflows may be degraded if Zendesk is unavailable
- **Circuit breaker**: No evidence found in codebase

## Consumed By

> Upstream consumers are tracked in the central architecture model. No explicit upstream callers are declared in this service's own architecture DSL beyond the relationship with `continuumGlobalSupportSystems`.

## Dependency Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Salesforce | No evidence found in codebase | No evidence found in codebase |
| OgWall | No evidence found in codebase | No evidence found in codebase |
| Cyclops | No evidence found in codebase | No evidence found in codebase |
| Global Support Systems | No evidence found in codebase | No evidence found in codebase |

> Operational health check and retry patterns are managed by the GSS team. See the owners manual at [https://confluence.groupondev.com/display/GSS/Owners+Manual+-+Zendesk](https://confluence.groupondev.com/display/GSS/Owners+Manual+-+Zendesk).
