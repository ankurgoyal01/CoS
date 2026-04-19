---
service: "ORR"
title: "Host Monitor Audit by Service"
generated: "2026-03-03"
type: flow
flow_name: "host-monitor-audit-by-service"
flow_type: synchronous
trigger: "Operator invokes orr_audit_host_notify_by_svc.sh <svc_name> on a Linux host"
participants:
  - "continuumOrrAuditToolkit"
  - "hostNotifyAuditByService"
  - "servicePortal"
  - "opsConfigRepository"
architecture_ref: "dynamic-hostNotifyAuditByService-monitoring-hostsWithoutServiceAudit-flow"
---

# Host Monitor Audit by Service

## Summary

This flow audits all on-prem production host-level monitor notify recipients for a single named service. The script validates the service exists in Service Portal, pulls the latest `ops-config` data, finds all production hosts assigned to that service, and for each host evaluates three notify sections (`notify`, `notify_under_monitors`, `notify_host`) against pageability rules. Results are printed to stdout and saved as a timestamped report file.

## Trigger

- **Type**: manual
- **Source**: Operator runs `./bin/orr_audit_host_notify_by_svc.sh <svc_name>` on `dev1.snc1` or equivalent Linux host
- **Frequency**: On demand, as part of ORR review cycles

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `hostNotifyAuditByService` | Script executor — orchestrates all steps | `continuumOrrAuditToolkit` |
| `servicePortal` | Validates the target service name is registered | `servicePortal` |
| `opsConfigRepository` | Source of host YAML configuration files | `opsConfigRepository` |

## Steps

1. **Validate Linux platform**: Checks `uname -s == Linux`; exits with message if not met.
   - From: `hostNotifyAuditByService`
   - To: OS
   - Protocol: shell

2. **Check script version**: Fetches script header from `https://raw.github.groupondev.com/SOC/ORR/master/bin/orr_audit_host_notify_by_svc.sh`; exits if local version is outdated.
   - From: `hostNotifyAuditByService`
   - To: `rawGithubContent`
   - Protocol: HTTPS GET

3. **Validate service name**: Issues `curl -ILs http://service-portal-vip.snc1/services/<svc_name>` and confirms HTTP 200 response.
   - From: `hostNotifyAuditByService`
   - To: `servicePortal`
   - Protocol: HTTP HEAD

4. **Pull ops-config**: Locates `ops-config` repo under `~/` and runs `git pull` to ensure fresh configuration data.
   - From: `hostNotifyAuditByService`
   - To: `opsConfigRepository`
   - Protocol: git

5. **Find production hosts for service**: Searches `ops-config/hosts/` for YAML files matching `- <svc_name>::` with `environment: production` and `lifecycle: live`; writes matching hostnames to a temp file.
   - From: `hostNotifyAuditByService`
   - To: `opsConfigRepository` (filesystem)
   - Protocol: filesystem grep

6. **Audit notify sections per host**: For each host, reads `notify:`, `notify_under_monitors:`, and `notify_host:` sections from the host YAML file; evaluates each alert email against pageability rules (is it `@groupon.pagerduty.com`, `soc-alert@groupon.com`, or `soc-alert-secondary@groupon.com`).
   - From: `hostNotifyAuditByService`
   - To: `opsConfigRepository` (filesystem)
   - Protocol: filesystem sed/awk

7. **Emit audit result per recipient**: For each recipient, prints PASS or Warning/Notice messages to stdout and to the report file.
   - From: `hostNotifyAuditByService`
   - To: `~/orr_audit_pd.report.hostbysvc.<svc>.<timestamp>.<pid>`
   - Protocol: file write

8. **Report output path**: Prints path to saved report file and cleans up temp files.
   - From: `hostNotifyAuditByService`
   - To: stdout

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Not running on Linux | `uname -s != Linux` check | Script exits with code 1 and message |
| Service name not registered in Service Portal | HTTP 200 check fails | Script exits with code 2 and remediation message |
| ops-config repo not found | `$REPO` variable empty | Script sends SIGTERM to parent PID; exits with code 3 |
| No production hosts found for service | Empty temp host file | Script sends SIGTERM; exits with "service might already be migrated to cloud" message |
| SIGINT/SIGTERM during execution | Trap handler | Removes temp file `$HOSTLIST_TMP` and exits with code 3 |

## Sequence Diagram

```
Operator -> hostNotifyAuditByService: ./orr_audit_host_notify_by_svc.sh <svc_name>
hostNotifyAuditByService -> OS: uname -s (platform check)
hostNotifyAuditByService -> rawGithubContent: GET script version header
hostNotifyAuditByService -> servicePortal: HEAD /services/<svc_name>
servicePortal --> hostNotifyAuditByService: HTTP 200 OK
hostNotifyAuditByService -> opsConfigRepository: git pull
hostNotifyAuditByService -> opsConfigRepository: grep production+live hosts for <svc_name>
opsConfigRepository --> hostNotifyAuditByService: list of host YAML filenames
loop for each host
  hostNotifyAuditByService -> opsConfigRepository: sed/awk notify: section
  hostNotifyAuditByService -> opsConfigRepository: sed/awk notify_under_monitors: section
  hostNotifyAuditByService -> opsConfigRepository: sed/awk notify_host: section
  opsConfigRepository --> hostNotifyAuditByService: alert recipient email addresses
  hostNotifyAuditByService -> stdout+reportfile: PASS / WARN / NOTICE per recipient
end
hostNotifyAuditByService --> Operator: Audit report at ~/orr_audit_pd.report.hostbysvc.*
```

## Related

- Architecture dynamic view: `dynamic-hostNotifyAuditByService-monitoring-hostsWithoutServiceAudit-flow`
- Related flows: [VIP Monitor Audit by Service](vip-monitor-audit-by-service.md), [Fleet-Wide Monitor Audit](fleet-wide-monitor-audit.md)
