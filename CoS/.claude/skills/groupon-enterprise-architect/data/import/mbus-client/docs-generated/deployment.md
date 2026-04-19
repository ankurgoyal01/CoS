---
service: "mbus-client"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "none"
environments: ["uat", "staging", "production-snc1", "production-sac1", "production-dub1"]
---

# Deployment

## Overview

The MBus Java Client Library is not a deployed service — it is a Maven JAR artifact distributed to embedding Java services. It is built as a standard Maven project using the `maven-shade-plugin` to produce an uber-JAR (`uber-mbus-client-{version}.jar`) in addition to the standard JAR. The artifact is published to Groupon's internal Artifactory repository on every successful merge to `master`. CI is managed by a Jenkins pipeline on Cloud Jenkins.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (build only) | `docker-compose.yml` uses `maven:3.6-jdk-8` image for isolated build/test; not used at runtime |
| Orchestration | None | Library artifact; no server process to orchestrate |
| Load balancer | MBus VIP (external) | Client connects to broker VIP endpoints (`mbus-vip.snc1`, etc.); VIP handles broker-side load balancing |
| CDN | None | Not applicable for a Java library artifact |
| Artifact repository | Artifactory | Releases: `https://artifactory.groupondev.com/artifactory/releases`; Snapshots: `https://artifactory.groupondev.com/artifactory/snapshots` |

## Environments

The library itself is not deployed per environment. The MBus broker endpoints it connects to are environment-specific:

| Environment | Purpose | Region | Broker VIP URL |
|-------------|---------|--------|---------------|
| UAT | Integration testing | snc1 | `http://mbus-uat-vip.snc1:8081` (general) |
| Staging | Pre-production | snc1 | `http://mbus-staging-vip.snc1:8081` (general) |
| Staging EMEA | Pre-production EMEA | snc1 | `http://mbus-emea-staging-vip.snc1:8081` |
| Production NA | North America production | snc1 | `http://mbus-vip.snc1:8081` (general), `http://mbus-m3-vip.snc1:8081` (M3) |
| Production NA Secondary | North America production | sac1 | `http://mbus-vip.sac1:8081` (general), `http://mbus-m3-vip.sac1:8081` (M3) |
| Production EMEA | EMEA production | dub1 | `http://mbus-vip.dub1:8081` (general) |

STOMP connections use port 61613 on the broker VIP host. HTTP dynamic server list fetching uses port 8081.

## CI/CD Pipeline

- **Tool**: Jenkins (Cloud Jenkins)
- **Config**: `Jenkinsfile` (root of repository)
- **Pipeline library**: `java-pipeline-dsl@latest-2`
- **Trigger**: Push to any branch (build only); push to `master` (build + publish artifact to Artifactory)
- **Slack channel**: `CHSN9J0QJ` (build notifications)

### Pipeline Stages

1. **Build**: Runs `mvn -pl java package` via `maven:3.6-jdk-8` Docker image
2. **Test**: Executes unit tests (JUnit 4) with forked JVM (`forkCount=3C`, `reuseForks=false`)
3. **Publish (master only)**: Publishes JAR and sources to Artifactory releases or snapshots repository
4. **Checkstyle** (reporting): Validates code style against `java/checkstyle.xml`
5. **FindBugs** (reporting): Static analysis at `Max` effort with `Low` threshold

## Releasing

The release process is manual and follows these steps (per `DEVELOPMENT.md`):

1. Update the module `java/pom.xml` version to a release version (remove `-SNAPSHOT`)
2. Update `CHANGELOG.md` and remove "in development" label
3. Run `mvn -pl java install` locally to verify
4. Commit with message `release X.X.X` and push to GitHub
5. Wait for CI to publish the artifact to Artifactory releases
6. Update version to next dev snapshot (`X.X.X-SNAPSHOT`) and add new CHANGELOG entry
7. Send announcement to `messagebus-announcements@groupon.com` mailing list

## Scaling

> Not applicable. As a client library embedded in host services, scaling is determined by the host service's deployment configuration. The library's internal thread pool size is configurable via `ConsumerConfig.setThreadPoolSize(int)` (default: 4).

## Resource Requirements

> Not applicable. As a JAR library, resource consumption depends on the host JVM process. The library maintains one thread per broker connection for consumers (`StompServerFetcher` threads) plus keepalive threads.
