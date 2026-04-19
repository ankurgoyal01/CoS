---
service: "ORR"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["script-variables", "env-vars"]
---

# Configuration

## Overview

The ORR Audit Toolkit is configured entirely through hardcoded script-level variables and one runtime environment variable (`HOME`). There is no external config store, Helm values file, or Consul integration. Each script defines its own variables at the top of the file. Operators must ensure the `ops-config` repo is cloned under their home directory and that they have intranet/VPN access to Service Portal and LBMS before running any script.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `HOME` | Locates the `ops-config` git clone; report files are written to `~/` | yes | Set by OS | env |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found in codebase.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `lbmon1.snc1.yml` | YAML | Load balancer monitor config for snc1 colo — parsed for VIP SNMP OID and notify recipients |
| `lbmon1.sac1.yml` | YAML | Load balancer monitor config for sac1 colo |
| `lbmon1.dub1.yml` | YAML | Load balancer monitor config for dub1 colo |
| `ops-config/hosts/*.yml` | YAML | Per-host production config — parsed for service mappings, environment, lifecycle, and notify fields |

> Note: `lbmon1.<colo>.yml` files are sourced from the local `ops-config` clone; they are not committed to the ORR repository.

## Script-Level Variables

| Variable | Script | Purpose |
|----------|--------|---------|
| `SP_URL` | `autoscore.sh` | Service Portal base URL — hardcoded to `http://service-portal-vip.snc1` |
| `CURL_OPTS_SP` | `autoscore.sh` | Curl header for Service Portal client identity — `-H GRPN-Client-ID:tdo-coea-automation` |
| `REPO` | `orr_audit_host_notify_by_svc.sh`, `orr_audit_vip_notify_by_svc.sh`, `orr_audit_pd_list_allsvcs.sh` | Path to `ops-config` clone, located by finding `ops-config-push.sh` under `~/` |
| `REPO_HOSTS` | all Bash scripts | Path to `ops-config/hosts` directory |
| `lbmon_filelist` | `orr_audit_vip_notify_by_svc.sh` | Space-separated list of lbmon YAML files — `lbmon1.snc1.yml lbmon1.sac1.yml lbmon1.dub1.yml` |
| `lb_list_snc1` | `orr_audit_vip_notify_by_svc.sh` | List of load balancer hostnames for snc1 colo |
| `lb_list_sac1` | `orr_audit_vip_notify_by_svc.sh` | List of load balancer hostnames for sac1 colo |
| `lb_list_dub1` | `orr_audit_vip_notify_by_svc.sh` | List of load balancer hostnames for dub1 colo |
| `hosts_dir` | `hosts_without_service.py` | Relative path to `ops-config/hosts` from `$HOME` — hardcoded to `repos/ops-config/hosts` |

## Secrets

> No evidence found in codebase. The toolkit uses no secrets — Service Portal access is via intranet/VPN and the `GRPN-Client-ID` header is a client identifier, not a secret.

## Per-Environment Overrides

Scripts target the production environment exclusively. The `ops-config` host YAML filtering uses `environment: production` and `lifecycle: live` predicates to restrict audit scope to live production hosts. There are no dev or staging modes.
