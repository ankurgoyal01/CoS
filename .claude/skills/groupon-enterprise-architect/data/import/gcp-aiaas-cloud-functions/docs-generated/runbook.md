---
service: "gcp-aiaas-cloud-functions"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /health` (Cloud Run: InferPDS API, MAD InferPDS API) | http | 30s (Docker HEALTHCHECK) | 10s |
| `GET /health` (Deal Score Cloud Function: `health_check` entry point) | http | On-demand | n/a |
| Docker HEALTHCHECK (`curl -f http://localhost:${PORT:-8080}/health`) | exec | 30s | 10s |

## Monitoring

### Metrics

> No application-level metrics instrumentation found in codebase. Monitoring relies on GCP Cloud Functions and Cloud Run built-in metrics.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| GCP Cloud Function invocation count | counter | Number of function invocations | Operational procedures to be defined by service owner |
| GCP Cloud Function error rate | gauge | Percentage of invocations returning 5xx | Operational procedures to be defined by service owner |
| GCP Cloud Run request latency | histogram | End-to-end request duration for InferPDS services | Operational procedures to be defined by service owner |
| GCP Cloud Run instance count | gauge | Number of running Cloud Run instances | Operational procedures to be defined by service owner |

### Dashboards

> Operational procedures to be defined by service owner.

| Dashboard | Tool | Link |
|-----------|------|------|
| GCP Cloud Functions monitoring | Google Cloud Console | GCP Console > Cloud Functions |
| GCP Cloud Run monitoring | Google Cloud Console | GCP Console > Cloud Run |
| LangSmith traces | LangSmith | `https://smith.langchain.com` (project: `InferPDS-Production`) |

### Alerts

> Operational procedures to be defined by service owner.

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| InferPDS health check failure | `GET /health` returns non-200 | critical | Redeploy Cloud Run service; check PostgreSQL and OpenAI connectivity |
| High Vertex AI error rate | Sustained `MODEL_PREDICTION_ERROR` responses | warning | Check Vertex AI endpoint status in GCP Console; verify service account credentials |
| PostgreSQL connection failures | Log entries showing `PostgreSQL connection failed` | warning | Check PostgreSQL host reachability; verify `POSTGRES_PASSWORD` / `DAAS_DBA_PASSWORD` env vars |
| Salesforce authentication failures | Log entries showing `Salesforce authentication failed` | warning | Check SF credentials in environment variables; verify Salesforce instance URL |

## Common Operations

### Restart Service

**Cloud Run (InferPDS API / MAD InferPDS API)**:
1. Navigate to GCP Console > Cloud Run > select the service
2. Click "Edit & Deploy New Revision" and deploy with no changes to trigger a rolling restart
3. Alternatively: `gcloud run deploy SERVICE_NAME --region us-central1 --image IMAGE_URL`

**Cloud Functions**:
Cloud Functions are stateless and restart on each invocation. To force re-deployment:
1. `gcloud functions deploy FUNCTION_NAME --region us-central1 --runtime python311`

### Scale Up / Down

**Cloud Run**:
- Set minimum instances: `gcloud run services update SERVICE_NAME --min-instances N`
- Set maximum instances: `gcloud run services update SERVICE_NAME --max-instances N`

**Cloud Functions**:
- Set maximum instances: `gcloud functions deploy FUNCTION_NAME --max-instances N`

### Database Operations

**PostgreSQL — Check connectivity**:
```
psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DATABASE -c "SELECT 1"
```

**PostgreSQL — Check scraped data for an account**:
```sql
SELECT account_id, scraped_at, length(page_text) as text_length
FROM aidg.inferpds_scraped_data
WHERE account_id = '<ACCOUNT_ID>'
ORDER BY scraped_at DESC LIMIT 5;
```

**PostgreSQL — Check matched services for an account**:
```sql
SELECT account_id, extracted_service, service_name, similarity_score, updated_at
FROM aidg.inferpds_services
WHERE account_id = '<ACCOUNT_ID>'
ORDER BY updated_at DESC LIMIT 10;
```

## Troubleshooting

### PostgreSQL Connection Failure
- **Symptoms**: Log entries `PostgreSQL connection failed` or `Failed to initialize PostgreSQL connection`; AIDG function returns `500 INTERNAL_ERROR`; InferPDS falls back to scraping mode
- **Cause**: Wrong `POSTGRES_HOST`, `POSTGRES_USER`, or `POSTGRES_PASSWORD` environment variables; network connectivity issue from Cloud Function / Cloud Run to PostgreSQL host; connection pool exhausted
- **Resolution**: Verify environment variables; check VPC/network connectivity from GCP to the PostgreSQL host; restart the Cloud Run service to reset the connection pool

### Vertex AI Prediction Failure
- **Symptoms**: Deal Score function returns `500 MODEL_PREDICTION_ERROR`; Google Scraper returns `merchantPotential` as error string
- **Cause**: Vertex AI endpoint `1617826906667745280` unavailable; GCP service account lacking `aiplatform.endpoints.predict` permission; feature vector schema mismatch
- **Resolution**: Check endpoint status in GCP Console (`prj-grp-aiaas-stable-6113`, `us-central1`); verify service account IAM roles; review feature names in request against endpoint expected schema

### OpenAI API Failure
- **Symptoms**: Deal generation returns `500 INTERNAL_ERROR`; InferPDS returns empty `pds` array; LangSmith shows failed traces
- **Cause**: `OPENAI_API_KEY` invalid or expired; OpenAI API rate limit or quota exceeded; model name mismatch
- **Resolution**: Rotate `OPENAI_API_KEY`; check OpenAI dashboard for quota usage; verify model name in request (default: `gpt-4.1-mini-2025-04-14`)

### Salesforce Authentication Failure
- **Symptoms**: Google Scraper logs `Salesforce authentication failed` but continues; InferPDS skips CRM persistence; missing account enrichment in Salesforce
- **Cause**: Salesforce password + security token incorrect; SF instance URL wrong; connected app credentials expired
- **Resolution**: Update `SF_PASSWORD` (password concatenated with security token), `SF_USERNAME`, and `SF_INSTANCE_URL` environment variables; regenerate Salesforce security token if expired

### InferPDS Returns Empty Services
- **Symptoms**: `POST /extract-services` returns `{"pds": [], "newServices": [], ...}` with no matched taxonomy services
- **Cause**: Merchant website is unreachable or returns no parseable content; similarity threshold too high; PDS taxonomy CSV reference data missing or mismatched
- **Resolution**: Test merchant URL reachability; reduce `similarityThreshold` query parameter (default `0.25`); use `forceNewScraping=true` to bypass cache; check that taxonomy CSV files are present in the Cloud Run container

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | All InferPDS or AIDG functions down; no deal generation possible | Immediate | AIaaS Platform Team |
| P2 | Degraded accuracy; Salesforce enrichment failing; PostgreSQL unavailable | 30 min | AIaaS Platform Team |
| P3 | Single function returning errors; non-critical enrichment (TinyURL, LangSmith) failing | Next business day | AIaaS Platform Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| PostgreSQL (`continuumAiaasPostgres`) | `SELECT 1` ping on each request (AIDG); connection attempt on request (InferPDS) | AIDG uses empty `scraped_text`; InferPDS triggers fresh web scraping |
| OpenAI API | No pre-check; errors surfaced at inference time | No fallback; returns structured error response |
| Vertex AI | No pre-check; errors surfaced at prediction time | Google Scraper falls back to LightGBM local model if `test=true` |
| Salesforce CRM | Authentication attempt at request start | Google Scraper continues without Salesforce update; logs warning |
| Apify | No pre-check; errors returned in response payload | Social Link Scraper includes `instagram_apify.error` field; proceeds without enrichment |
| BigQuery | Client initialization at request time | Returns `500 BIGQUERY_ERROR` to caller; no fallback |
