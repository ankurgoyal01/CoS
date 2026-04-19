---
service: "AIGO-ContentServices"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Component | Type | Port |
|---------------------|-----------|------|------|
| `GET /grpn/healthcheck` | frontend-content-generator | http | 3000 |
| `GET /grpn/healthcheck` | service_content_generator | http | 5000 |
| `GET /grpn/healthcheck` | service_web_scraper | http | 8000 |
| `GET /grpn/healthcheck` | service_prompt_database | http | 7000 |

All four services implement `GET /grpn/healthcheck` which returns `{"status": "OK"}` on success. This endpoint is configured as both the readiness and liveness probe in each component's Kubernetes deployment manifest (`common.yml`).

## Monitoring

### Metrics

> No evidence found in codebase. No Prometheus, Datadog, or application-level metrics instrumentation is implemented. Logging uses Python `logging` module (INFO level) and stdout.

### Dashboards

> No evidence found in codebase. Dashboard configuration is managed externally by the platform/operations team.

### Alerts

> No evidence found in codebase. Alert configuration is managed externally.

## Common Operations

### Restart Service

Operational procedures to be defined by service owner. For Kubernetes-managed deployments, restart a component by rolling the deployment:

1. Identify the component name: `frontend`, `generator`, `scraper`, or `promptdb`
2. Use Raptor or `kubectl rollout restart deployment/<component>` in the appropriate namespace
3. Verify readiness probe at `GET /grpn/healthcheck` returns `{"status": "OK"}`

### Scale Up / Down

Scaling is managed via HPA with `hpaTargetUtilization: 50`. To manually override:

1. Update `minReplicas`/`maxReplicas` in `.meta/deployment/cloud/components/<component>/staging-us-central1.yml` or `production-us-central1.yml`
2. Trigger a deployment via Jenkins or Raptor deploy

### Database Operations

**Run Migrations** (Prompt Database Service):

```sh
# From inside the service_prompt_database container or locally with DB access:
alembic upgrade head
```

Migrations are in `service_prompt_database/alembic/versions/`. Seed migrations populate initial agent configurations and guidelines from JSON files in `service_prompt_database/alembic/data/`.

**Rollback Migration**:

```sh
alembic downgrade -1
```

**Refresh Salesforce Data** (Content Generator Service):

1. Call `POST /salesforce/launch-job` to create a new bulk query job
2. Call `GET /salesforce/poll-job` to launch, poll, and store results in one step (recommended)
3. Data is stored at `salesforce/salesforce_data/salesforce_data.csv` within the container
4. Call `GET /salesforce/get-stored-data` to retrieve the latest stored data as JSON

## Troubleshooting

### LLM Requests Failing
- **Symptoms**: `POST /generate` returns HTTP 500; logs show `Error in LLM response`
- **Cause**: `OPENAI_API_KEY` is invalid, expired, or rate-limited by OpenAI
- **Resolution**: Verify `OPENAI_API_KEY` environment variable is set correctly in the generator deployment manifest; check OpenAI API status; rotate key if compromised

### Salesforce Authentication Failure
- **Symptoms**: `POST /salesforce/launch-job` returns HTTP 401 with `"Failed to authenticate with Salesforce"`
- **Cause**: Salesforce credentials (`SF_USERNAME`, `SF_PASSWORD`) are incorrect or expired; `SF_INSTANCE_URL` is misconfigured
- **Resolution**: Verify Salesforce credentials in deployment secrets; confirm `SF_INSTANCE_URL` matches the correct Salesforce org

### Salesforce Job Polling Timeout
- **Symptoms**: `GET /salesforce/poll-job` returns HTTP 408 after exhausting attempts
- **Cause**: Salesforce bulk query job is taking longer than `max_attempts * interval` seconds
- **Resolution**: Call `GET /salesforce/poll-job?max_attempts=12&interval=15` to extend polling window; or manually call `/salesforce/launch-job` then `/salesforce/store-results/{job_id}` after sufficient wait time

### Web Scraper Returns Empty USPs
- **Symptoms**: `POST /crawl` returns `top10_usps: []`
- **Cause**: Merchant website pages failed to load or contain no relevant commercial content; Chromium driver setup failed; Prompt Database Service unavailable (agent configs not loaded)
- **Resolution**: Verify `PROMPT_DATABASE_URL` is reachable from the scraper pod; confirm Chromium/Selenium dependencies are installed in the container; check scraper logs for `Failed to scrape <url>` warnings

### Prompt Database Service Unavailable
- **Symptoms**: Web scraper returns empty agent configs; content generation returns errors referencing missing guidelines
- **Cause**: `continuumPromptDatabaseService` pod is down or `PROMPT_DATABASE_URL` is misconfigured
- **Resolution**: Check pod health via `GET /grpn/healthcheck`; verify internal cluster DNS resolution for `aigo-contentservices--promptdb.staging.service`; confirm database migrations have been applied

### Frontend Cannot Reach Backend Services
- **Symptoms**: Browser shows API errors; network requests to generator/scraper/promptdb fail with CORS or connection errors
- **Cause**: `NEXT_PUBLIC_GENERATOR_URL`, `NEXT_PUBLIC_SCRAPER_URL`, or `NEXT_PUBLIC_PROMPTDB_URL` environment variables are not set or point to wrong URLs
- **Resolution**: Verify frontend deployment manifest env vars for the target environment; redeploy frontend if env vars were recently changed

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Platform fully unavailable (all content generation blocked) | Immediate | AIGO Engineering on-call |
| P2 | Single service degraded (e.g., scraper down; generation still functional) | 30 min | AIGO Engineering |
| P3 | Minor impact (e.g., stale Salesforce data; guidelines API slow) | Next business day | AIGO Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumPromptDatabaseService` | `GET /grpn/healthcheck` on port 7000 | No fallback; scraper and frontend will fail to load agent/guideline data |
| `continuumContentGeneratorService` | `GET /grpn/healthcheck` on port 5000 | No fallback; frontend generation flow will be unavailable |
| `continuumWebScraperService` | `GET /grpn/healthcheck` on port 8000 | No fallback; scrape step in frontend will be unavailable |
| `continuumPromptDatabasePostgres` | SQLAlchemy session health (implicit) | No fallback; Prompt Database Service will return 500 on all DB-backed endpoints |
| OpenAI API | External; check status.openai.com | No fallback; LLM-dependent endpoints return HTTP 500 |
| Salesforce | External; check Salesforce status page | Stored CSV data remains accessible via `/salesforce/get-stored-data` if previously fetched |
