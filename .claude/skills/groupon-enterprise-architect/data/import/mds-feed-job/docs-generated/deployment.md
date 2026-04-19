---
service: "mds-feed-job"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "spark-on-hadoop"
environments: [development, staging, production]
---

# Deployment

## Overview

MDS Feed Job is a Spark batch application packaged as a fat JAR (Maven Shade plugin) and submitted to a Hadoop/Spark cluster via Apache Livy or an external job scheduler. It does not run as a persistent service; each feed generation run is a discrete job submission. The job reads from and writes to GCS/HDFS, and calls external services over HTTPS. There is no Kubernetes deployment, load balancer, or CDN.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Packaging | Maven Shade (fat JAR) | Built via `mvn package`; produces a self-contained JAR with all dependencies |
| Job submission | Apache Livy | REST-based Spark job submission to Hadoop cluster |
| Scheduler | External scheduler (cron / orchestration platform) | Triggers Livy submissions on feed run schedule |
| Distributed storage | GCS + HDFS | Hadoop Client 3.3.6 with GCS connector for snapshot reads and feed output writes |
| Container | Docker (build only) | Dockerfile used for reproducible build environment; not used at runtime |
| Load balancer | none | Not applicable — batch job, not a service |
| CDN | none | Not applicable |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development and unit testing | local | `--master local[*]` |
| staging | Integration testing and pre-production validation | us-central1 / cluster | Livy staging endpoint |
| production | Live feed generation for all marketing channels | us-central1 / cluster | Livy production endpoint |

## CI/CD Pipeline

- **Tool**: CI/CD pipeline (details managed externally)
- **Config**: `pom.xml` (Maven build), external pipeline configuration
- **Trigger**: On merge to main branch; manual dispatch for ad-hoc runs

### Pipeline Stages

1. **Build**: `mvn clean package -DskipTests` produces fat JAR artifact
2. **Unit Test**: `mvn test` runs unit and integration tests
3. **Artifact Publish**: JAR uploaded to artifact repository (e.g., Nexus/Artifactory)
4. **Deploy to Staging**: Livy job submission with staging configuration
5. **Smoke Test**: Validate feed output in GCS staging bucket
6. **Deploy to Production**: Livy job submission with production configuration on schedule

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Spark dynamic allocation or fixed executor count at submission | Configured via `--num-executors` / `spark.dynamicAllocation` |
| Memory | Spark executor memory set at submit time | `--executor-memory` (e.g., 8g–32g depending on feed type) |
| CPU | Spark executor cores set at submit time | `--executor-cores` (e.g., 4 cores per executor) |
| Driver | Fixed driver memory at submit | `--driver-memory` (e.g., 4g) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 4 cores per executor | Cluster-policy dependent |
| Memory | 8–32 GB per executor (feed-type dependent) | Cluster-policy dependent |
| Disk | HDFS/GCS spill space | Cluster-managed |

> Deployment configuration for specific cluster endpoints, resource quotas, and Livy submission parameters is managed externally by the MIS platform team.
