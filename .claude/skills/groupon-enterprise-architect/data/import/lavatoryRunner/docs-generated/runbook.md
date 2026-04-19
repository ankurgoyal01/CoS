---
service: "lavatoryRunner"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Splunk query: `index=prod_ops sourcetype=lavatory` | log-based | Per cron run | N/A |
| Wavefront dashboard: `https://groupon.wavefront.com/dashboard/lavatory` | metrics | Per cron run | N/A |
| Artifactory API ping: `GET /artifactory/api/system/ping` (used in integration tests) | http | On-demand | 50 seconds (10 x 5s retries) |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `removed_files_count` | counter | Number of artifact files deleted per repository per run | No evidence found in codebase |
| `removed_bytes_count` | counter | Total bytes reclaimed per repository per run | No evidence found in codebase |
| `removed_bytes_percent` | gauge | Percentage of repository storage reclaimed | No evidence found in codebase |
| `removed_files_percent` | gauge | Percentage of repository files removed | No evidence found in codebase |

> Metrics are emitted in log lines prefixed `INFO performance repo=...` and visible in Wavefront at `https://groupon.wavefront.com/dashboard/lavatory`.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Lavatory performance | Wavefront | https://groupon.wavefront.com/dashboard/lavatory |

### Alerts

> No evidence found in codebase. Alert configuration is managed outside this repository.

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| No purge activity for 24h | Absence of `sourcetype=lavatory` logs in Splunk over 24h window | warning | Check cron job on primary hosts; check Artifactory connectivity |
| Artifactory unreachable | Container exits non-zero; no log output | critical | Verify Artifactory availability; check `lavatory` user credentials |

## Common Operations

### Restart Service

Lavatory Runner is a cron-triggered batch container, not a long-running service. To trigger an ad-hoc run:

1. SSH to the primary `artifactory-utility` host for the target environment.
2. Execute the cron script manually: `bash /opt/lavatory/lavatory_cron_job.sh <repo-name>`.
3. Monitor logs at `/var/log/lavatory/<repo-name>.log`.

### Scale Up / Down

To adjust which hosts run cron jobs:
1. Modify the Ansible inventory group `primary` in `ansible/env/<env>/lavatory`.
2. Run the Ansible playbook: `ansible-playbook -i env/<env>/lavatory retention_policy.yml --ask-vault-pass`.
3. To remove cron jobs, either update the playbook or SSH to the primary hosts and delete cron entries manually.

### Add or Remove a Policy

1. Read lavatory policy docs at `http://lavatory.readthedocs.io/en/latest/policies/index.html`.
2. Add or update a Python policy file in `policies/`.
3. Add the corresponding cron expression and repo name to Ansible group_vars files for uat, staging, and all prod colos.
4. Commit and push — wait for Jenkins to build and push the new Docker image.
5. Run the Ansible playbook to deploy updated cron jobs to hosts.

### Database Operations

> Not applicable. Lavatory Runner owns no database.

## Troubleshooting

### No artifacts being deleted (policy seems to have no effect)
- **Symptoms**: Splunk shows `removed_files_count=0` for expected repositories.
- **Cause**: All artifacts may be within retention thresholds, or the whitelist rules may be protecting them. Alternatively, the `TARGET_COLOS` download-date check may be preserving items recently pulled from any colo.
- **Resolution**: Run in dry-run mode (`lavatory purge --policies-path=/opt/lavatory/policies --repo <repo> --no-default`) to inspect the purge candidate list without deleting. Review policy thresholds (`TAG_MAX_AGE_DAYS`, `TAG_NUMBER_LIMIT`, `DOWNLOADED_DAYS_AGO`) and whitelist regex patterns in the relevant `policies/*.py` file.

### Artifactory authentication failure
- **Symptoms**: Container exits with HTTP 401 errors in logs; no artifacts deleted.
- **Cause**: `ARTIFACTORY_USERNAME` or `ARTIFACTORY_PASSWORD` is incorrect or the `lavatory` user account has been locked/changed.
- **Resolution**: Retrieve the current lavatory user password from `artifactory/secret` repo. Update the Ansible vault value and redeploy. Verify the `lavatory` user has admin rights in the target Artifactory instance.

### Cron job not running
- **Symptoms**: No Splunk entries for `sourcetype=lavatory` beyond the expected schedule window.
- **Cause**: Cron entry may have been removed or host may be unavailable. Only one `artifactory-utility` machine per production colo is designated as primary.
- **Resolution**: SSH to the primary host; check crontab for root user (`crontab -l`). If missing, re-run the Ansible playbook. Check host availability.

### Integration tests failing in Jenkins
- **Symptoms**: Jenkins "Test" stage fails; expected artifact counts before/after purge do not match `EXPECTED_BEFORE`/`EXPECTED_AFTER` values in `test/test.sh`.
- **Cause**: Test image timestamps may not be seeded correctly, or Artifactory Pro test container did not start within 50 seconds.
- **Resolution**: Review Jenkins test stage logs for the exact failure counts. Verify that the `artifactory/secret` repo checkout succeeded and contains a valid Artifactory Pro license file. Re-run the pipeline.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Artifactory disk full due to no cleanup running | Immediate | rapt team |
| P2 | Purge runs failing across all colos | 30 min | rapt team |
| P3 | Single repo not being cleaned | Next business day | rapt team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Artifactory | `GET /artifactory/api/system/ping` returns `OK` | None — container exits; next cron run retries |
| Splunk | Presence of recent `sourcetype=lavatory` entries | Logs remain on host under `/var/log/lavatory/` |
| Wavefront | Dashboard shows recent data points | Metrics still visible in Splunk performance log lines |
