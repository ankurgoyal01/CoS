---
service: "ORR"
title: "Fleet-Wide Monitor Audit"
generated: "2026-03-03"
type: flow
flow_name: "fleet-wide-monitor-audit"
flow_type: batch
trigger: "Operator invokes orr_audit_pd_list_allsvcs.sh with no arguments"
participants:
  - "continuumOrrAuditToolkit"
  - "monitorRecipientsAuditAllServices"
  - "opsConfigRepository"
architecture_ref: "dynamic-hostNotifyAuditByService-monitoring-hostsWithoutServiceAudit-flow"
---

# Fleet-Wide Monitor Audit

## Summary

This flow generates fleet-wide audit reports for host and VIP monitor alert recipients across all production services in a single run. It pulls the latest `ops-config` data, scans every production host YAML file to extract non-pageable alert recipients, then scans the three `lbmon1.<colo>.yml` files to extract non-pageable VIP monitor recipients. The result is four report files (raw text + CSV for hosts, raw text + CSV for VIPs) written to the operator's home directory.

## Trigger

- **Type**: manual
- **Source**: Operator runs `./bin/orr_audit_pd_list_allsvcs.sh` on a Linux host with `ops-config` cloned
- **Frequency**: On demand; typically run at the start of an ORR cycle to produce a baseline report

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `monitorRecipientsAuditAllServices` | Script executor — orchestrates bulk host and VIP audit | `continuumOrrAuditToolkit` |
| `opsConfigRepository` | Source of host YAML files and lbmon VIP monitor files | `opsConfigRepository` |

## Steps

1. **Pull ops-config**: Runs `git pull` in the `ops-config` repo to get the latest host and monitor configuration.
   - From: `monitorRecipientsAuditAllServices`
   - To: `opsConfigRepository`
   - Protocol: git

2. **Find all production live host files**: Searches `ops-config/hosts/` for all YAML files with `environment: production` and `lifecycle: live`; writes the list to a temp file.
   - From: `monitorRecipientsAuditAllServices`
   - To: `opsConfigRepository` (filesystem)
   - Protocol: filesystem find + grep

3. **Audit host notify recipients (bulk)**: For each host YAML file, reads the `notify:` section (between `notify:` and `notify_host:` anchors) and extracts all email addresses. Skips `soc-alert@groupon.com` and `soc-alert-secondary@groupon.com` (known-pageable). Skips `@groupon.pagerduty.com` addresses. Flags all remaining addresses as potentially non-pageable. Resolves the subservice name from `ops_params.subservices`; uses `~UNDEFINED` if missing.
   - From: `monitorRecipientsAuditAllServices`
   - To: `opsConfigRepository` (filesystem)
   - Protocol: filesystem sed/awk/grep

4. **Sort and format host report**: Sorts by service/host name, prepends header row, and writes two output files: `~/orr_audit_pd.report.<timestamp>.hosts` (raw text) and `~/orr_audit_pd.report.<timestamp>.hosts.csv` (comma-separated).
   - From: `monitorRecipientsAuditAllServices`
   - To: `~/orr_audit_pd.report.<timestamp>.hosts*`
   - Protocol: file write

5. **Audit VIP notify recipients (bulk)**: Reads each `lbmon1.<colo>.yml` file (snc1, sac1, dub1). For each VIP monitor block, extracts all notify recipients. Skips `soc-alert@groupon.com`, `soc-alert-secondary@groupon.com`, and `@groupon.pagerduty.com` addresses. Flags remaining addresses as potentially non-pageable.
   - From: `monitorRecipientsAuditAllServices`
   - To: `opsConfigRepository` (local lbmon YAML files)
   - Protocol: filesystem sed/awk/grep

6. **Sort and format VIP report**: Sorts results, prepends header row, and writes `~/orr_audit_pd.report.<timestamp>.vips` (raw text) and `~/orr_audit_pd.report.<timestamp>.vips.csv`.
   - From: `monitorRecipientsAuditAllServices`
   - To: `~/orr_audit_pd.report.<timestamp>.vips*`
   - Protocol: file write

7. **Report completion**: Prints paths to all four generated report files to stdout.
   - From: `monitorRecipientsAuditAllServices`
   - To: stdout

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| ops-config repo not found | `$REPO` empty | `cd` to empty path; `git pull` fails with a shell error |
| SIGINT during host audit | Trap handler | Removes temp host file and report; exits with code 1 |
| SIGINT during VIP audit | Trap handler | Removes temp VIP list and VIP report; exits with code 1 |

## Sequence Diagram

```
Operator -> monitorRecipientsAuditAllServices: ./bin/orr_audit_pd_list_allsvcs.sh
monitorRecipientsAuditAllServices -> opsConfigRepository: git pull
monitorRecipientsAuditAllServices -> opsConfigRepository: find production+live host YAML files
opsConfigRepository --> monitorRecipientsAuditAllServices: host file list
loop for each host YAML
  monitorRecipientsAuditAllServices -> opsConfigRepository: sed notify: section
  opsConfigRepository --> monitorRecipientsAuditAllServices: recipient email addresses
  monitorRecipientsAuditAllServices -> reportfile_hosts: append non-pageable record
end
monitorRecipientsAuditAllServices -> reportfile_hosts: sort + add header + write .csv
monitorRecipientsAuditAllServices -> opsConfigRepository: read lbmon1.snc1.yml
monitorRecipientsAuditAllServices -> opsConfigRepository: read lbmon1.sac1.yml
monitorRecipientsAuditAllServices -> opsConfigRepository: read lbmon1.dub1.yml
loop for each VIP monitor block per colo
  monitorRecipientsAuditAllServices -> reportfile_vips: append non-pageable record
end
monitorRecipientsAuditAllServices -> reportfile_vips: sort + add header + write .csv
monitorRecipientsAuditAllServices --> Operator: 4 report file paths printed to stdout
```

## Related

- Architecture dynamic view: `dynamic-hostNotifyAuditByService-monitoring-hostsWithoutServiceAudit-flow`
- Related flows: [Host Monitor Audit by Service](host-monitor-audit-by-service.md), [VIP Monitor Audit by Service](vip-monitor-audit-by-service.md)
