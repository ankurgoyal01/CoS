---
service: "momo-config"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| SNMP at `127.0.0.1:8162` (community `public`) | SNMP | Configured externally | Not evidenced |
| `/var/log/ecelerity/paniclog.ec` | Log-based | Continuous | N/A |
| Ecelerity control channel (`control_listener.conf`) | TCP | On-demand (`eccmd` / `ec_console`) | Not evidenced |
| Adaptive delivery module suspension state (LevelDB) | Internal | Per delivery cycle | N/A |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Outbound delivery rate | counter | Messages successfully delivered per binding/domain | Operational procedure to be defined by service owner |
| In-band bounce rate | counter | Permanent and transient SMTP failures per binding/domain | Operational procedure to be defined by service owner |
| OOB bounce count | counter | Out-of-band DSN messages received and logged on inbound cluster | Operational procedure to be defined by service owner |
| FBL complaint count | counter | FBL (ARF) reports received on inbound cluster | Operational procedure to be defined by service owner |
| Adaptive suspension events | gauge | Number of active per-binding/domain suspensions triggered by rejection rate threshold | `adaptive_rejection_rate_suspension_percentage` = 50% (email/trans), 25% (smtp) |
| Memory utilization | gauge | Ecelerity process memory as percentage of system | Alert at `Memory_HWM = 95%` |
| Queue depth | gauge | `max_resident_messages` ceiling indicates queue pressure | Alert near 256000 (email/trans), 65536 (inbound/smtp) |

Metrics are published to `metricsStack` via the Ecelerity metrics pipeline.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| MTA Delivery Metrics | Operational procedure to be defined by service owner | — |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High adaptive suspension rate | Multiple binding/domain pairs suspended simultaneously | critical | Check delivery logs in `/var/log/ecelerity/delivery.ec`; review ISP feedback; adjust `adaptive_domains.conf` or `adaptive_sweep.conf` |
| Memory high-water mark | Ecelerity `Memory_HWM = 95%` reached | critical | Reduce injection rate; check queue depth; consider restarting after draining |
| Panic log errors | Non-empty entries in `/var/log/ecelerity/paniclog.ec` | warning | Review panic log; correlate with delivery or policy changes |
| High in-band bounce rate | Elevated entries in `/var/log/ecelerity/inband_bounce.ec` | warning | Check binding group health; review domain profiles; verify recipient list hygiene |
| FBL complaint spike | Elevated entries in `fbl_csv` / `fbl_jlog` | warning | Review campaign sending patterns; check for list hygiene issues; notify email deliverability team |

## Common Operations

### Restart Service

Operational procedures to be defined by service owner. Ecelerity can be restarted via the system service manager (`systemctl restart ecelerity` or equivalent). The on-disk spool at `/var/spool/ecelerity` ensures queued messages survive restarts. The adaptive LevelDB backstore at `/opt/msys/leveldb/adaptive.leveldb` also persists across restarts.

### Scale Up / Down

Operational procedures to be defined by service owner. Adding or removing cluster nodes is managed externally; node addresses must be reflected in DNS zone definitions managed by `continuumMtaDnsService`. Per-node connection limits are set via `Server_Max_Outbound_Connections = 20000` and `Max_Outbound_Connections = 32` in each cluster's `ecelerity.conf`.

### Database Operations

The LevelDB adaptive backstore is managed automatically by the Ecelerity adaptive module. To reset adaptive state for a binding/domain pair, use the Ecelerity control channel (`ec_console` / `eccmd`) — `adaptive reset <binding> <domain>`. No SQL migrations apply; the spool and backstore are filesystem-based.

## Troubleshooting

### High Adaptive Suspension Rate

- **Symptoms**: Delivery rate drops sharply; multiple `adaptive_suspension` events in delivery logs; `binding_domain` pairs appear suspended
- **Cause**: Remote ISP rejection rate exceeded `adaptive_rejection_rate_suspension_percentage` (50% for email/trans, 25% for smtp)
- **Resolution**: Check `/var/log/ecelerity/delivery.ec` for rejection patterns; verify domain-specific rules in `domains.conf`; review `adaptive_sweep.conf` and `adaptive_domains.conf` for the affected domain; check ISP postmaster pages for temporary blocks; wait for suspension to expire (1 hour) or manually reset via `ec_console`

### Inbound FBL / Bounce Messages Not Being Classified

- **Symptoms**: Messages arriving on inbound response domains are rejected with `552 Denied by policy`; FBL or bounce logs are empty
- **Cause**: Domain not listed in `groupon_config.msg_types`; malformed MIME structure in DSN or ARF report
- **Resolution**: Verify the destination domain is declared in `Relay_Domains` or `Bounce_Domains` in `ecelerity.conf`; confirm domain entry exists in `groupon_config.msg_types`; check `policy.log` for classification errors; enable `groupon_config.log_samples = true` to capture raw message samples to `/var/log/ecelerity/inbound_samples/`

### DKIM Signing Failures

- **Symptoms**: Messages delivered without DKIM signature; receiving ISPs report DKIM=none
- **Cause**: `opendkim` module misconfiguration; key file missing at `/opt/msys/ecelerity/etc/conf/default/includes/dkim_certificates/%{s}.key`; selector `s2048d20190430` not published in DNS
- **Resolution**: Verify key file exists and is readable by `ecuser`; confirm DNS TXT record for `s2048d20190430._domainkey.<domain>` is published; check `paniclog.ec` for OpenDKIM module errors; reload scriptlet after key deployment

### Messages Stuck in Spool / Not Draining

- **Symptoms**: Queue depth increasing; `/var/spool/ecelerity` growing; delivery rate low
- **Cause**: Remote MX unreachable; binding/domain suspended; memory high-water mark reached; `Disk_Queue_Drain_Rate = 100` throttle
- **Resolution**: Check adaptive suspension state via `ec_console`; verify DNS resolution for recipient domain; monitor memory utilization; check `Host_Failure_Retry = 120` for recently failed hosts; verify `Message_Expiration` has not been reached (79201s email, 259200s trans)

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | All outbound mail delivery stopped or all inbound response processing halted | Immediate | MTA Operations team |
| P2 | Significant delivery degradation (multiple ISPs suspended); FBL/bounce processing failure | 30 min | MTA Operations team |
| P3 | Single domain throttle or minor bounce rate increase | Next business day | Email Deliverability team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `loggingStack` | Check log file sizes and modification times in `/var/log/ecelerity/`; verify log pipeline is consuming | Log writes buffer to disk; no data loss if log pipeline temporarily unavailable |
| `metricsStack` | Check Ecelerity metrics emission; verify metric values visible in monitoring tool | Metrics gap; delivery continues unaffected |
| Remote recipient MX servers | Monitor delivery rate and bounce rate per domain; check adaptive suspension events | Adaptive delivery module suspends and retries; messages held in spool up to `Message_Expiration` |
| DNS resolver | Attempt `msys.dnsLookup` from `ec_console`; verify DNS resolution for key recipient domains | Delivery deferred for affected domains |
