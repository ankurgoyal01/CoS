---
service: "ORR"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 0
---

# Integrations

## Overview

The ORR Audit Toolkit has four external dependencies, all accessed via HTTP or git from an on-prem Linux host. There are no internal Groupon service dependencies — the toolkit reads directly from configuration repositories and infrastructure APIs. No circuit breakers or retry logic is implemented; scripts exit on failure with a descriptive message.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| ops-config repository | git / filesystem | Source of truth for production host YAML config and lbmon VIP monitor files | yes | `opsConfigRepository` |
| Service Portal | HTTP REST | Validates service name exists before auditing; retrieves service lifecycle and ORR autoscoring attributes | yes | `servicePortal` |
| LBMS API | HTTP REST | Retrieves VIP SNMP OID metadata used to correlate VIP names against lbmon config | yes | `lbmsApi` |
| Raw GitHub Content Server | HTTPS | Fetches NetOps load balancer config files for VIP-to-service-group traversal; checks script self-version | yes | `rawGithubContent` |

### ops-config Repository Detail

- **Protocol**: git clone + `git pull` (filesystem read after pull)
- **Base URL**: Local clone at `~/` (located by finding `ops-config-push.sh`)
- **Auth**: Internal GitHub Enterprise (SSH/HTTPS credentials of operator)
- **Purpose**: All host YAML files in `ops-config/hosts/` are parsed to find production hosts by service, read monitor notify sections (`notify:`, `notify_under_monitors:`, `notify_host:`), and detect hosts missing `subservices` mapping
- **Failure mode**: Scripts exit early with "unable to locate ops-config repo" if clone is not found
- **Circuit breaker**: No

### Service Portal Detail

- **Protocol**: HTTP REST
- **Base URL**: `http://service-portal-vip.snc1`
- **Auth**: `GRPN-Client-ID: tdo-coea-automation` request header (used in `autoscore.sh`)
- **Purpose**: Validates that a given `svc_name` is registered (`/services/<svc_name>` returns HTTP 200) before proceeding; also queries `/api/v1/services/<svc>/attributes/lifecycle` and `/api/v2/services/<svc>?include_orr=true` for autoscoring and lifecycle data
- **Failure mode**: Scripts exit with HTTP 200 check failure; operator must confirm VPN access and correct service name
- **Circuit breaker**: No

### LBMS API Detail

- **Protocol**: HTTP REST
- **Base URL**: `http://lbmsv2-vip.snc1`
- **Auth**: None (intranet/VPN access required)
- **Purpose**: `GET /v2/vip_snmp_oids?vip_name=<vip>&colo=<colo>` returns the SNMP OID for a given VIP, which is then used to locate the corresponding monitor block in `lbmon1.<colo>.yml`
- **Failure mode**: If SNMP OID lookup returns empty, VIP is skipped with a log message and processing continues
- **Circuit breaker**: No

### Raw GitHub Content Server Detail

- **Protocol**: HTTPS GET
- **Base URL**: `https://raw.github.groupondev.com`
- **Auth**: Internal GitHub Enterprise access (intranet/VPN)
- **Purpose**: Two uses — (1) fetch NetOps load balancer config files under `prod-netops/netops_oxidized_<colo>_config/master/load_balancers/<lb_name>` to resolve VIP-to-server-group-to-VServer mappings; (2) fetch script header of each script's latest version from `SOC/ORR/master/bin/<script>` for self-update check
- **Failure mode**: VIP resolution skips unavailable load balancer nodes; version check silently skips if content is unavailable
- **Circuit breaker**: No

## Internal Dependencies

> No evidence found in codebase.

## Consumed By

Upstream consumers are tracked in the central architecture model. The ORR Audit Toolkit is invoked manually by operators and is not called by any other service.

## Dependency Health

Scripts perform a pre-flight check against Service Portal (HTTP 200 validation) before executing audit logic. The `ops-config` repo is updated via `git pull` at the start of each run to ensure fresh configuration data. No automated health checks, retries, or timeouts are configured beyond curl's default behavior.
