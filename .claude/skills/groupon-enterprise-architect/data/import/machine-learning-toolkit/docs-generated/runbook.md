---
service: "machine-learning-toolkit"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Notes |
|---------------------|------|-------|
| `GET /healthcheck?scope=internal` | HTTP (API Gateway MOCK) | Returns `{ "message": "I am healthy" }` on 200; returns 500 if `scope` is not `internal` |
| `GET /{version}?scope=internal` | HTTP (API Gateway MOCK) | Per-version healthcheck; same contract as above |
| MWAA Scheduler Heartbeat (Wavefront) | CloudWatch metric | Most important MWAA health signal; visible in Wavefront filtered by MWAA environment name |

> The `status_endpoint` in `.service.yml` is set to `disabled: true`. The API Gateway healthcheck endpoint is the primary liveness check.

## Monitoring

### Metrics

| Metric | Tool | Description | Alert Threshold |
|--------|------|-------------|----------------|
| MWAA Scheduler Heartbeat | Wavefront | Ping success of MWAA scheduler; forwarded from CloudWatch for all `dnd-accounts` environments | Absence of heartbeat triggers severity 5 alert |
| MWAA Disk Space | Wavefront | Task storage usage on MWAA Fargate tasks (10 GB limit) | 80% full triggers "Airflow - No Disk Space" severity 5 alert |
| MWAA CPU Usage | Wavefront | CPU utilization of MWAA environment | Sustained high usage triggers "Airflow - High CPU Usage" severity 5 alert |
| MWAA Memory Usage | Wavefront | Memory utilization of MWAA environment | Sustained high usage triggers "Airflow - High Memory Usage" severity 5 alert |
| EMR Bootstrap Success/Failure | Wavefront | Whether EMR cluster bootstrapped successfully | Failure triggers "Ephemeral EMR - Failed to deploy" severity 2 alert |
| EMR Query Success/Failure | Wavefront | Whether EMR steps completed successfully | Failure triggers "Ephemeral EMR - Query Failed" severity 2 alert |
| SageMaker Endpoint Invocations | CloudWatch | Invocation count, latency, error rate per endpoint | CloudWatch deployment alarm `{project}-deployment-alarm` |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| ds-pnp | Wavefront | `https://groupon.wavefront.com/dashboards/ds-pnp` |
| dssi-ml-toolkit | Wavefront | `https://groupon.wavefront.com/dashboards/dssi-ml-toolkit` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Airflow - No Disk Space | Disk usage > 80% on MWAA Fargate task | 5 (critical) | [See Airflow - No Disk Space](#airflow---no-disk-space) |
| Airflow - No Scheduler Heartbeats | MWAA scheduler stops sending heartbeats | 5 (critical) | [See Airflow - No Scheduler Heartbeats](#airflow---no-scheduler-heartbeats) |
| Airflow - High CPU Usage | Sustained high CPU on MWAA host | 5 (critical) | [See Airflow - High Memory Usage](#airflow---high-memory-usage) (same procedure) |
| Airflow - High Memory Usage | Sustained high memory on MWAA host | 5 (critical) | [See Airflow - High Memory Usage](#airflow---high-memory-usage) |
| Ephemeral EMR - Failed to deploy | EMR bootstrap failure | 2 (warning) | [See EMR - Failed to deploy](#ephemeral-emr---failed-to-deploy) |
| Ephemeral EMR - Query Failed | EMR step failure | 2 (warning) | [See EMR - Query Failed](#ephemeral-emr---query-failed) |

## Common Operations

### Restart Service

To restart the MWAA environment:

1. Run a dummy `terraform apply` (update a non-functional environment attribute, e.g., a tag) via Jenkins using the `APPLY` action.
2. AWS will update the MWAA environment and restart the scheduler.

To fully destroy and redeploy:

1. Trigger Jenkins with `action=DESTROY ALL` for the target environment.
2. If destroy fails mid-way, run the destroy command again.
3. Once destroy completes, trigger Jenkins with `action=APPLY` to redeploy.
4. Requires access to the `grpn-dnd-dssi-af` IAM role (contact `@cloudcore` in Slack).

### Scale Up / Down

**MWAA workers**: The `max_workers` value in `mwaa.tf` can be updated up to 25. Default is 10. Update the Terraform variable and run `terraform apply` via Jenkins.

**MWAA environment class**: Upgrade from `mw1.small` to a larger class by updating the `environment_class` variable in `mwaa.tf` and running `terraform apply`.

**EMR cluster**: Modify the instance type or count in the project-specific EMR job configuration (DAG inputs or SSM model config). The platform administrator controls allowed instance types via CloudCore SCPs.

**SageMaker endpoint**: Autoscaling policy is configured per endpoint. Adjust instance type (use SageMaker Inference Recommender) and target scaling metrics via Terraform or the SageMaker console. Update the ADM (architecture decision memo) for the project before changing.

### Database Operations

> Not applicable. This service does not own a relational database. S3 bucket operations (if needed) should be performed via the AWS CLI or Console with the `grpn-dnd-dssi-af` role.

## Troubleshooting

### Airflow - No Disk Space

- **Symptoms**: Wavefront "Airflow - No Disk Space" alert; tasks may fail with disk-related errors
- **Cause**: MWAA Fargate task storage limited to 10 GB per ECS Fargate 1.3; log accumulation or large task outputs
- **Resolution**:
  1. Use a `BashOperator` DAG task to run `df` and identify the full disk
  2. Use `du -sh ./*` to identify large directories
  3. Remove large files confirmed unnecessary
  4. If logs are filling disk, investigate the source operator (likely `PythonOperator` or `BashOperator` producing excessive output)
  5. Log storage management is handled by AWS; open AWS Support for persistent issues

### Airflow - No Scheduler Heartbeats

- **Symptoms**: Wavefront "Airflow - No Scheduler Heartbeats" alert; DAGs stop scheduling or running
- **Cause**: MWAA scheduler crashed or MWAA environment unhealthy
- **Resolution**:
  1. Check `#production` Slack channel for broader AWS outage
  2. If no broader outage: run a dummy `terraform apply` to trigger MWAA environment update
  3. If environment is not running: destroy and redeploy via Jenkins
  4. If MWAA is running but Wavefront is still not receiving heartbeats: verify the CloudWatch metric exists in the MWAA log group
  5. If metrics are missing, contact AWS Support

### Airflow - High Memory Usage

- **Symptoms**: Wavefront "Airflow - High Memory Usage" alert
- **Cause**: Memory-intensive DAG task, excessive `PythonOperator` usage, or runaway process
- **Resolution**:
  1. Check Wavefront dashboard `dssi-ml-toolkit` for memory trend
  2. Disable unnecessary DAGs temporarily via Airflow UI
  3. Verify the memory-consuming process is an Airflow worker (check DAG metrics in CloudWatch logs)
  4. Run `airflow list_dags -r` via `BashOperator` to identify slow/large DAGs
  5. Notify the DAG author if a specific workflow is the cause
  6. Restart MWAA via dummy `terraform apply`

### Airflow - High CPU Usage

- **Symptoms**: Wavefront "Airflow - High CPU Usage" alert
- **Cause**: Same as High Memory Usage
- **Resolution**: Follow the same steps as [Airflow - High Memory Usage](#airflow---high-memory-usage)

### Ephemeral EMR - Failed to deploy

- **Symptoms**: Wavefront "Ephemeral EMR - Failed to deploy" alert; MWAA DAG fails at EMR create step
- **Cause**: Invalid configuration, CloudCore SCP restriction, spot instance unavailability, or invalid bootstrap script
- **Resolution**:
  1. Compare EMR configuration with the example template in the toolkit
  2. Check with CloudCore (`@cloudcore` in Slack) whether instance types are allowed by SCPs
  3. If using spot instances: ensure an on-demand failover policy is configured
  4. Check EMR bootstrap scripts for shell errors (`install.sh` files in `bootstrap/dssi-build-*/`)
  5. If none of the above apply, contact AWS Support

### Ephemeral EMR - Query Failed

- **Symptoms**: Wavefront "Ephemeral EMR - Query Failed" alert; EMR step exits with error
- **Cause**: Spark container memory/CPU insufficient for the SQL operation, or data quality issue
- **Resolution**:
  1. Increase instance count in the EMR job configuration (DAG input or model config SSM parameter)
  2. Check EMR logs in Kibana (forwarded from S3 via Filebeat)

### SageMaker Endpoint - 400 Bad Request

- **Symptoms**: API Gateway returns 400
- **Cause**: Missing or malformed required parameters in inference request
- **Resolution**: Verify that all required parameters are included and match the JSON schema defined for the endpoint

### SageMaker Endpoint - 403 Forbidden

- **Symptoms**: API Gateway returns 403
- **Cause**: Missing or invalid `X-API-Key` header
- **Resolution**: Confirm the correct API key is being passed in the `X-API-Key` header

### SageMaker Endpoint - 415 Unsupported Media Type

- **Symptoms**: API Gateway returns 415
- **Cause**: Request body is not JSON
- **Resolution**: Set `Content-Type: application/json` and send a JSON body

### SageMaker Endpoint - 424 Model Error

- **Symptoms**: API Gateway returns 424; response contains original SageMaker error message
- **Cause**: SageMaker encountered an application error within the inference container
- **Resolution**: Inspect the `OriginalMessage` in the 424 response; check SageMaker endpoint logs in CloudWatch/Kibana

### SageMaker Endpoint - 503 Service Unavailable

- **Symptoms**: API Gateway returns 503
- **Cause**: SageMaker endpoint unavailable or overwhelmed; possible broader outage
- **Resolution**:
  1. Check API Gateway throttle settings; adjust if needed
  2. Check with CloudSRE for broader AWS outage
  3. If no outage: delete and redeploy the endpoint via `terraform apply`

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | MWAA scheduler down (no DAGs running) | Immediate | P&P DS on-call via PagerDuty; local-ds@groupon.com |
| P2 | Specific model endpoint unavailable | 30 min | P&P DS team; dnd-ds-pnp@groupon.com |
| P3 | EMR job failures, non-critical DAG failures | Next business day | P&P DS team |

PagerDuty alerts configured per [Wavefront PagerDuty integration](https://groupondev.atlassian.net/wiki/spaces/SR/pages/62973838901/Wavefront#Wavefront-HowtocreateaPagerdutyalert).

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| AWS MWAA | Wavefront scheduler heartbeat; CloudWatch log groups receiving data | Destroy and redeploy via Terraform |
| AWS SageMaker endpoints | CloudWatch deployment alarm; API Gateway 200 responses | Delete and redeploy endpoint via `terraform apply` |
| AWS EMR (transient) | Wavefront EMR alerts; CloudWatch/Kibana EMR logs | Re-trigger DAG; adjust instance config; contact CloudCore |
| Centralized logging (ELK/Kinesis) | Check CloudWatch subscription filter status in AWS console | Logs remain in CloudWatch; no automatic fallback |
| Wavefront metrics | Platform metrics dashboard `dssi-ml-toolkit` | No automatic fallback; contact CloudSRE |
