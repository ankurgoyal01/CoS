# Runbook

## Deployment
- Runs on Kubernetes (cluster: legacy-prod)
- Helm chart: `marketing-deal-service`
- CI/CD pipeline: Jenkins job `mds-deploy`

## Monitoring
- Grafana dashboard: `marketing-deal-overview`
- Alerts: PagerDuty service `Merchant Deals`

## Rollback Procedure
1. Roll back Helm release: `helm rollback mds <previous_revision>`
2. Verify feed generator status.
3. Notify merchant-platform Slack channel.
