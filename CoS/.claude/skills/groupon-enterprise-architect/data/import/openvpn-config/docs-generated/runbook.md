---
service: "openvpn-config"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| None — status endpoint disabled | N/A | N/A | N/A |

The `.service.yml` declares `status_endpoint: disabled: true`. Health of the Cloud Connexa platform itself is monitored via the OpenVPN Cloud Connexa admin console and the InfoSec GChat space `AAAAsHzYN9c`.

## Monitoring

### Metrics

> No evidence found in codebase. No application-level metrics are emitted. Script exit codes provide the primary signal of success or failure.

### Dashboards

> No evidence found in codebase. Monitoring dashboards are not configured in this repository. The Cloud Connexa admin console provides operational visibility into the VPN tenant.

### Alerts

> No evidence found in codebase. Alerting is managed externally. Contact infosec@groupon.com or the GChat space `AAAAsHzYN9c` for incident response.

## Common Operations

### Export Backup

Capture a full snapshot of the current Cloud Connexa tenant configuration:

```bash
export OPENVPN_API=https://<tenant>.openvpn.com
export OPENVPN_CLIENT_ID=<client-id>
export OPENVPN_CLIENT_SECRET=<client-secret>
python3 export_backup.py
```

Output files written to `backup/`:
- `backup/networks.json`
- `backup/users.json`
- `backup/user_groups.json`
- `backup/apps.json`
- `backup/ip_services.json`
- `backup/access_groups.json`

### Restore Backup

Restore missing entities from the last export to the Cloud Connexa tenant:

```bash
export OPENVPN_API=https://<tenant>.openvpn.com
export OPENVPN_CLIENT_ID=<client-id>
export OPENVPN_CLIENT_SECRET=<client-secret>
python3 restore_backup.py
```

The script compares each entity in the backup files against live Cloud Connexa state and only creates entities that are missing. Existing entities are not overwritten (except access group destinations, which are appended).

### Delete a User

Remove a specific user from Cloud Connexa by email address:

```bash
export OPENVPN_API=https://<tenant>.openvpn.com
export OPENVPN_CLIENT_ID=<client-id>
export OPENVPN_CLIENT_SECRET=<client-secret>
python3 delete_user.py user@groupon.com
```

The script validates the email format, looks up the user ID by email, and issues a DELETE request. Confirmation is printed to stderr.

### Query: Find Application for a Domain

```bash
cd scripts/
DOMAIN=example.internal ./get-app-for-domain.sh
```

### Query: Find IP Services in a Subnet

```bash
cd scripts/
python3 get-services-in-subnet.py 10.224.0.0/16
```

### Query: Find Service for a Specific IP Range

```bash
cd scripts/
python3 get-service-for-ip-range.py 10.224.0.0/20
```

### Query: List Access Groups for a User

```bash
cd scripts/
USER=user@groupon.com ./list-groups-for-user.sh
```

### Query: List Access Groups for an Application

```bash
cd scripts/
APP="my-app-name" ./list-groups-for-app.sh
```

### Query: List Users for an Application

```bash
cd scripts/
APP="my-app-name" ./list-users-for-app.sh
```

### Query: List Users for an Access Group

```bash
cd scripts/
GROUP="my-group-name" ./list-users-for-group.sh
```

### Scale Up / Down

> Not applicable. This is a CLI toolset, not a deployed service.

### Database Operations

No database migrations are required. The `backup/*.json` files are overwritten in full by each export run. To refresh the backup after making changes in Cloud Connexa, re-run `export_backup.py`.

## Troubleshooting

### Script fails with HTTP 4xx error

- **Symptoms**: Script exits with an exception; stderr shows request args, response headers, and response body
- **Cause**: Invalid credentials, incorrect `OPENVPN_API` URL, or the targeted entity does not exist
- **Resolution**: Verify all three environment variables are set and correct. Check the response body in stderr for the specific API error message.

### Script fails with HTTP 429 Too Many Requests

- **Symptoms**: Script pauses silently for a period, then continues (handled automatically by `make_api_call` in `openvpn_api.py`)
- **Cause**: Cloud Connexa API rate limit reached
- **Resolution**: No manual intervention needed; the script sleeps for `x-ratelimit-replenish-time` seconds and retries automatically.

### User not found during delete

- **Symptoms**: `delete_user.py` prints "Couldn't find an OpenVPN user with that email." to stderr and exits without deleting
- **Cause**: The supplied email does not match any user in Cloud Connexa (case-insensitive comparison is attempted)
- **Resolution**: Verify the email address. Run an export backup and check `backup/users.json` for the correct email.

### Restore skips an application

- **Symptoms**: stderr message `Skipping app '<name>'` during `restore_backup.py`
- **Cause**: Application restore requires network ID remapping for apps that have moved networks; the remapping code path is incomplete (noted as pending in `restore_backup.py` line 87)
- **Resolution**: Manually create the skipped application in Cloud Connexa admin console, or update the restore script network-ID remapping logic.

### IP service route not found for subnet

- **Symptoms**: `ValueError: Network route not found for range '<subnet>' in ip-service '<name>'`
- **Cause**: An IP service references a subnet that is not covered by any restored network's routes
- **Resolution**: Ensure the parent network for the IP service has been restored first and that its routes include the required subnet.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Cloud Connexa VPN down — remote employees cannot access internal network | Immediate | infosec@groupon.com, GChat space AAAAsHzYN9c |
| P2 | Partial access loss — specific applications or user groups inaccessible | 30 min | infosec@groupon.com |
| P3 | Backup script failure — configuration snapshot not up to date | Next business day | infosec@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| OpenVPN Cloud Connexa API | Attempt `GET /api/beta/networks/page?page=0&size=1` with valid credentials; expect HTTP 200 | No automated fallback; operations blocked until API is available |
| Okta | Check Okta admin console status | Cloud Connexa authentication unavailable; VPN connectivity impacted |
| AWS DNS | DNS resolution of connector hostnames | Connector tunnel establishment may fail |

> Operational procedures for infrastructure-level incidents (connector host failures, AWS DNS outages) are managed by the NetOps team and are outside the scope of this automation repository.
