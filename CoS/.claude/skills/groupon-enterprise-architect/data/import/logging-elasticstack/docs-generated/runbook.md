---
service: "logging-elasticstack"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/_cluster/health` (Elasticsearch) | http | Kubernetes liveness probe interval | Per probe config |
| `/api/status` (Kibana) | http | Kubernetes readiness probe interval | Per probe config |
| Kafka consumer group lag (Telegraf) | metrics | Telegraf scrape interval | — |
| Kubernetes pod readiness (ECK / Helm) | exec | Kubernetes readiness probe interval | Per probe config |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Elasticsearch cluster status | gauge | Red/yellow/green cluster health (`/_cluster/health`) | Alert on red; warn on yellow |
| Elasticsearch indexing rate | counter | Documents indexed per second across all indices | Alert on sustained drop to zero |
| Elasticsearch JVM heap usage | gauge | JVM heap used percentage per node | Alert above 85% |
| Elasticsearch search latency | histogram | P99 search query latency | Alert above configured SLA threshold |
| Kafka consumer group lag (`logging_<env>_<sourcetype>`) | gauge | Number of unconsumed messages per topic/partition in Logstash consumer group | Alert when lag grows unboundedly |
| Logstash pipeline throughput | counter | Events processed per second by Logstash pipeline | Alert on sustained drop |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Elasticsearch Cluster Health | Wavefront | Configured per cluster in Wavefront; URL defined by Logging Platform Team |
| Kafka Consumer Lag | Wavefront | Configured per environment; URL defined by Logging Platform Team |
| Logstash Pipeline Metrics | Kibana Monitoring | Available in Kibana Stack Monitoring at `:5601/app/monitoring` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| ES Cluster Red | `/_cluster/health` returns `red` | critical | Investigate unassigned shards; check node availability; escalate to Logging Platform Team |
| Kafka Consumer Lag Growing | Consumer group lag increasing over 15 minutes | warning | Check Logstash pipeline status; restart Logstash if stalled; investigate filter parse errors |
| ES JVM Heap Critical | JVM heap > 85% sustained | critical | Force GC or restart affected Elasticsearch node; consider adding nodes or reducing shard count |
| Logstash Pipeline Stalled | Zero events processed for > 5 minutes | warning | Check Logstash logs for exceptions; verify Kafka connectivity; restart Logstash pipeline |
| ES Disk Watermark Reached | Disk usage above 85% (low watermark) | warning | Trigger index deletion or rollover; review ILM policy; add disk capacity or reduce retention |

## Common Operations

### Restart Service

**Logstash (GKE)**:
1. Identify the Logstash deployment: `kubectl get pods -n <namespace> -l app=logstash`
2. Perform rolling restart: `kubectl rollout restart deployment/logstash -n <namespace>`
3. Monitor rollout: `kubectl rollout status deployment/logstash -n <namespace>`
4. Verify consumer group offset resumes: check Kafka lag in Wavefront dashboard

**Elasticsearch (GKE/ECK)**:
1. ECK operator manages rolling restarts; update the Elasticsearch CR to trigger: `kubectl annotate elasticsearch <name> common.k8s.elastic.co/co-rollover-restart=$(date +%s) -n <namespace>`
2. Monitor cluster health during restart: `curl -u <creds> http://$ELASTICSEARCH_API_VIP/_cluster/health?wait_for_status=yellow`

**On-prem (Ansible)**:
1. Run the appropriate Ansible playbook targeting the specific role (logstash/elasticsearch/kibana)
2. Monitor service restart via ClusterShell: `clush -g <group> 'systemctl status elasticsearch'`

### Scale Up / Down

**GKE (Logstash)**:
1. Update Helm chart values for replica count: `helm upgrade <release> <chart> --set logstash.replicas=<N> -n <namespace>`
2. Monitor pod scheduling: `kubectl get pods -n <namespace> -w`

**GKE (Elasticsearch)**:
1. Edit the Elasticsearch ECK resource node count: `kubectl edit elasticsearch <name> -n <namespace>`
2. ECK operator handles node addition/removal and shard rebalancing automatically

**On-prem**:
1. Add node to Ansible inventory
2. Run provisioning playbook targeting the new node
3. Elasticsearch cluster auto-discovers and rebalances shards to the new node

### Database Operations

**Trigger manual ES snapshot to S3**:
1. Call `POST /_snapshot/<repository>/<snapshot_name>` via Elasticsearch API
2. Monitor: `GET /_snapshot/<repository>/<snapshot_name>`

**Force ILM policy step execution**:
1. Check current ILM step: `GET /<index>/_ilm/explain`
2. Move to next step if stuck: `POST /_ilm/move/<index>` with target step body

**Delete old indices manually**:
1. List indices: `GET /_cat/indices/<pattern>?v&s=index`
2. Delete: `DELETE /<index_name>`

## Troubleshooting

### Logstash Grok Parse Failures
- **Symptoms**: Events in Elasticsearch tagged with `_grokparsefailure`; error index receiving high volume; sourcetype data missing parsed fields
- **Cause**: Log format change in producer service not reflected in Logstash filter config
- **Resolution**: Update the sourcetype Logstash filter `.conf` file; run filter unit tests; deploy updated Logstash via Jenkins pipeline

### Kafka Consumer Lag Not Decreasing
- **Symptoms**: Wavefront shows Logstash consumer group lag growing; log events delayed in Kibana
- **Cause**: Logstash pipeline stalled (filter exception, ES write rejection) or Logstash pod OOM
- **Resolution**: Check Logstash logs for exceptions; increase Logstash JVM heap or replica count; verify Elasticsearch write availability

### Elasticsearch Red Cluster Status
- **Symptoms**: `/_cluster/health` returns `red`; Kibana shows cluster health alert; Logstash write errors
- **Cause**: One or more primary shards unassigned (node failure, disk full, or allocation filter mismatch)
- **Resolution**: Run `GET /_cluster/allocation/explain` to identify unassigned shards; address root cause (add node, free disk, fix allocation filter); shards auto-recover once nodes rejoin

### Kibana Login Failure
- **Symptoms**: Engineers unable to authenticate to Kibana; Okta redirect loop or 401 errors
- **Cause**: Okta application configuration change, Kibana certificate expiry, or Kibana pod unavailable
- **Resolution**: Check Kibana pod status in GKE; verify Okta application integration; check TLS certificate expiry; review Kibana logs for auth errors

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Elasticsearch cluster down — all log ingestion and search unavailable | Immediate | Logging Platform Team (jsermersheim, seborys, dartiukhov) |
| P2 | Logstash stalled — log ingestion delayed, search of recent logs unavailable | 30 min | Logging Platform Team |
| P3 | Kibana unavailable — log search UI inaccessible, ingestion unaffected | Next business day | Logging Platform Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Elasticsearch | `GET /_cluster/health` returns `green` or `yellow` | Logstash buffers writes in Kafka; replay possible after ES recovery |
| Apache Kafka | Monitor consumer group lag in Wavefront; verify broker connectivity | Filebeat in-memory queue holds events during short Kafka outages; extended outages cause event loss |
| Okta | Kibana login page loads and redirects to Okta | No fallback — Kibana inaccessible without Okta |
| AWS S3 | Snapshot API returns success status | Snapshot failures are non-blocking; log ingestion and search unaffected |
| Wavefront | Check Wavefront dashboard data freshness | Platform continues operating without metrics; manual `/_cluster/health` polling as fallback |
