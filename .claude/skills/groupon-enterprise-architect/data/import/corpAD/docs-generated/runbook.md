---
service: "corpAD"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `ldaps://corpldap1.<colo>:636` | tcp | Operational monitoring interval (Syseng-managed) | N/A |
| SolarWinds node monitoring | http | Continuous | N/A |

The standard Groupon `/status.json` health endpoint is disabled for corpAD (`status_endpoint.disabled: true` in `.service.yml`). Health is monitored via SolarWinds:
`https://uschi1vpwsw02.group.on/Orion/NetPerfMon/Resources/NodeSearchResults.aspx?Property=Caption&SearchText=adc&ResourceID=4&AccountID=Guest`

## Monitoring

### Metrics

> Operational procedures to be defined by service owner. Metrics are monitored via SolarWinds; application-level metrics (counters, gauges) are not surfaced through a standard Groupon metrics pipeline for this infrastructure service.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| AD / LDAP Node Monitoring | SolarWinds | `https://uschi1vpwsw02.group.on/Orion/NetPerfMon/Resources/NodeSearchResults.aspx?Property=Caption&SearchText=adc&ResourceID=4&AccountID=Guest` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| LDAP VIP unreachable | `corpldap1.<colo>` not responding on port 636 | critical | Page `it-sys-engineering@groupon.pagerduty.com`; verify domain controller health in SolarWinds |
| Workday sync failure | Employee import job fails or times out | critical | Check sync job logs; re-run import manually; escalate to Workday integration owner |
| AD replication failure | Domain controllers not replicating changes | critical | Run `repadmin /replsummary`; investigate per Microsoft AD DS troubleshooting docs |

PagerDuty service: `https://groupon.pagerduty.com/services/PQPJUWN`
Slack channel ID: `CHW6USSV9`

## Common Operations

### Restart Service

Active Directory Domain Services (NTDS) restart:

1. Log in to the affected domain controller via RDP or server management console.
2. Open Services (`services.msc`) or use PowerShell: `Restart-Service -Name NTDS -Force`
3. Verify replication resumes: `repadmin /replsummary`
4. Confirm LDAP connectivity from a client: `ldapsearch -H ldaps://corpldap1.<colo>:636 -x -b "" -s base`

> Full operational procedures are in the Owners Manual: `https://confluence.groupondev.com/display/IT/Group.on+Active+Directory+Owner%27s+Manual`

### Scale Up / Down

1. To add a domain controller: promote a new Windows Server instance using `dcpromo` or the AD DS role installation wizard.
2. To remove a domain controller: demote gracefully using `dcpromo /forceremoval` (only after verifying all FSMO roles are transferred if applicable).
3. Update VIP configuration to include or exclude the new/removed domain controller.

### Database Operations

Active Directory domain database (NTDS.dit) operations:

- **Defragmentation**: Run offline defragmentation with `ntdsutil` during a maintenance window if NTDS.dit grows excessively.
- **Backup**: Use Windows Server Backup to capture System State including NTDS.dit for each domain controller.
- **Authoritative restore**: Required when tombstoned objects (e.g., accidentally deleted accounts) must be recovered. Performed via `ntdsutil` in Directory Services Restore Mode (DSRM).

## Troubleshooting

### LDAP Connectivity Failure

- **Symptoms**: Consuming services (killbill, ARQWeb, openvpn-config) report LDAP bind failures or connection timeouts to `corpldap1.<colo>:636`
- **Cause**: Domain controller is down, VIP misconfiguration, certificate expiry (LDAPS), or network ACL change
- **Resolution**: Check SolarWinds dashboard for node health; verify TCP connectivity to port 636 from the consumer host; check TLS certificate expiry on the domain controller; verify VIP routing

### Workday Sync Failure

- **Symptoms**: New hires do not receive AD accounts; terminated employees retain active accounts beyond expected offboarding window
- **Cause**: Workday API unavailability, credential expiry, network connectivity issue between sync host and Workday
- **Resolution**: Check sync job logs on the Syseng-managed sync host; verify Workday service credentials are valid; re-run sync manually; consult Workday integration documentation

### AD Replication Failure

- **Symptoms**: Changes made on one domain controller are not visible on others; cross-colo directory lookups return stale data
- **Cause**: Network partition between colos, replication partner unavailability, USN rollback, lingering objects
- **Resolution**: Run `repadmin /replsummary` and `repadmin /showrepl` to identify failing replication links; resolve per Microsoft AD DS replication troubleshooting guidance

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | LDAP service down — authentication for internal services blocked | Immediate | Page `it-sys-engineering@groupon.pagerduty.com`; Syseng on-call |
| P2 | Degraded LDAP response — partial failures or elevated latency | 30 min | Notify via Slack `CHW6USSV9`; page PagerDuty if not resolving |
| P3 | Workday sync delayed / stale data | Next business day | Slack `CHW6USSV9`; assign to Syseng team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Workday | Verify sync job completed successfully (check sync job logs) | AD retains last-synced data; manual account management required until sync restored |
| Domain Controllers (per colo) | SolarWinds node monitor + `repadmin /replsummary` | Consumers fail over to other domain controllers behind the same VIP (if multiple DCs are registered) |
