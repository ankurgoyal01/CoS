---
service: "akamai"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 0
---

# Integrations

## Overview

The akamai service has one external dependency: the Akamai SaaS platform itself. The `continuumAkamaiServiceMetadata` container references the Akamai control plane for WAF configuration, bot management analytics, and security dashboards. There are no internal Groupon service dependencies for this metadata repository. A separate related service, `akamai-cdn` (`continuumAkamaiCdn`), also integrates with the same Akamai platform but is owned independently under CDN delivery operations.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Akamai Control Plane | HTTPS | WAF configuration, bot management controls, and security analytics dashboards | yes | `akamai` |

### Akamai Control Plane Detail

- **Protocol**: HTTPS
- **Base URL**: `https://control.akamai.com` (production and staging, per `.service.yml` `colos.snc1`)
- **Auth**: Akamai account credentials (account ID: `AANA-67IW3O`, contract type: `1-2RBL`) — managed by the Cyber Security team
- **Purpose**: Provides WAF rule management, bot management policy enforcement, and security analytics. The Akamai Security Center dashboards (referenced in `akamaiSecurityDashboards`) are accessed at `https://control.akamai.com/apps/securitycenter` with specific config selector `85902`
- **Failure mode**: If Akamai control plane is unavailable, existing WAF and bot management policies remain enforced at the edge (rules are cached at edge nodes); security analytics and policy changes are blocked until the control plane recovers
- **Circuit breaker**: Not applicable — access to the Akamai control plane is manual/operational, not automated by application code

## Internal Dependencies

> No evidence found — this repository defines no runtime dependencies on other Groupon internal services.

## Consumed By

> Upstream consumers are tracked in the central architecture model. The Akamai edge platform (`akamai`) receives all inbound Groupon consumer and merchant web traffic, making it a foundational security layer for the entire Continuum platform.

## Dependency Health

The Akamai Security Center dashboards referenced in `.service.yml` provide operational visibility into WAF and bot management health:

- Dashboard 1: `https://control.akamai.com/apps/securitycenter?accountId=AANA-67IW3O&contractTypeId=1-2RBL&configSelector=85902&view=ng-web-security-analytics&hash=7e35214a-934c-46e0-ade2-539e460dca05`
- Dashboard 2: `https://control.akamai.com/apps/securitycenter?accountId=AANA-67IW3O&contractTypeId=1-2RBL&configSelector=85902&view=ng-web-security-analytics&hash=eefa4d31-993a-4b9e-9062-c4b6cf236684`
- Dashboard 3: `https://control.akamai.com/apps/securitycenter?accountId=AANA-67IW3O&contractTypeId=1-2RBL&configSelector=85902&view=ng-web-security-analytics&hash=55780191-f766-4beb-b637-77c755b6fd35`

No automated circuit breaker or retry logic is defined in this repository; operational health monitoring is performed manually via the dashboards above.
