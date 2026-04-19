---
service: "web-config"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` (port 9999) | http | Configured by load balancer | Configured by load balancer |
| `GET /heartbeat` (port 80/443) | http | Configured by load balancer | Configured by load balancer |
| `nginx -t` (pre-deploy validation) | exec | On every deploy | Synchronous |

The healthcheck endpoints proxy to `grout_proxy` (127.0.0.1:9000) and are restricted to internal network ranges (127.0.0.1, 10.0.0.0/8, 100.0.0.0/8, 172.16.0.0/12). External access is denied with HTTP 403.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| nginx `stub_status` at `/nginx_status` | gauge | Active connections, requests accepted/handled/total | Internal networks only |
| `requestTime` (nginx access log field) | histogram | Total request processing time in seconds | Operational procedures to be defined by service owner |
| `upstreamResponseTime` (nginx access log field) | histogram | Time to receive response from grout_proxy | Operational procedures to be defined by service owner |

nginx access logs use the `routing` format and write to `/var/log/nginx/access_file.log`. Log fields include: `vhost`, `ip`, `clientIp`, `xff`, `request`, `status`, `requestTime`, `upstreamResponseTime`, `requestId`, `brand`, `https`, `akbot`.

### Dashboards

> Operational procedures to be defined by service owner. Dashboard links are not discoverable from the repository.

### Alerts

> Operational procedures to be defined by service owner. Alert definitions are managed outside this repository.

## Common Operations

### Generate config for a single environment

```sh
pipenv run fab generate:{ENVIRONMENT}
# ENVIRONMENT: test, staging, production, redirect
# deploy_target defaults to "cloud"
```

### Generate config for all environments

```sh
pipenv run fab generate_all
```

### Deploy config to an environment (requires specific revision for production)

```sh
pipenv run fab {ENVIRONMENT} deploy:{REVISION}
# Example (production SNC1):
#   pipenv run fab prod_snc1 deploy:abc1234
# UAT/test may omit REVISION:
#   pipenv run fab uat_snc1 deploy
```

### Check deployed revision and metadata

```sh
pipenv run fab {ENVIRONMENT} check_revision check_meta
```

### Rollback config

```sh
pipenv run fab {ENVIRONMENT} rollback
```

### Deploy error pages only

```sh
pipenv run fab {ENVIRONMENT} deploy_error_pages
```

### Run redirect automation CLI (production)

```sh
cd go/redirect-requests
./create-redirects -e production
# Dry run (deprecated):
./create-redirects -e production --dryrun
# Single ticket:
./create-redirects -e production -t MESH-1234
```

### Scale Up / Down

> Deployment configuration managed externally. Replica scaling is handled via the `routing-deployment` Kubernetes manifest repository.

### Database Operations

> Not applicable. web-config does not own any database. Git history serves as the audit log for all config changes.

## Troubleshooting

### nginx config validation failure during CI

- **Symptoms**: Jenkins `Build and Test` stage fails; Docker Compose reports `nginx: configuration file /var/groupon/nginx/conf/main.conf test failed`
- **Cause**: A Mustache template rendering error, invalid YAML data, or malformed nginx directive in a template or data file
- **Resolution**: Run `pipenv run fab generate:{ENV}` locally; inspect the generated `conf/nginx/k8s/{env}/` files for syntax errors; fix the template or data file; re-run generation and validate with `nginx -t`

### Redirect CLI fails to retrieve Jira secret

- **Symptoms**: CLI panics with `error unable to retrieve secret credentials secretName: hybrid-boundary-svc-user-jira`
- **Cause**: IAM role on the execution host lacks `secretsmanager:GetSecretValue` permission, or the secret does not exist in the target region
- **Resolution**: Verify IAM permissions; confirm the secret name and region (`us-west-2` default, override with `-r`); check AWS Secrets Manager console

### Redirect CLI cannot create GitHub PR

- **Symptoms**: CLI prints `error: could not find github api token` or `Error: Could not create a pull request`
- **Cause**: `REDIRECT_API_TOKEN` environment variable is not set, expired, or lacks `repo` scope on `github.groupondev.com`
- **Resolution**: Set `REDIRECT_API_TOKEN` to a valid GitHub Enterprise personal access token with `repo` scope for the `routing/web-config` repository

### Routing host unreachable during deploy

- **Symptoms**: Fabric task fails with SSH connection error; `fab {ENV} deploy` does not complete
- **Cause**: SSH key not present, user does not have `sudo` access on the target host, or the `routing` user is not accessible
- **Resolution**: Verify SSH key is loaded (`ssh-add`); confirm `sudo` access on the target host; check VPN/network connectivity to `routing-app*.{datacenter}`

### Config deployed but nginx not reloading

- **Symptoms**: Config files updated on hosts but traffic behaviour unchanged
- **Cause**: nginx reload command failed silently after config copy
- **Resolution**: SSH to the routing host as the `routing` user; run `/usr/local/etc/init.d/nginx reload` manually; check `/var/log/nginx/error_file.log` for errors

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Routing service down — all traffic to groupon.com failing | Immediate | Routing Service + Prod-ops (prod-ops@groupon.com) + SOC (soc@groupon.com) |
| P2 | Degraded — specific virtual hosts or redirect rules broken | 30 min | Routing Service (routing-service@groupon.com) |
| P3 | Minor — error pages not updating, redirect automation blocked | Next business day | Routing Service |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| apiProxy / routing hosts | SSH connectivity + `nginx -t` pre-deploy | Existing config remains active; deploy aborts |
| Jira (continuumJiraService) | Successful issue search response | Redirect CLI aborts; no redirects are created |
| GitHub Enterprise | Successful PR creation response | Redirect CLI prints error; branch may still exist locally |
| AWS Secrets Manager | Successful `GetSecretValue` response | Redirect CLI panics; no Jira credentials available |
