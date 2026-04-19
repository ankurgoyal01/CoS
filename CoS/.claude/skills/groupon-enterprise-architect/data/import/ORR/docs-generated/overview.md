---
service: "ORR"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Operations / Operational Readiness"
platform: "Continuum"
team: "SOC / TDO-COEA Automation"
status: active
tech_stack:
  language: "Bash / Python"
  language_version: "Bash v4+, Python 3.7"
  framework: "N/A"
  framework_version: "N/A"
  runtime: "Linux (CentOS)"
  runtime_version: "N/A"
  build_tool: "N/A"
  package_manager: "pip (Python venv)"
---

# ORR (Operational Readiness Review) Overview

## Purpose

The ORR Audit Toolkit is a repository of CLI scripts that automate repetitive Operational Readiness Review tasks for Groupon's on-prem infrastructure. It verifies that monitoring alert recipients for production hosts and VIPs are pageable via PagerDuty, and that all production hosts have a service identity configured in `ops-config`. The toolkit reduces manual ORR audit effort and produces structured reports that service teams and SOC can act on.

## Scope

### In scope

- Auditing host-level monitor notify recipients for a named service (`orr_audit_host_notify_by_svc.sh`)
- Auditing VIP-level monitor notify recipients for a named service (`orr_audit_vip_notify_by_svc.sh`)
- Fleet-wide report generation for all host and VIP monitor recipients (`orr_audit_pd_list_allsvcs.sh`)
- Detecting production hosts in `ops-config` that have no `subservices` mapping (`hosts_without_service.py`)
- Identifying services with autoscoring disabled in Service Portal (`autoscore.sh`)
- Generating raw text and CSV audit reports saved to the operator's home directory

### Out of scope

- Remediating misconfigured monitors (reports only — service teams act on findings)
- Managing PagerDuty escalation policy configuration
- Cloud/AWS environment monitoring (scripts target on-prem, CentOS hosts only)
- Automated scheduling or CI execution of audits (all scripts are operator-invoked)

## Domain Context

- **Business domain**: Operations / Operational Readiness
- **Platform**: Continuum
- **Upstream consumers**: SOC engineers, ORR reviewers, and service team on-call operators who invoke the scripts manually
- **Downstream dependencies**: `ops-config` repository (host YAML config), Service Portal (`http://service-portal-vip.snc1`), LBMS API (`http://lbmsv2-vip.snc1`), raw GitHub content server (`https://raw.github.groupondev.com`) for NetOps load balancer configs and script version checks

## Stakeholders

| Role | Description |
|------|-------------|
| SOC Engineer | Primary operator of audit scripts; reviews reports and escalates findings |
| ORR Reviewer | Uses audit output to evaluate service operational readiness |
| Service Team On-Call | Receives findings and remediates non-pageable alert configurations |
| TDO-COEA Automation | Maintainer team for the autoscoring and Service Portal integration scripts |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Bash | v4+ | `bin/orr_audit_host_notify_by_svc.sh`, `bin/orr_audit_vip_notify_by_svc.sh`, `bin/orr_audit_pd_list_allsvcs.sh`, `autoscore.sh` |
| Language | Python | 3.7 | `hosts_without_service_project/hosts_without_service.py` header comment |
| Runtime | Linux (CentOS) | N/A | Script header: "run this script on Linux platform (CentOS), tested on host dev1.snc1" |
| Package manager | pip (Python venv) | N/A | `hosts_without_service_project/README.md` |
| Build tool | N/A | N/A | Script-based toolkit; no build step |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jq` | system | serialization | Parses JSON responses from Service Portal and `autoscore.sh` API calls |
| `pyYAML` | pip | serialization | Parses host YAML files in `ops-config/hosts` within `hosts_without_service.py` |
| `curl` | system | http-client | Issues HTTP requests to Service Portal, LBMS API, and raw GitHub endpoints |
| `git` | system | vcs-client | Pulls latest `ops-config` repo state before each audit run |
| `dig` | system | dns | Resolves IP addresses to hostnames for VIP server lookups |
