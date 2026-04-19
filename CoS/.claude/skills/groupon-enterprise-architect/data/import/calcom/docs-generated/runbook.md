---
service: "calcom"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Initial Delay | Notes |
|---------------------|------|--------------|-------|
| `GET /` (port 3000) | http readiness probe | 180 seconds | Kubernetes readiness probe; failure removes pod from service |
| `GET /` (port 3000) | http liveness probe | 180 seconds | Kubernetes liveness probe; failure triggers pod restart |

## Monitoring

### Metrics

> No service-level metrics configuration found in codebase. Metrics collection is handled at the Kubernetes infrastructure level.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Conveyor Cloud | Wavefront | https://groupon.wavefront.com/dashboard/conveyor-cloud |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Pod crash / restart loop | Liveness probe failures trigger pod restarts | critical | Check pod logs; inspect configuration; verify database connectivity |
| Readiness probe failures | Pod not ready after 180s initial delay | warning | Check application logs; verify database and SMTP connectivity |
| PagerDuty | Service-level incidents | critical | https://groupon.pagerduty.com/service-directory/PD8SL6O |

- **PagerDuty service**: https://groupon.pagerduty.com/service-directory/PD8SL6O
- **Team Gchat space**: AAAAwBAemtE
- **Mailing list**: conveyor-team@groupon.com

## Common Operations

### Restart Service

1. Identify the failing pod: `kubectl get pods -n calcom-production`
2. Check pod logs: `kubectl logs <pod-name> -n calcom-production`
3. Delete the pod to trigger a restart: `kubectl delete pod <pod-name> -n calcom-production`
4. Verify the replacement pod reaches `Running` state: `kubectl get pods -n calcom-production -w`

### Scale Up / Down

Scaling is managed via HPA and Helm values in `.meta/deployment/cloud/components/worker/<env>.yml`. To manually scale:
```
kubectl scale deployment calcom -n calcom-production --replicas=<N>
```
For persistent changes, update `minReplicas`/`maxReplicas` in the appropriate environment YAML file and redeploy.

### Adding an Admin User

Since user management is a paid Cal.com feature, admin promotion requires direct database access:
1. Obtain database credentials from the [calcom-secrets repository](https://github.groupondev.com/conveyor-cloud/calcom-secrets/blob/main/database_credentials) (requires DBA user access).
2. Have the target user create an account at `https://meet.groupon.com` with a password longer than 15 characters and 2FA enabled.
3. Connect to the production database (`calcom_prod` on `pg-noncore-us-057-prod`).
4. In the `users` table, update the target user's `role` field to `ADMIN`.
5. Ask the user to log out and back in to confirm admin access (visible as an `Admin` section in Settings).

### Accessing the Admin Section (Existing Admin)

1. Log in at `https://meet.groupon.com` using credentials from the [secrets repository](https://github.groupondev.com/conveyor-cloud/calcom-secrets/blob/main/admin_credentials).
2. Enable 2FA for the admin account.
3. Log out and log back in to gain access to the admin section.
4. Make required changes.
5. Disable 2FA when admin access is no longer needed.

### Database Operations

Database provisioning and backups are managed by the GDS team:
- **Staging DB**: `calcom_stg` on `pg-noncore-emea-561-stg` (AWS us-west-1, account: grpn-stable)
- **Production DB**: `calcom_prod` on `pg-noncore-us-057-prod` (AWS us-west-1, account: grpn-prod)
- **Backup/restore**: Contact GDS via [#gds-daas](https://chat.google.com/room/AAAAIGlgIi0?cls=7) Gchat channel
- **Production incidents**: Use [#production](https://chat.google.com/room/AAAAOTeTjHg?cls=7) Gchat channel
- For general backup documentation: [AWS Backups & Restores Confluence page](https://groupondev.atlassian.net/wiki/spaces/PRODOPS/pages/55045747316/AWS+Backups+Restores)

## Troubleshooting

### Pod Failing to Start / Crash Loop
- **Symptoms**: Pods remain in `CrashLoopBackOff` or `Error` state; liveness probe failures
- **Cause**: Application crash on startup, typically due to missing environment variables, inability to connect to the database, or insufficient memory
- **Resolution**: Check pod logs (`kubectl logs <pod-name> -n calcom-production`); verify all required env vars are set; confirm database is reachable; check if memory limits are sufficient (minimum 1500Mi for single-user load)

### Emails Not Delivered
- **Symptoms**: Booking confirmations or reminders not received by attendees
- **Cause**: SMTP credentials invalid, Gmail SMTP service unreachable, or incorrect `EMAIL_FROM` / `EMAIL_SERVER_*` configuration
- **Resolution**: Verify SMTP env vars are correctly set; check application logs for SMTP errors; confirm SMTP credentials in Kubernetes secrets are current

### Admin Section Inaccessible
- **Symptoms**: No "Admin" section visible in Settings after login
- **Cause**: Admin account does not have 2FA enabled, or password is not longer than 15 characters; or user's `role` is not `ADMIN` in the database
- **Resolution**: Enable 2FA on the admin account (see Admin Login steps above); verify user `role` field in database

### Application Errors (Application-Level Bugs)
- **Symptoms**: UI errors, booking failures, or unexpected application behavior
- **Cause**: Upstream Cal.com application issue
- **Resolution**: This is a wrapper around a third-party tool. Check [Cal.com documentation](https://cal.com/) and [Cal.com GitHub](https://github.com/calcom/cal.com) for known issues. Apply a newer image version if a fix is available upstream.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down / meet.groupon.com unreachable | Immediate | Conveyor Team via PagerDuty (PD8SL6O) |
| P2 | Degraded (emails not sending, booking failures) | 30 min | Conveyor Team via Gchat (space: AAAAwBAemtE) |
| P3 | Minor impact (admin access issue, single user problem) | Next business day | conveyor-team@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumCalcomPostgres` | GDS monitors database availability; app readiness probe implicitly validates DB connectivity | No fallback; service is non-functional without database |
| `gmailSmtpService` (smtp.gmail.com:465) | No dedicated health check; errors surface in application logs | Booking records persist in DB; only notifications fail |
| `continuumCalcomWorkerService` | Kubernetes pod health probes on port 3000 | Background jobs queue in DB; delivery delayed until worker recovers |

## Useful Links

| Resource | URL |
|---------|-----|
| Owners Manual | https://pages.github.groupondev.com/conveyor/dev_guide/onboarding.html |
| ORR Document | https://docs.google.com/document/d/1RmP_vQ9H5hE_kpKvjOuSbOZZ6tKl8HnH9pEUP2SbrqI/edit |
| GEARS Document | https://docs.google.com/document/d/19jrwLBJwrL-KlQK3_S5Flmo8rzyshuY6oaajK4eN2SY/edit |
| Failure Scenarios | https://docs.google.com/document/d/157SU0XfnDd8A894CLoRAtzw02kncJl54nHcqKzW6zis/edit |
| ARQ Access Request | https://arq.groupondev.com/ra/request/service |
| Wavefront Dashboard | https://groupon.wavefront.com/dashboard/conveyor-cloud |
| PagerDuty | https://groupon.pagerduty.com/service-directory/PD8SL6O |
