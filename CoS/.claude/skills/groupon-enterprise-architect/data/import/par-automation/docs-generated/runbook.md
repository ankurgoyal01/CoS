---
service: "par-automation"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /release/healthcheck` on port 8080 | HTTP | Kubernetes default | Kubernetes default |

The health check returns `HTTP 200 OK` with body `OK` when the process is running. Both readiness and liveness probes use this endpoint.

## Monitoring

### Metrics

> No evidence found in codebase. No custom metrics instrumentation (Prometheus, Datadog, etc.) is present in the repository. Runtime metrics are likely collected at the Kubernetes/Conveyor platform level.

### Dashboards

> No evidence found in codebase. Dashboard links are not documented in the repository. Check Groupon's standard GCP/Conveyor monitoring dashboards for the `par-automation` service.

### Alerts

> No evidence found in codebase. Alert configuration is not present in the repository. Alerts should be configured at the platform level for Kubernetes pod restarts, HPA scaling events, and HTTP 5xx rates.

## Common Operations

### Restart Service

1. Log in to the Kubernetes cluster for the target environment (e.g., `gcp-production-us-central1`, context: `par-automation-gcp-production-us-central1`)
2. Run: `kubectl rollout restart deployment/par-automation -n par-automation-{env}`
3. Monitor rollout: `kubectl rollout status deployment/par-automation -n par-automation-{env}`

### Scale Up / Down

Scaling is controlled via HPA. To manually adjust bounds:
1. Edit the Helm values in `.meta/deployment/cloud/components/api/common.yml` or the relevant environment file
2. Submit a PR, merge to `main`, and trigger a Deploybot deployment

### View Logs

Logs are written to stdout using Go's `log` package in structured JSON format for HTTP events. Use standard Kubernetes log commands or the Groupon Splunk/log aggregation platform (configured by `logConfig` in `common.yml`).

```bash
kubectl logs -l app=par-automation -n par-automation-{env} --tail=100
```

### Render Helm Manifests Locally

To inspect the rendered Kubernetes manifests for a given target environment:

```bash
raptor cloud:render --target staging-us-central1 -o rendered.yaml
```

## Troubleshooting

### PAR Request Returns HTTP 500 — Hybrid Boundary API Unreachable

- **Symptoms**: `POST /release/par` returns `HTTP 500` with `Description` containing "error when making request to Hybrid Boundary API"
- **Cause**: The Hybrid Boundary Lambda API (`continuumHybridBoundaryLambdaApi`) is unavailable or the `hb_api_domain` env var resolves to an unreachable host
- **Resolution**: Verify `hb_api_domain` config value for the environment; check Hybrid Boundary API health; confirm network connectivity within the service mesh

### PAR Request Returns HTTP 500 — Okta Token Failure

- **Symptoms**: `POST /release/par` returns `HTTP 500` with `Description` containing "error when getting Okta token"
- **Cause**: The `HYBRID-BOUNDARY-SVC-USER-OKTA` secret is expired, rotated, or the Okta IdP is unreachable
- **Resolution**: Verify the Okta client secret in GCP Secret Manager; check the `svc_hbuser` account is active in `groupon.okta.com`; confirm connectivity to `https://groupon.okta.com`

### PAR Request Returns HTTP 500 — Jira Ticket Creation Failure

- **Symptoms**: `POST /release/par` returns `HTTP 500` with `Description` containing "error while creating Jira issue"
- **Cause**: The Jira API token (`HYBRID-BOUNDARY-SVC-USER-JIRA`) has expired, the Jira project key is wrong, or the Jira service is unavailable
- **Resolution**: Verify the Jira API token in GCP Secret Manager; confirm the Jira service account has permission to create issues in `PAR` and `GPROD` projects in Jira

### PAR Request Returns HTTP 400 — Service Not Found in Service Portal

- **Symptoms**: `POST /release/par` returns `HTTP 400` with `Description` containing "could not find service ... in service portal"
- **Cause**: The `FromService` or `ToDomain` value provided does not exist in the Service Portal registry
- **Resolution**: Confirm the service name spelling; ensure the service is registered in Service Portal for the target environment

### PAR Request Returns HTTP 400 — Duplicate Request

- **Symptoms**: `POST /release/par` returns `HTTP 400` with `Description` containing "cannot add a principal that already exists"
- **Cause**: The requesting service's principal already has access to the target domain in Hybrid Boundary
- **Resolution**: No action needed — access already exists. The requester should verify existing policies in the Hybrid Boundary UI

### Service Fails to Start — Secret Manager Panic

- **Symptoms**: Pod crashes on startup with a panic referencing Secret Manager
- **Cause**: `PROJECT_NUMBER` env var is missing or incorrect, or the GCP service account running the pod lacks Secret Manager access
- **Resolution**: Verify `PROJECT_NUMBER` in the Helm values for the environment; confirm GCP IAM permissions for the pod's workload identity

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down; PAR requests cannot be processed | Immediate | cloud-routing@groupon.com |
| P2 | Degraded — partial failures (e.g., Jira tickets not created, non-production PAR requests failing) | 30 min | cloud-routing@groupon.com |
| P3 | Minor impact — isolated request failures; service otherwise healthy | Next business day | cloud-routing@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Service Portal | `GET {service_portal_root_domain}/grpn/healthcheck` | None — PAR request fails if Service Portal is unavailable |
| Hybrid Boundary Lambda API | Response to `GET /release/v1/services/{service}/{domain}/authorization/policies` | None — PAR request fails if HB API is unavailable |
| Okta IdP | Implicit via token request; check `https://groupon.okta.com` status | None — PAR request fails if Okta cannot issue a token |
| Jira (`continuumJiraService`) | Implicit via issue creation API; check Atlassian status page | None — PAR request fails in production if Jira is unavailable; non-production requests are unaffected |
| GCP Secret Manager | Implicit via SDK call at startup | None — pod panics on startup if secrets are unavailable |
