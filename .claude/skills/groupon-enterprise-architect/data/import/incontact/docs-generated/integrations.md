---
service: "incontact"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 2
---

# Integrations

## Overview

InContact has one external integration (the InContact SaaS platform itself, vendor-managed) and two declared internal dependencies within the Continuum platform: `ogwall` and `global_support_systems`. Both internal relationships are currently recorded as stub-only in the architecture DSL and have not been elaborated with protocol or payload details.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| NICE InContact SaaS | vendor SDK / web | Cloud contact centre platform providing agent desktop, telephony, and digital channel capabilities | yes | `continuumIncontactService` |

### NICE InContact SaaS Detail

- **Protocol**: Vendor-managed (SaaS); likely HTTPS/REST and/or WebRTC for telephony
- **Base URL / SDK**: Managed externally by NICE inContact; see architecture doc at https://drive.google.com/file/d/1hogsBRetYJ2CU-cpiQVX4s26wnB21psS/view
- **Auth**: Vendor-managed authentication within the InContact SaaS platform
- **Purpose**: Provides contact centre infrastructure for Groupon GSS agents — handles inbound/outbound calls, chat, and digital customer contact channels
- **Failure mode**: Loss of contact centre capability for GSS agents; customers unable to reach support
- **Circuit breaker**: Not applicable — SaaS dependency managed by vendor SLA

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| ogwall | Unknown (stub-only) | Declared dependency — exact protocol and purpose not yet elaborated | `ogwall` |
| global_support_systems | Unknown (stub-only) | Declared dependency — exact protocol and purpose not yet elaborated | `global_support_systems` |

> Note: Both internal dependencies are marked `[stub-only]` in `architecture/models/relations.dsl`. Full elaboration (protocol, data flow, criticality) is pending.

## Consumed By

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

> No evidence found in codebase.

Operational procedures to be defined by service owner. For SRE escalation, contact gss-dev@groupon.pagerduty.com or PagerDuty service PN9TCKJ.
