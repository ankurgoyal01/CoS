---
service: "zookeeper"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "docker"
environments: [development, staging, production]
---

# Deployment

## Overview

ZooKeeper is deployed as a JVM process managed by shell scripts (`bin/zkServer.sh`). A Docker development environment is provided at `dev/docker/Dockerfile` using `maven:3.8.4-jdk-11` as the base image. The main entry point class is `org.apache.zookeeper.server.quorum.QuorumPeerMain`. Production ensemble deployment configuration (Kubernetes, ECS, or bare-metal) is managed externally by the Continuum Platform team and is not included in this repository.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `dev/docker/Dockerfile` (base: `maven:3.8.4-jdk-11`; includes C build dependencies: g++, cmake, autoconf, OpenSSL, libsasl2) |
| Orchestration | External (not in repo) | Production orchestration managed externally by Continuum Platform team |
| Load balancer | Not applicable | Clients connect directly to ensemble members; leader election is internal |
| CDN | None | ZooKeeper is a backend TCP service with no CDN requirement |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local single-node testing and development | Local | `localhost:2181` |
| Staging | Integration testing with multi-node quorum | Not specified in repo | Not specified in repo |
| Production | Live Continuum Platform coordination ensemble | Not specified in repo | Not specified in repo |

## CI/CD Pipeline

- **Tool**: GitHub Actions + Jenkins
- **Config**: `.github/workflows/ci.yaml` (GitHub Actions); `Jenkinsfile` (Jenkins daily build)
- **Trigger**: On push/PR to any branch (GitHub Actions); daily (`@daily` cron) via Jenkins

### Pipeline Stages

1. **Checkout**: Retrieves source code at the target branch
2. **Set up JDK**: Configures Eclipse Temurin JDK 8 or 11 via `actions/setup-java@v4` with Maven cache
3. **Install C Dependencies**: Installs `libcppunit-dev` and `libsasl2-dev` for C client compilation
4. **Build with Maven**: Runs `mvn -Pfull-build apache-rat:check verify spotbugs:check checkstyle:check` — covers license checks, compilation, unit tests, static analysis, and style enforcement
5. **Upload test results**: Uploads surefire and failsafe reports on failure
6. **Upload C unit test logs**: Uploads cppunit test logs on failure
7. **Typo Check**: Runs `crate-ci/typos@v1.22.4` on pull requests only

Jenkins additionally runs `spotbugs:check checkstyle:check -Pfull-build -Dsurefire-forkcount=4` across both JDK 8 and JDK 11 in a matrix build.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Manual quorum expansion (add server entries to `zoo.cfg`) | Odd number of nodes recommended (3, 5, 7) for quorum majority |
| Memory | Manual — configure `ZK_SERVER_HEAP` env var | Default 1000 MB; increase for large znode trees |
| CPU | Manual — configure JVM thread pools | Configured via `SERVER_JVMFLAGS` |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not specified in repo | Not specified in repo |
| Memory | 1000 MB (default `ZK_SERVER_HEAP`) | Configurable via `ZK_SERVER_HEAP` env var |
| Disk | Sufficient for `dataDir` snapshots and transaction logs | Dependent on write throughput; autopurge recommended in production |

> Deployment configuration managed externally. Kubernetes manifests, ECS task definitions, and environment-specific resource limits are not present in this repository.
