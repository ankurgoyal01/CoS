---
service: "jira"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `http://jira.groupondev.com` | HTTP (200 response on root URL) | Not configured in source | Not specified |
| MySQL validation query `select 1` | JDBC | Every 300,000 ms (5 min) idle eviction | 3,000 ms (`validation-query-timeout`) |

> The `.service.yml` sets `status_endpoint.disabled: true`, meaning no automated status endpoint is registered.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Wavefront dashboard | gauge/counter | General Jira health metrics | See dashboard |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| snc1-jira | Wavefront | `https://groupon.wavefront.com/dashboard/snc1-jira` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| PagerDuty P2UCC96 | Service degradation or outage | critical | Page `page-sa@groupon.pagerduty.com`; follow Owners Manual |

## Common Operations

### Restart Service

1. Connect to the Jira host in `snc1`.
2. Run `sudo /usr/local/etc/init.d/jira stop`.
3. Verify the Java process has stopped: `ps -wfea | grep java`.
4. Run `sudo /usr/local/etc/init.d/jira start`.
5. Monitor startup: `sudo tail -f /var/groupon/atlassian/apps/jira/logs/catalina.out`.
6. Confirm Gwall SSO authentication: `sudo tail -f /var/groupon/atlassian/data/jira-home/log/gwall-authenticator.log`.

> Full failover instructions: `https://github.groupondev.com/ProdSysAdmin/Jira/wiki/Jira-Owners-Manual#how-to-do-to-failover`

### Scale Up / Down

> Single-node deployment. Horizontal scaling is not configured. Vertical scaling requires host reprovisioning by Systems Engineering.

### Database Operations

- Database is managed by DaaS MySQL team. Contact `syseng@groupon.com` for schema change requests.
- Jira applies its own schema migrations automatically during startup via internal `UpgradeTask` classes.
- For manual SQL access: connect to `jira-db-master-vip.snc1:3306`, database `jiranewdb`, user `jirauser`.

### Deploy a Config Change

1. Modify the relevant config file in `sys_config/`.
2. Copy the updated file to the Jira installation directory on the host.
3. Restart Jira using the steps above.
4. Log levels can be changed without restart via **Admin > System > Logging & Profiling** (changes are not persistent across restarts).

### Deploy a GwallAuthenticator Change

1. Obtain the Jira 5.0.6 standalone tarball.
2. Compile `GwallAuthenticator.java` against the Jira classpath (see `jira_sso/README`).
3. Copy the compiled `.class` file to `/var/groupon/atlassian/apps/jira/atlassian-jira/WEB-INF/classes/com/groupon/seraph/`.
4. Restart Jira.

## Troubleshooting

### Users Cannot Log In (SSO Headers Missing)
- **Symptoms**: Users are redirected to `/login.jsp` instead of being auto-authenticated. Log message: `"this is not a gwalled request, let's handle it using the super class"` in `gwall-authenticator.log`.
- **Cause**: The API proxy (`apiProxy`) is not injecting `X-GRPN-SamAccountName` and `X-OpenID-Extras` headers. This may indicate a proxy misconfiguration, Okta/Gwall outage, or direct access bypassing the proxy.
- **Resolution**: Verify that all traffic passes through `apiProxy`. Check Gwall/Okta health. Inspect request headers in `gwall-authenticator.log`.

### New User Provisioning Fails
- **Symptoms**: Log message `"username does not exist, we'll create it: <username>"` followed by an exception in `gwall-authenticator.log`. User cannot access Jira.
- **Cause**: `UserUtil.createUserNoNotification` failed. Possible causes: database connectivity issue, directory ID mismatch, or duplicate user constraint.
- **Resolution**: Check MySQL connectivity. Verify `directory_id=1` exists in `cwd_user`. Check Jira logs for the underlying exception.

### Legacy Username Not Mapped
- **Symptoms**: User with a current SSO username cannot log in. Log message: `"gwall username does not exist in DB"` but no legacy mapping found.
- **Cause**: `/var/groupon/jira/legacy_usernames.txt` does not contain an entry for the user's current SSO username.
- **Resolution**: Add a `current_username,legacy_username` line to `/var/groupon/jira/legacy_usernames.txt` on the Jira host. No restart required (file is read per-request).

### Database Connection Exhaustion
- **Symptoms**: Jira UI becomes unresponsive or very slow. `atlassian-jira.log` shows JDBC pool wait timeout (30,000 ms exceeded).
- **Cause**: All 20 JDBC connections are in use. Possible long-running queries or abandoned connections.
- **Resolution**: Check `atlassian-jira-slow-queries.log` for slow queries. Pool abandoned connection timeout is 300 s — connections should be reclaimed automatically. Consider restarting Jira if the pool does not recover.

### High Heap Usage / OutOfMemoryError
- **Symptoms**: `catalina.out` shows `OutOfMemoryError: Java heap space`. Jira becomes unresponsive.
- **Cause**: Heap limit (`-Xmx10240m`) exceeded. Common triggers: large JQL queries, bulk operations, or memory leaks in plugins.
- **Resolution**: Restart Jira. Review recent bulk operations. Consider raising `JVM_MAXIMUM_MEMORY` in `setenv.sh` if the host has available RAM.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down; no one can access Jira | Immediate | Page `page-sa@groupon.pagerduty.com`; PagerDuty service `P2UCC96` |
| P2 | Degraded performance or partial access issues | 30 min | Systems Engineering (`syseng@groupon.com`); Slack `CHW6USSV9` |
| P3 | Minor impact (single user issue, non-critical feature broken) | Next business day | Systems Engineering via Slack `CHW6USSV9` |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| MySQL (`jira-db-master-vip.snc1`) | JDBC `select 1` on idle connections | None; Jira is unavailable if DB is down |
| Okta / Gwall (`apiProxy`) | HTTP headers present on each request | Falls back to standard Jira login page (`/login.jsp`) |
