---
service: "mdi-dashboard-v2"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /health` | http | > No evidence found | > No evidence found |

> No evidence found of an explicitly configured health check endpoint. The itier-server framework typically exposes a `/health` or `/status` endpoint. Confirm with service owner.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Number of incoming HTTP requests per route | Operational procedures to be defined by service owner |
| HTTP error rate (5xx) | counter | Number of 5xx responses from the Express server | Operational procedures to be defined by service owner |
| HTTP latency | histogram | Response time per route | Operational procedures to be defined by service owner |
| PostgreSQL connection errors | counter | Errors connecting to mdiDashboardPostgres | Operational procedures to be defined by service owner |
| Downstream service error rate | counter | HTTP errors from upstream Continuum service calls | Operational procedures to be defined by service owner |

### Dashboards

> Operational procedures to be defined by service owner. Dashboard links are not discoverable from the inventory.

| Dashboard | Tool | Link |
|-----------|------|------|
| MDI Dashboard Overview | > Not documented | > Not documented |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High 5xx rate | >5% of requests return 5xx over 5 min | critical | Check Node.js process logs; verify downstream service connectivity; restart if unresponsive |
| PostgreSQL unavailable | Connection to mdiDashboardPostgres fails | critical | Verify DB host connectivity; check Sequelize connection pool; alert DBA team |
| Downstream service degraded | Repeated timeouts to Marketing Deal Service or other dependencies | warning | Check API Proxy health; verify downstream service status; consider temporarily disabling affected routes |

## Common Operations

### Restart Service

1. SSH to the target VM in the affected datacenter (snc1 / sac1 / dub1).
2. Identify the Node.js process: `ps aux | grep node`.
3. Send SIGTERM to the process to allow graceful shutdown: `kill -TERM <pid>`.
4. Verify the process has stopped: `ps aux | grep node`.
5. Start the service using the Napistrano start command or process manager: `npm start` or equivalent itier-server start command.
6. Confirm the health check endpoint responds successfully.

### Scale Up / Down

1. Provision or deprovision VMs via the internal infrastructure tooling.
2. Run a Napistrano deploy targeting the new VM set to install and configure the application.
3. Update the load balancer configuration to include or remove the VM.

### Database Operations

1. **Run migrations**: Execute Sequelize migration CLI against the target environment's `DATABASE_URL`: `./node_modules/.bin/sequelize db:migrate`.
2. **Rollback migration**: `./node_modules/.bin/sequelize db:migrate:undo`.
3. **Connection verification**: Test PostgreSQL connectivity using `psql` with the configured `DATABASE_URL`.

## Troubleshooting

### Deal browser returns no results
- **Symptoms**: `/browser` endpoint returns empty deal list or HTTP 500
- **Cause**: Marketing Deal Service is unreachable, returning errors, or the API Proxy is degraded
- **Resolution**: Check connectivity to `continuumMarketingDealService` via API Proxy; inspect Node.js process logs for HTTP error codes from downstream; verify `MARKETING_DEAL_SERVICE_URL` environment variable is correctly set

### Feed generation does not execute
- **Symptoms**: POST to `/feeds/generate` returns an error or feed status does not update
- **Cause**: MDS Feed Service is unreachable; `DATABASE_URL` misconfigured preventing feed config read; or feed configuration is malformed
- **Resolution**: Verify feed configuration in PostgreSQL; check connectivity to MDS Feed Service (`MDS_FEED_SERVICE_URL`); inspect application logs for Sequelize or HTTP errors

### API key creation fails
- **Symptoms**: POST to `/keys` returns a 500 or database error
- **Cause**: PostgreSQL connection unavailable or Sequelize misconfiguration
- **Resolution**: Verify `DATABASE_URL` is correctly set; check `mdiDashboardPostgres` availability; inspect Sequelize error logs

### Authentication failures for all routes
- **Symptoms**: All routes return 401 or redirect to login repeatedly
- **Cause**: `SESSION_SECRET` misconfigured; itier-user-auth service unreachable; session store issue
- **Resolution**: Verify `SESSION_SECRET` environment variable; check itier-user-auth configuration; inspect itier-server auth middleware logs

### JIRA ticket creation fails
- **Symptoms**: JIRA ticket creation action returns an error in the UI
- **Cause**: `JIRA_HOST`, `JIRA_USERNAME`, or `JIRA_PASSWORD` misconfigured; JIRA service unreachable
- **Resolution**: Verify JIRA environment variables; test JIRA API credentials manually; check network connectivity to `JIRA_HOST`

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down; no users can access the dashboard | Immediate | Marketing Engineering on-call |
| P2 | Core feature degraded (deal browser, feed management unavailable) | 30 min | Marketing Engineering on-call |
| P3 | Non-critical feature degraded (JIRA integration, Salesforce data missing) | Next business day | Marketing Engineering team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumMarketingDealService` | HTTP GET to service health endpoint via API Proxy | Deal browser and insights pages show error state |
| `mdiDashboardPostgres` | Sequelize connection pool health | Feed builder and API key management unavailable |
| `continuumTaxonomyService` | HTTP GET to service health endpoint | Search autocomplete unavailable |
| `apiProxy` | HTTP connectivity check | All internal Continuum service calls fail |
| `salesForce` | HTTP connectivity check | Merchant CRM data unavailable; non-blocking |
| JIRA | HTTP connectivity check to `JIRA_HOST` | Ticket creation unavailable; non-blocking |
