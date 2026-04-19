---
service: "ORR"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

> Not applicable — the ORR Audit Toolkit is a CLI tool with no running service instance. There are no HTTP health endpoints or liveness probes.

## Monitoring

### Metrics

> No evidence found in codebase. The toolkit generates flat file reports; no metrics are emitted to Grafana, Datadog, or any monitoring backend.

### Dashboards

> No evidence found in codebase.

### Alerts

> No evidence found in codebase. Alert monitoring hygiene for other services is the output of this toolkit, but the toolkit itself has no alerts.

## Common Operations

### Run a Host Monitor Audit for a Specific Service

```bash
# On dev1.snc1 (or any Linux host with ops-config clone and VPN access)
cd <local ORR repo>
./bin/orr_audit_host_notify_by_svc.sh <svc_name>
# Reports written to ~/orr_audit_pd.report.hostbysvc.<svc_name>.<timestamp>.<pid>
```

### Run a VIP Monitor Audit for a Specific Service

```bash
cd <local ORR repo>
./bin/orr_audit_vip_notify_by_svc.sh <svc_name>
# Reports written to ~/orr_audit_pd.report.vipbysvc.<svc_name>.<timestamp>.<pid>
# and ~/orr_audit_pd.report.vipbysvc.<svc_name>.<timestamp>.<pid>.csv
```

### Run Fleet-Wide Host and VIP Monitor Audit

```bash
cd <local ORR repo>
./bin/orr_audit_pd_list_allsvcs.sh
# 4 report files generated under ~/: .hosts, .hosts.csv, .vips, .vips.csv
# Search by service: cat ~/orr_audit_pd.report.<timestamp>.hosts | grep svc_name
# Find undefined hosts: grep UNDEFINED ~/orr_audit_pd.report.<timestamp>.hosts
```

### Detect Orphaned Hosts (No Service Mapping)

```bash
cd hosts_without_service_project/
source <environment-name>/bin/activate
python hosts_without_service.py
# Results in /tmp/hosts_without_service.txt
```

### Identify Services with Autoscoring Disabled

```bash
cd <local ORR repo>
./autoscore.sh
# Lists all Live services where autoscoring_enabled == false
```

### Update Scripts to Latest Version

```bash
cd <local ORR repo>
git pull
```

### Scale Up / Down

> Not applicable — CLI toolkit with no server component.

### Database Operations

> Not applicable — no database owned by this toolkit.

## Troubleshooting

### Script Exits: "ops-config repo not found"
- **Symptoms**: Script prints "unable to locate ops-config repo, exit!" and terminates
- **Cause**: `ops-config` repository is not cloned under the operator's home directory, or `ops-config-push.sh` is not present in the clone
- **Resolution**: Clone `ops-config` to `~/ops-config` (or any subdirectory of `~/`); ensure `ops-config-push.sh` exists in the clone root

### Script Exits: Service Name Not Found in Service Portal
- **Symptoms**: Script prints "Please make sure the service name as argument is correct" with exit code 2
- **Cause**: The service name argument does not match a registered service in Service Portal, or the host running the script cannot reach `http://service-portal-vip.snc1`
- **Resolution**: Verify the service name at `https://services.groupondev.com/services/<svc_name>`; confirm VPN or intranet access is active

### Script Exits: "please run this script on Linux platform"
- **Symptoms**: Script prints the Linux platform message and exits immediately
- **Cause**: Script is being run on macOS or Windows
- **Resolution**: SSH to `dev1.snc1` or another on-prem Linux host and run from there

### Script Exits: "please install jq"
- **Symptoms**: Script detects `jq` is missing
- **Cause**: `jq` is not installed on the operator's host
- **Resolution**: Install via `brew install jq` (macOS) or `sudo yum --enablerepo=repo-vip-epel install jq` (CentOS)

### Script Reports Outdated Version
- **Symptoms**: Script prints "please update this script to the latest version: cd ... git pull"
- **Cause**: Local script version is older than the version in `SOC/ORR` master branch
- **Resolution**: Run `git pull` in the local ORR repo directory

### VIP Audit Shows No VIPs Found
- **Symptoms**: `orr_audit_vip_notify_by_svc.sh` prints "no relevant VIP is found for the service"
- **Cause**: Service has been fully migrated to cloud/AWS — no on-prem hosts in `ops-config` for this service
- **Resolution**: Use `https://vipstatus.groupondev.com` to verify VIP status; confirm service is not cloud-only

### hosts_without_service.py Fails on YAML Parse
- **Symptoms**: Python script raises `yaml.YAMLError` or `KeyError`
- **Cause**: A malformed host YAML file in `ops-config/hosts`, or `ops_params.subservices` key path differs from expected structure
- **Resolution**: Identify the offending file from the traceback and check its format against a known-good host YAML; report to ops-config maintainers if corrupt

## Incident Response

> Not applicable — the ORR Audit Toolkit is not a production service and has no SLA. There are no on-call escalation paths for the toolkit itself.

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | N/A — not a production service | N/A | SOC team |
| P2 | N/A | N/A | SOC team |
| P3 | N/A | N/A | SOC team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `ops-config` repo | `git pull` succeeds; `ops-config-push.sh` locatable | Scripts exit early; operator must resolve clone |
| `servicePortal` (`http://service-portal-vip.snc1`) | HTTP 200 on `/services/<svc_name>` before audit | Scripts exit with exit code 2; check VPN access |
| `lbmsApi` (`http://lbmsv2-vip.snc1`) | VIP SNMP OID lookup returns non-empty result | Individual VIPs are skipped with a log message; audit continues |
| `rawGithubContent` (`https://raw.github.groupondev.com`) | curl returns non-empty content | Individual load balancer node data skipped; VIP resolution may be incomplete |
