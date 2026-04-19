---
service: "clam-load-generator"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "conveyor-cloud (kubernetes-compatible)"
environments: [uat, staging, production]
---

# Deployment

## Overview

The CLAM Load Generator is packaged as a Docker container (built on `maven:3.6.3-jdk-11`) and published to Groupon's internal Docker registry at `docker-conveyor.groupondev.com/metrics/`. It is run as a short-lived Conveyor Cloud pod rather than a continuously running service — it executes its load generation run and exits. CI/CD is managed by a Jenkins shared library pipeline (`java-pipeline-dsl`). Container images are tagged by version (e.g., `pod-load-generator:1.0.0`).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` at repo root; base image `maven:3.6.3-jdk-11` |
| Build (inside container) | Maven 3.6.3 | `mvn -f /app/pom.xml clean package` |
| Orchestration | Conveyor Cloud (Kubernetes-compatible) | Short-lived pod; not a persistent deployment |
| Load balancer | None | No inbound HTTP traffic |
| CDN | None | Not applicable |
| Docker registry | `docker-conveyor.groupondev.com` | Namespace: `metrics/` |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| UAT | Load testing against UAT Telegraf agents | snc1 | `http://telegraf-agent1-uat.snc1:8186/` (example `TARGET_URL`) |
| Staging | Load and break scenario testing against staging Kafka/Telegraf | snc1 | Configured via profile YAML (`kafka-08-broker-staging-vip.snc1:9092`) |
| Production (Dublin) | Production break scenario validation | dub1 | Referenced in `application-kafka-prod-dub-break.yml` |

## CI/CD Pipeline

- **Tool**: Jenkins (shared library `java-pipeline-dsl@latest-2`)
- **Config**: `Jenkinsfile` at repo root
- **Trigger**: Push to `master` branch (releasable branch)
- **Slack notifications**: `#bot---metrics`

### Pipeline Stages

1. **Build and package**: Maven compiles source and packages the fat JAR via `spring-boot-maven-plugin` (layout: ZIP)
2. **Docker build**: Builds the container image, copying the pre-built JAR into `/usr/local/lib/load-generator.jar`
3. **Docker publish**: Tags and pushes to `docker-conveyor.groupondev.com/metrics/pod-load-generator:<version>`

### Manual Docker build and publish

```
docker build -t pod-load-generator:1.0.0 .
docker tag pod-load-generator:1.0.0 docker-conveyor.groupondev.com/metrics/pod-load-generator:1.0.0
docker push docker-conveyor.groupondev.com/metrics/pod-load-generator:1.0.0
```

### Default container entrypoint

The container's `CMD` automatically runs the `sma-load-test` profile:

```
java -jar /usr/local/lib/load-generator.jar --spring.profiles.active=sma-load-test
```

To run a different profile, override the command when launching the pod.

### Local JAR execution

```
java -jar target/load-generator-1.0.0.jar --spring.profiles.active=<profile>
```

For a custom configuration file:

```
java -jar target/load-generator-1.0.0.jar --spring.config.additional-location=file:./custom-config.yml
```

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Manual — launch additional pods with independent profiles | N/A |
| Concurrency | Configured via `generator.threads` in profile YAML | Default: 1–20 threads depending on profile |
| Throughput | Configured via `generator.rate-per-second` | Range: 1 ops/sec (integration test) to 20,000 ops/sec (telegraf load test) |

## Resource Requirements

> No evidence found in codebase. Resource requests and limits are managed externally by Conveyor Cloud pod specifications.

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Deployment configuration managed externally | Deployment configuration managed externally |
| Memory | Deployment configuration managed externally | Deployment configuration managed externally |
| Disk | Minimal — no persistent storage | N/A |
