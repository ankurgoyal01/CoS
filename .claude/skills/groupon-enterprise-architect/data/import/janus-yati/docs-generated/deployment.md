---
service: "janus-yati"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "dataproc"
environments: ["stable", "prod", "prod-sox"]
---

# Deployment

## Overview

Janus Yati is deployed as a fat JAR artifact uploaded to GCS and executed by Google Cloud Dataproc Spark clusters managed by Apache Airflow. There is no long-running application server. Each Airflow DAG provisions an ephemeral Dataproc cluster, submits the Spark job, and then tears the cluster down when the job completes (or on idle-delete TTL expiry). Long-running streaming jobs (`KafkaToFileJobMain` DAGs) use persistent cluster pools that are periodically refreshed. The JAR is built by Jenkins CI, published to Artifactory, and then staged to a GCS operational bucket for Dataproc node access.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Artifact | Fat JAR (maven-shade-plugin) | `janus-yati-${VERSION}-jar-with-dependencies.jar` uploaded to `gs://prod-us-janus-operational-bucket/jar/` |
| Cluster provisioning | Google Cloud Dataproc 2.1-ubuntu20 | Created per-DAG-run or reused from cluster pool |
| Compute (non-SOX streaming jobs) | n1-standard-4 master + n1-standard-4 / n1-highmem-8 workers | Varies by job; up to 15+ workers for high-throughput ingestion |
| Compute (SOX jobs) | n1-standard-4 master + e2-standard-8 workers | 2 workers per SOX cluster |
| Compute (replay/dedup/vacuum) | n1-highmem-8 master + n1-highmem-8 workers | 5-10 workers |
| Compute (schema/view/BQ) | n1-standard-2 master, zero workers | Schema update jobs run single-node |
| Compute (business metrics) | n2-standard-4 master + n2-highmem-4 workers | 6 workers |
| Cluster init | Init script at `gs://prod-us-janus-operational-bucket/initscript.sh` | Provisions Kafka keystores and Janus Yati config on each node |
| Orchestration | Apache Airflow (managed Airflow control plane) | DAGs loaded from `orchestrator/` directory |
| Networking | Private GCP VPC (internal_ip_only=true) | Subnetwork `sub-vpc-prod-sharedvpc01-us-central1-private` in project `prj-grp-shared-vpc-prod-2511` |
| Load balancer | Not applicable — no inbound traffic | — |
| CDN | Not applicable | — |
| CI/CD | Jenkins (`Jenkinsfile`) | Uses `java-pipeline-dsl@dpgm-1396-pipeline-cicd` shared library |
| Local testing | Docker Compose (`.ci/docker-compose.yml`) | Image `docker.groupondev.com/jtier/dev-java8-maven:2024-04-23-77dca2a` |

## Environments

| Environment | Purpose | Region | GCP Project |
|-------------|---------|--------|-------------|
| stable | Pre-production integration testing | us-central1 | stable GCP project |
| prod | Production — NA and EMEA event ingestion | us-central1 | `prj-grp-janus-prod-0808` |
| prod-sox | Production — SOX-scoped event ingestion with isolated service account and GCS paths | us-central1 | `prj-grp-janus-prod-0808` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` (root of repo)
- **Trigger**: Push to `main` branch; also supports manual dispatch
- **Notification**: Slack channel `#janus-robots` on any failure; commit author is pinged
- **Deploy target**: `production-us-central1`

### Pipeline Stages

1. **Build and Test**: Runs `mvn -U -B clean verify -DskipDocker=true -Ddockerfile.skip=true` inside the Docker CI container; executes unit tests and integration tests using TestContainers (Kafka) and WireMock
2. **Deploy (pre-release)**: Runs `mvn -U -B clean deploy -DskipTests -DskipDocker=true -Ddockerfile.skip=true -Drevision=$ARTIFACT_VERSION`; publishes the JAR to Artifactory at `https://artifactory.groupondev.com/artifactory/releases/com/groupon/data-engineering/janus-yati/`
3. **Stage to GCS**: (inferred) JAR is staged from Artifactory to `gs://prod-us-janus-operational-bucket/jar/` so Dataproc clusters can access it at job submission time via the `yati_jar` config parameter

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (streaming jobs) | Fixed executor instances per job | `spark.executor.instances` 3-31 per job; `spark.dynamicAllocation.enabled=false` for most jobs |
| Horizontal (maintenance jobs) | Dynamic allocation | `spark.dynamicAllocation.enabled=true` for dedup, vacuum, raw-source jobs |
| Horizontal (cluster workers) | Per-DAG cluster config in YAML | 2-15 workers depending on job type |
| Spark executor memory | Fixed per job | 3G-24G depending on job; e.g., Juno job: `spark.executor.memory=20G`, `spark.driver.memory=24G` |
| Spark executor CPU | Fixed per job | `spark.executor.cores` 4-8 per job |
| Kafka throughput | `--maxOffsetsPerTrigger` and `--batchIntervalMs` | Janus-all: 5-7M offsets per trigger, 100-180s batch; raw sources: 200K-400K offsets, 120s batch |

## Resource Requirements

| Resource | Streaming (janus-all-juno) | Schema update | Replay |
|----------|---------------------------|---------------|--------|
| Executor memory | 20G | not applicable (zero workers) | 2G per executor |
| Driver memory | 24G | not applicable | 2G |
| Executor cores | 8 | not applicable | 4 |
| Executor instances | 15 | not applicable | 31 |
| Workers | 15 x n1-highmem-8 | 0 | 10 x n1-standard-8 |
| Disk (per node) | 100 GB pd-standard | 100 GB pd-standard | 100 GB pd-standard |
