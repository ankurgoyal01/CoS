---
service: "external_dns_tools"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `named-checkconf /usr/local/etc/named.conf` | exec (run on each BIND host post-deploy) | Per-deploy | N/A |
| `dig +noall +answer @127.0.0.1 <record>` | exec (QA assertions in Ansible playbook) | Per-deploy | N/A |
| Akamai alert monitoring (zone transfer check) | Akamai-managed polling | ~6-9 minutes alert delay | N/A |
| `dig SOA <zone>` serial check | manual exec (operator-run during deploy) | Per change, ~15 min before deploy | N/A |

## Monitoring

### Metrics

> No evidence found in codebase for application-level metrics instrumentation. BIND server health is monitored through Akamai alerts and the Wavefront dashboard.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Public NS dashboard | Wavefront | `https://groupon.wavefront.com/dashboard/public-ns` |
| Akamai FastDNS alerts | Akamai Luna | `https://control.akamai.com` → Configure → Alerts → FastDNS |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| `syseng_fastdns_expired_zone` | Akamai ZTAs cannot contact or zone-transfer BIND masters for longer than the SOA expiration interval | warning | Check BIND master availability; verify firewall allows Akamai ZTA IPs; verify correct master IP in Akamai Luna config |
| `syseng_fastdns_failed_zonetransfer` | All ZTAs fail zone transfer — Akamai may be serving stale DNS | critical | Immediately check BIND master availability; verify firewall rules for all Akamai ZTA IP ranges; check named daemon status; escalate to `groupon-support@akamai.com` if unresolved |
| `syseng_fastdns_soa_ahead` | Akamai ZTA detects a BIND master advertising a lower SOA serial than what ZTA already holds | warning | Check zone SOA serial on master using `dig SOA <zone> +short`; compare to `ops-ns_public_config` repo serial; republish zone with incremented serial if necessary |

Alert notifications are sent to:
- Full body: `service-engineering-alerts@groupon.com`
- PagerDuty pager: `sre-alert-allhours@groupon.com`
- PagerDuty service: `https://groupon.pagerduty.com/services/PPF3JXH`

## Common Operations

### Restart Service

To restart the BIND daemon on a BIND master:

```
sudo systemctl start named
```

Or via the legacy init script used in Ansible playbooks:
```
sudo /usr/local/etc/init.d/named restart
```

After restart, verify with:
```
/usr/local/sbin/named-checkconf /usr/local/etc/named.conf
dig +noall +answer @127.0.0.1 groupon.com
```

### Scale Up / Down

Adding capacity must only be performed by Systems Engineering. Process:
1. Procure new EC2 instances
2. Roll hosts using standard Ansible playbooks
3. Update Akamai EdgeDNS configuration on `control.akamai.com` to include new host IPs as additional zone transfer sources

Contact SRE on-call if capacity addition is urgently required.

### Database Operations

Zone file changes are made via GitHub PR to `ops-ns_public_config`. After merge:
1. Verify the SOA serial in the change PR is exactly 1 greater than the current production serial (check with `dig SOA <record>`)
2. Verify the rollback PR SOA serial is exactly 1 greater than the change PR serial
3. Resolve any merge conflicts before proceeding
4. Deploy using `dns_deploy.py` per the standard SOP: Confluence page `https://groupondev.atlassian.net/wiki/spaces/IT/pages/80509337735/Deploy+public+DNS`

## Troubleshooting

### Zone SOA Ahead Alert

- **Symptoms**: Akamai alert `syseng_fastdns_soa_ahead` fires; Akamai ZTAs refuse to zone-transfer because master advertises a lower SOA serial than ZTA already has
- **Cause**: BIND master was reloaded or restored with a zone file whose SOA serial is lower than what Akamai's ZTAs previously received (e.g., after a failed rollback or incorrect serial assignment)
- **Resolution**:
  1. From any production BIND EC2 instance, run: `for i in 50.115.209.8 50.115.209.102 usc5.akam.net; do echo $i; dig @${i} SOA groupon.com +short; done`
  2. Compare the serial in the output to the serial in `ops-ns_public_config` master branch for that zone file
  3. If the SOA serial on the master branch is lower than what Akamai holds, increment the serial in `ops-ns_public_config` via a new PR and redeploy
  4. If alert persists, escalate to `groupon-support@akamai.com` cc `infrastructure-engineering@groupon.com` and `syseng@groupon.com`

### Failed Zone Transfer

- **Symptoms**: `syseng_fastdns_failed_zonetransfer` alert fires; Akamai may serve stale DNS records
- **Cause**: BIND master unreachable (EC2 down, networking issue, or firewall blocking Akamai ZTA IPs)
- **Resolution**:
  1. Verify BIND master EC2 instances are running and `named` daemon is active
  2. Check that firewall rules permit all current Akamai ZTA IPs (list available on `control.akamai.com`)
  3. Verify the correct master IP addresses are configured in Akamai EdgeDNS configuration
  4. If masters are healthy and firewall is correct, escalate to Akamai support

### ops-config push changes failed

- **Symptoms**: `dns_deploy.py` fails at the `ops-config push changes` Ansible task; error message indicates OCQ push failure
- **Cause**: Stale local `ops-config` repo state or concurrent modification
- **Resolution**:
  1. Navigate to the ops-config working directory: `cd /var/groupon/$USER/ops-config`
  2. Run: `git status; git pull --rebase; ./bin/ops-config-queue -v; git push --tags`
  3. Re-run `dns_deploy.py` and select the previously-created hostclass tag using option `a`
  4. Deploy using option `e` (or `c`/`d` for test-only or production-only)

### Verifying Domain Ownership for Escalation

To determine which team owns an alert domain:
```
dig SOA <domain> +short | cut -d ' ' -f 2
```
- If hostmaster address is `hostmaster.groupon.com`: escalate to Service Engineering (`service-engineering@groupon.com`)
- If hostmaster address is `domains.groupon.de`: escalate to SOC Team

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Failed zone transfer — potential for stale DNS propagation | Immediate | Infrastructure Engineering (PagerDuty: `dns@groupon.pagerduty.com` / `https://groupon.pagerduty.com/services/PPF3JXH`) |
| P2 | Expired zone or SOA ahead — DNS changes not propagating | 30 min | Infrastructure Engineering on-call |
| P3 | Deploy tooling error (non-urgent change blocked) | Next business day | Infrastructure Engineering (`infrastructure-engineering@groupon.com`) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Akamai EdgeDNS | Monitor `syseng_fastdns_failed_zonetransfer` alert; check Luna dashboard | Akamai continues serving previously-cached DNS records indefinitely |
| BIND masters (EC2) | `sudo systemctl status named`; `dig @<master-ip> SOA groupon.com` | Remaining masters continue serving zone transfers; capacity add required if multiple fail |
| ops-config / config service | Deploy tool polls `http://config.<dc>/host/<host>` and reports propagation status | Roll back hostclass tag to prior known-good tag using rollback PR and redeploy |
