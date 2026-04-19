---
service: "logging-elasticstack"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 6
internal_count: 1
---

# Integrations

## Overview

The Logging Elastic Stack integrates with 6 external systems: Elastic Stack components (Elasticsearch, Kibana, Filebeat), Apache Kafka for log buffering, Wavefront TSDB for operational metrics, Okta for authentication, AWS S3 for snapshot storage, and GCP GKE for Kubernetes-based deployment. Internally, the platform serves all Groupon services as log producers via Filebeat agent deployment. The `metricsStack` and `messageBus` are shared infrastructure stubs in the central architecture model.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Elastic Stack (ES/Kibana/Filebeat) | embedded | Core ELK platform components — log processing, storage, and search | yes | `continuumLoggingElasticsearch`, `continuumLoggingKibana`, `continuumLoggingFilebeat` |
| Apache Kafka | kafka | Log event message buffer between Filebeat and Logstash | yes | `messageBus` |
| Wavefront TSDB | Wavefront API | Operational metrics and cluster health dashboards | no | `metricsStack` |
| Okta | OAuth 2.0 / SAML | SSO authentication for Kibana UI and API access | yes | — |
| AWS S3 | AWS SDK (boto3) | Elasticsearch snapshot and backup repository storage | no | — |
| GCP GKE | Kubernetes API / Helm | Container orchestration for cloud-based cluster deployment | yes | — |

### Apache Kafka Detail

- **Protocol**: Kafka producer/consumer (Filebeat Kafka output plugin, Logstash Kafka input plugin)
- **Base URL / SDK**: Configured via `KAFKA_ENDPOINT` and `KAFKA_PREFIX` environment variables
- **Auth**: SASL/SSL as configured in Filebeat and Logstash Kafka plugin settings
- **Purpose**: Decouples log ingestion (Filebeat) from log processing (Logstash); buffers bursts in log volume; provides replay capability for Logstash restarts
- **Failure mode**: Filebeat applies back-pressure or drops events per configured queue limits; Logstash stalls processing until Kafka becomes available
- **Circuit breaker**: No circuit breaker; Logstash consumer group offsets allow safe replay on reconnect

### Wavefront TSDB Detail

- **Protocol**: Wavefront API / Telegraf agent push
- **Base URL / SDK**: Configured via Telegraf Wavefront output plugin and ES Watcher HTTP output
- **Auth**: Wavefront API token
- **Purpose**: Receives Elasticsearch cluster operational metrics (JVM heap, indexing rate, search latency, shard health) and Kafka consumer lag; powers dashboards and PagerDuty alert routing
- **Failure mode**: Metrics emission failures are non-blocking for log processing; dashboards become stale
- **Circuit breaker**: No circuit breaker configured

### Okta Detail

- **Protocol**: OAuth 2.0 / SAML 2.0
- **Base URL / SDK**: Configured in Kibana `xpack.security.authc` settings
- **Auth**: Okta application integration for Kibana; engineers authenticate via Okta SSO at `:5601/login`
- **Purpose**: Provides SSO access control for Kibana UI and REST API; ensures only authorized Groupon engineers can query logs
- **Failure mode**: Kibana becomes inaccessible for SSO-authenticated users; no fallback local auth
- **Circuit breaker**: No circuit breaker; Okta is an external SaaS dependency

### AWS S3 Detail

- **Protocol**: AWS SDK (boto3)
- **Base URL / SDK**: boto3 configured with IAM role or access key credentials
- **Auth**: AWS IAM credentials (access key / role)
- **Purpose**: Stores Elasticsearch index snapshots for disaster recovery and long-term archival of aged-out log data
- **Failure mode**: Snapshot operations fail gracefully; log ingestion and search continue unaffected
- **Circuit breaker**: No circuit breaker

### GCP GKE Detail

- **Protocol**: Kubernetes API, Helm
- **Base URL / SDK**: Configured via kubeconfig and Helm chart values
- **Auth**: GCP service account / kubeconfig credentials
- **Purpose**: Hosts containerized Logstash, Elasticsearch (ECK), and Kibana workloads in cloud regions; managed via Helm charts and Krane for rolling deployments
- **Failure mode**: Deployment failures roll back via Helm revision history; Kubernetes self-heals container restarts
- **Circuit breaker**: Kubernetes liveness/readiness probes provide health gating

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| All Groupon services (as log producers) | Filebeat agent (file harvesting) | Filebeat agents deployed alongside every Groupon service; collect log files and stdout streams; ship events to Kafka topics | `continuumLoggingFilebeat` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. All Groupon service teams consume the logging platform via Kibana UI or Elasticsearch API for log search and incident triage.

## Dependency Health

- **Elasticsearch**: Kibana health endpoint at `/api/status`; ES cluster health via `/_cluster/health`
- **Kafka**: Consumer group lag monitored via Telegraf and surfaced in Wavefront dashboards
- **Okta**: Monitored by Okta's own status page; Kibana login failures surface as authentication errors
- **AWS S3**: Snapshot operation results returned in Elasticsearch `/_snapshot` API responses; boto3 script exit codes
- **GCP GKE**: Kubernetes readiness/liveness probes on all workloads; Helm deployment status via `helm status`
