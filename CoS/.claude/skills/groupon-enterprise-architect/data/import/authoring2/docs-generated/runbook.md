---
service: "authoring2"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /props` | HTTP (readiness probe) | 20s | — |
| `GET /props` | HTTP (liveness probe) | 20s | — |
| `GET /grpn/healthcheck` | HTTP (load-balancer heartbeat) | — | — |
| `GET /status.json` | HTTP (application health + version) | — | — |
| ActiveMQ TCP port 61616 | TCP socket (sidecar readiness) | 30s | — |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | gauge | Requests per minute to API endpoints | Wavefront alert — see dashboard |
| HTTP error rate | counter | Count of 4xx/5xx responses | Wavefront alert — see dashboard |
| JVM memory usage | gauge | Heap and non-heap memory via Micrometer JMX/InfluxDB | Wavefront alert |
| DB query latency | histogram | PostgreSQL round-trip latency via JPA | Latency spike triggers Wavefront alert |
| Redis latency | gauge | Referenced in runbook; no direct Redis dependency confirmed in code |

Metrics are exported via `micrometer-registry-influx` to InfluxDB and `micrometer-registry-jmx` for local JMX access on port `8009`.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Taxonomy Authoring (primary) | Wavefront | `https://groupon.wavefront.com/u/sDKG07VFBD?t=groupon` |
| Conveyor Cloud Customer Metrics | Wavefront | `https://groupon.wavefront.com/dashboards/Conveyor-Cloud-Customer-Metrics` |
| SAC1/SNC1 Taxonomy Authoring | Wavefront | `https://groupon.wavefront.com/dashboard/sac1_snc1-taxonomy-authoring` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Latency alert | Redis or DB latency spike | warning | Check Redis and DB latencies; reach out to respective service owners |
| Error rate alert | Elevated 4xx/5xx rate | warning/critical | Review ELK logs for exception details; delete affected pod if single-pod issue |
| PagerDuty page | Service health degraded | critical | See incident response section below |

Alert notifications: `taxonomy-alerts@groupon.com`, PagerDuty service `PVUUEHR`, Slack channel `#taxonomy` (ID: `CF7MW8SJV`).

## Common Operations

### Restart Service

**Cloud (Kubernetes):**
```sh
# Delete the impacted pod; Kubernetes automatically creates a replacement
kubectl -n <namespace> delete pod <pod_name>

# Or restart the full deployment
kubectl -n <namespace> rollout restart deployment/authoring2
```

**On-premises (Apache Tomcat):**
```sh
sudo /usr/local/etc/init.d/apache-tomcat.sh stop
sudo /usr/local/etc/init.d/apache-tomcat.sh start
```

**ActiveMQ (on-premises):**
```sh
sudo /usr/local/activemq/bin/activemq stop
sudo /usr/local/activemq/bin/activemq start xbean:/usr/local/activemq/conf/activemq.xml
```

### Scale Up / Down

**Cloud:** Adjust `minReplicas` / `maxReplicas` in the relevant environment YAML under `.meta/deployment/cloud/components/app/` and redeploy, or use the Deploybot UI.

```sh
kubectl scale deployment authoring2 --replicas=<N> -n <namespace>
```

### Heartbeat Management

```sh
# Enable traffic (on-premises)
sudo touch /var/groupon/nginx/heartbeat.txt

# Disable traffic (on-premises)
sudo rm /var/groupon/nginx/heartbeat.txt
```

### Deploy a New Release

1. Merge PR to `devel` branch.
2. Run `mvn clean release:clean release:prepare release:perform` to create a versioned release in Artifactory.
3. Go to `https://deploybot.groupondev.com/hawk/authoring2` and deploy to staging.
4. Verify staging via status endpoint and smoke tests.
5. Obtain CAT approval at `https://cat.groupondev.com/generic_client`.
6. Promote staging (`us-west-1`) to production via Deploybot.

### Rollback

Use Deploybot to re-deploy the previous version. The previous artifact remains available in Artifactory.

### Database Operations

- Connect to the production database via SSH tunnel:
  ```sh
  ssh -f -N -L <LOCAL_PORT>:<DB_VIP>:<DB_VIP_PORT> <USER>@<APP_HOST>
  ```
- Database host (production): `taxonomyV2-rw-na-production-db.gds.prod.gcp.groupondev.com`, port `5432`, database `taxonomyv2_prod`.
- No automated migration tooling is present in the repository. Schema changes are applied manually or via DaaS procedures.

## Troubleshooting

### Elevated Error Rate

- **Symptoms**: Wavefront error rate alert fires; ELK logs show exceptions
- **Cause**: May be downstream dependency failure (DB unavailable, TaxonomyV2 unreachable), pod OOM kill, or application bug
- **Resolution**:
  1. Open Wavefront dashboard to identify which endpoint is throwing errors.
  2. Check [ELK logs](https://logging-prod-us-unified1.grpn-logging-prod.us-west-2.aws.groupondev.com/goto/30d4507b6d1f91ab1f14593e126e1c97) for exception stack traces.
  3. If a single pod is impacted: `kubectl delete pod <pod_name>` — a replacement is created automatically.
  4. If all pods are impacted: check [ELK logs](https://logging-prod-us-unified1.grpn-logging-prod.us-west-2.aws.groupondev.com/goto/67d784db21a28f1d27238e50f6db2537) for downstream service errors; contact relevant team.

### Snapshot Stuck in PENDING

- **Symptoms**: `POST /snapshots/create` returns 400 with message "There is a snapshot being generated, please wait!"
- **Cause**: A previous snapshot generation job is in `PENDING` status and has not completed (possibly due to a crash mid-processing).
- **Resolution**: Check the `Snapshots` table for rows with `status = PENDING`. If the ActiveMQ consumer is no longer processing the message, manually update the status to `failed` in the database and restart the pod to drain the queue.

### Bulk Job Not Progressing

- **Symptoms**: `GET /bulk/{guid}` returns `percent = 0` indefinitely
- **Cause**: ActiveMQ sidecar is down; or `BulkQueueListener` is not running (pod restart mid-job)
- **Resolution**: Verify ActiveMQ sidecar is running: `kubectl describe pod <pod>`. Check TCP connectivity to port 61616. Restart the pod to re-establish the JMS consumer.

### High DB Latency

- **Symptoms**: Wavefront DB latency alert fires; API endpoints are slow
- **Cause**: Long-running export queries (CSV/XLS generation for large taxonomies); or DaaS infrastructure issue
- **Resolution**: Check for concurrent CSV export requests (limited to 2 by semaphore). Contact DaaS team if infrastructure-level issue. Check Wavefront DB latency dashboard.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down; authoring unavailable | Immediate | `taxonomy-alerts@groupon.com`, PagerDuty `PVUUEHR` |
| P2 | Degraded functionality; bulk jobs failing or snapshots blocked | 30 min | Slack `#taxonomy`, `taxonomy-dev@groupon.com` |
| P3 | Minor impact; single endpoint errors or slow performance | Next business day | `taxonomy-dev@groupon.com` |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| PostgreSQL (DaaS) | Application startup fails if DB is unreachable; `/props` readiness probe covers indirectly | No fallback; service is unusable without DB |
| ActiveMQ sidecar | TCP socket probe on port 61616 (180s initial delay) | Bulk and snapshot operations fail with JMS connection errors; read-only endpoints remain functional |
| `continuumTaxonomyService` | HTTP response from activation PUT call | Snapshot deploy fails with HTTP 500; taxonomy content is unaffected in Authoring2 |
