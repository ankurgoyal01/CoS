---
service: "ORR"
title: "VIP Monitor Audit by Service"
generated: "2026-03-03"
type: flow
flow_name: "vip-monitor-audit-by-service"
flow_type: synchronous
trigger: "Operator invokes orr_audit_vip_notify_by_svc.sh <svc_name> on a Linux host"
participants:
  - "continuumOrrAuditToolkit"
  - "vipNotifyAuditByService"
  - "servicePortal"
  - "opsConfigRepository"
  - "rawGithubContent"
  - "lbmsApi"
architecture_ref: "dynamic-hostNotifyAuditByService-monitoring-hostsWithoutServiceAudit-flow"
---

# VIP Monitor Audit by Service

## Summary

This flow audits VIP-level monitor notify recipients for a single named service. It first finds all on-prem production hosts for the service, then traverses the NetOps load balancer configs to discover which VIPs (virtual IPs) route traffic to those hosts. For each VIP it retrieves the SNMP OID from LBMS, locates the VIP's monitor block in the local `lbmon1.<colo>.yml` file, and evaluates the notify recipients against tier-specific pageability rules (tier-1 vs tier-2 vs vs:single VIPs). Reports are written to stdout and saved in raw text and CSV formats.

## Trigger

- **Type**: manual
- **Source**: Operator runs `./bin/orr_audit_vip_notify_by_svc.sh <svc_name>` on `dev1.snc1` or equivalent Linux host
- **Frequency**: On demand, as part of ORR review cycles

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `vipNotifyAuditByService` | Script executor — orchestrates all steps | `continuumOrrAuditToolkit` |
| `servicePortal` | Validates the target service name is registered | `servicePortal` |
| `opsConfigRepository` | Source of host YAML files and lbmon config files | `opsConfigRepository` |
| `rawGithubContent` | Provides NetOps load balancer config for VIP topology traversal | `rawGithubContent` |
| `lbmsApi` | Provides VIP SNMP OID for lbmon file correlation | `lbmsApi` |

## Steps

1. **Validate Linux platform and jq**: Checks `uname -s == Linux` and `which jq`; exits if either fails.
   - From: `vipNotifyAuditByService`
   - To: OS
   - Protocol: shell

2. **Check script version**: Fetches script header from `https://raw.github.groupondev.com/SOC/ORR/master/bin/orr_audit_vip_notify_by_svc.sh`; exits if outdated.
   - From: `vipNotifyAuditByService`
   - To: `rawGithubContent`
   - Protocol: HTTPS GET

3. **Validate service name**: Confirms service is registered in Service Portal via HTTP 200 check.
   - From: `vipNotifyAuditByService`
   - To: `servicePortal`
   - Protocol: HTTP HEAD

4. **Pull ops-config**: Runs `git pull` in the `ops-config` clone.
   - From: `vipNotifyAuditByService`
   - To: `opsConfigRepository`
   - Protocol: git

5. **Find production hosts for service**: Searches `ops-config/hosts/` for matching host YAML files (`- <svc_name>::`, `environment: production`, `lifecycle: live`).
   - From: `vipNotifyAuditByService`
   - To: `opsConfigRepository` (filesystem)
   - Protocol: filesystem grep

6. **Resolve VIPs from hosts**: For each production host, queries the load balancer configs at `https://raw.github.groupondev.com/prod-netops/netops_oxidized_<colo>_config/master/load_balancers/<lb_name>` to traverse: server → service group (`bind serviceGroup`) → VServer (`bind lb vserver`) → VIP IP. Resolves VIP IPs using `dig -x` where needed. Deduplicates the VIP list.
   - From: `vipNotifyAuditByService`
   - To: `rawGithubContent`
   - Protocol: HTTPS GET

7. **Look up SNMP OID per VIP**: For each discovered VIP, calls `GET http://lbmsv2-vip.snc1/v2/vip_snmp_oids?vip_name=<vip>&colo=<colo>` to retrieve the SNMP OID.
   - From: `vipNotifyAuditByService`
   - To: `lbmsApi`
   - Protocol: HTTP REST

8. **Correlate VIP with lbmon monitor block**: Uses the SNMP OID to locate the corresponding monitor entry in `lbmon1.<colo>.yml` and extracts all notify recipients from the `notify:` block.
   - From: `vipNotifyAuditByService`
   - To: `opsConfigRepository` (local lbmon YAML)
   - Protocol: filesystem sed/grep

9. **Evaluate notify recipients by VIP tier**: Applies tier-specific rules:
   - `vs:app:` and `-tier2-` VIPs: requires service team PagerDuty address + `soc-alert@groupon.com`
   - `vs:routing:` and `-tier1-` VIPs: only `soc-alert@groupon.com` required
   - `vs:single:` VIPs: requires both service team PagerDuty and `soc-alert@groupon.com`
   - From: `vipNotifyAuditByService`
   - To: in-memory logic
   - Protocol: Bash conditionals

10. **Write audit report**: Formats and saves findings to `~/orr_audit_pd.report.vipbysvc.<svc>.<timestamp>.<pid>` (raw text) and `.csv`, then prints to stdout.
    - From: `vipNotifyAuditByService`
    - To: `~/orr_audit_pd.report.vipbysvc.*`
    - Protocol: file write

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Not running on Linux | `uname -s != Linux` check | Exit code 1 |
| jq not installed | `which jq` check | Exit code 1 with install instructions |
| Service not in Service Portal | HTTP 200 check fails | Exit code 2 |
| ops-config repo not found | `$REPO` empty | SIGTERM to parent PID; exit code 3 |
| No production hosts found | Empty host temp file | Exit with "service may be cloud-only" message |
| No VIPs found for hosts | Empty VIP temp file | Exit with "use vipstatus.groupondev.com to verify" message |
| SNMP OID not found for VIP | Empty jq result | Skip VIP with log message; continue processing |
| Unknown colo for server/VIP | colo not snc1/sac1/dub1 | Skip with log message; continue |
| SIGINT during execution | Trap handler | Remove temp files (`$HOSTLIST_TMP`, `$SGLIST_TMP`, `$VIPLIST_TMP`, `$ORR_AUDIT_REPORT_TMP`) and exit code 3 |

## Sequence Diagram

```
Operator -> vipNotifyAuditByService: ./orr_audit_vip_notify_by_svc.sh <svc_name>
vipNotifyAuditByService -> servicePortal: HEAD /services/<svc_name>
servicePortal --> vipNotifyAuditByService: HTTP 200 OK
vipNotifyAuditByService -> opsConfigRepository: git pull
vipNotifyAuditByService -> opsConfigRepository: grep production+live hosts for <svc_name>
opsConfigRepository --> vipNotifyAuditByService: list of host YAML filenames
loop for each host
  vipNotifyAuditByService -> rawGithubContent: GET lb config for <host_colo>
  rawGithubContent --> vipNotifyAuditByService: bind serviceGroup entries
  loop for each service group
    vipNotifyAuditByService -> rawGithubContent: GET lb config for service group
    rawGithubContent --> vipNotifyAuditByService: bind lb vserver entries + VIP IPs
  end
end
loop for each VIP
  vipNotifyAuditByService -> lbmsApi: GET /v2/vip_snmp_oids?vip_name=<vip>&colo=<colo>
  lbmsApi --> vipNotifyAuditByService: snmp_oid
  vipNotifyAuditByService -> opsConfigRepository: sed lbmon1.<colo>.yml for snmp_oid notify block
  opsConfigRepository --> vipNotifyAuditByService: notify recipient email list
  vipNotifyAuditByService -> reportfile: WARN/NOTICE per recipient and VIP tier
end
vipNotifyAuditByService --> Operator: Audit report at ~/orr_audit_pd.report.vipbysvc.*
```

## Related

- Architecture dynamic view: `dynamic-hostNotifyAuditByService-monitoring-hostsWithoutServiceAudit-flow`
- Related flows: [Host Monitor Audit by Service](host-monitor-audit-by-service.md), [Fleet-Wide Monitor Audit](fleet-wide-monitor-audit.md)
