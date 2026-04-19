---
service: "ORR"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["cli"]
auth_mechanisms: ["none"]
---

# API Surface

## Overview

The ORR Audit Toolkit exposes no HTTP or RPC API. Its interface is a set of CLI scripts invoked directly by operators on a Linux host. Each script accepts positional arguments (service name) and writes output to stdout and to timestamped report files in the operator's home directory.

## CLI Tools

### Host and VIP Audit Scripts

| Script | Invocation | Argument | Purpose |
|--------|-----------|----------|---------|
| `orr_audit_host_notify_by_svc.sh` | `./bin/orr_audit_host_notify_by_svc.sh <svc_name>` | Service name registered in Service Portal | Audits host-level monitor notify recipients for the named service |
| `orr_audit_vip_notify_by_svc.sh` | `./bin/orr_audit_vip_notify_by_svc.sh <svc_name>` | Service name registered in Service Portal | Audits VIP-level monitor notify recipients for the named service |
| `orr_audit_pd_list_allsvcs.sh` | `./bin/orr_audit_pd_list_allsvcs.sh` | None | Runs fleet-wide host and VIP monitor recipient audit across all production services |
| `hosts_without_service.py` | `python hosts_without_service.py` | None | Scans all `ops-config/hosts` YAML files and reports hosts missing `subservices` mapping |
| `autoscore.sh` | `./autoscore.sh` | None | Lists all Live services that have autoscoring disabled in Service Portal |

### Multiple-service loop pattern

```bash
for svc in svc1 svc2 svc3; do
  ./bin/orr_audit_host_notify_by_svc.sh $svc
done
```

## Output Formats

| Script | Output Files | Format |
|--------|-------------|--------|
| `orr_audit_host_notify_by_svc.sh` | `~/orr_audit_pd.report.hostbysvc.<svc>.<timestamp>.<pid>` | Raw text |
| `orr_audit_vip_notify_by_svc.sh` | `~/orr_audit_pd.report.vipbysvc.<svc>.<timestamp>.<pid>` | Raw text + `.csv` |
| `orr_audit_pd_list_allsvcs.sh` | `~/orr_audit_pd.report.<timestamp>.hosts`, `~/orr_audit_pd.report.<timestamp>.vips` | Raw text + `.csv` each |
| `hosts_without_service.py` | `/tmp/hosts_without_service.txt` | Plain text list |

## Audit Comment Codes

| Code | Meaning |
|------|---------|
| `WARN:double_check_if_the_email_address_to_service_team_is_pageable` | Alert email is not a `@groupon.pagerduty.com` address — pageability must be verified |
| `WARN:need_to_add_service_team_as_PagerDuty_recipient_for_tier2_VIP` | Tier-2 VIP only has SOC recipient, service team PagerDuty recipient missing |
| `WARN:PagerDuty_recipient_not_configured_yet_atleast_add_soc-alert@_as_recipient` | No PagerDuty recipient configured at all |
| `WARN:need_to_add_soc-alert@_as_PagerDuty_recipient_too` | Service team PagerDuty address present but `soc-alert@groupon.com` missing |
| `NOTICE:consider_adding_service_team_as_PagerDuty_recipient_too` | Only SOC is configured; service team recipient recommended |
| `NOTICE:normally_only_soc-alert@_is_required_for_tier1_VIP` | Non-SOC recipient on a tier-1 VIP (informational) |

## Request/Response Patterns

> Not applicable — this service exposes no HTTP or RPC interface.

## Rate Limits

> Not applicable — CLI toolkit with no server component.

## Versioning

Scripts perform a self-version check on startup by fetching the current version header from `https://raw.github.groupondev.com/SOC/ORR/master/bin/<script>`. If the remote version is newer, the script exits with an instruction to `git pull`.

## OpenAPI / Schema References

> No evidence found in codebase.
