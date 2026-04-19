---
service: "clam"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "yarn"
environments: [staging-snc, prod-snc, prod-sac, prod-dub]
---

# Deployment

## Overview

CLAM is deployed as an Apache Spark application on Groupon's internal Hadoop/YARN cluster (gdoop). It is not containerized for runtime (Docker is used only as the CI build environment). The job runs in YARN cluster deploy-mode as a long-lived streaming application. It is submitted and restarted automatically by gdoop-cron using the `YARNApplicationRestarter` scheduler class, which polls every minute and resubmits the job if it is not running. Deployment of a new release is managed by Ansible playbooks.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container (CI build only) | Docker | `docker.groupondev.com/jtier/dev-java11-maven:2020-06-22-619d341` — used for building the artifact, not for running the job |
| Runtime orchestration | Apache YARN | `--master yarn --deploy-mode cluster`; YARN queue: `clam` |
| Job scheduler / restarter | gdoop-cron (`YARNApplicationRestarter`) | Configured via `/home/svc_clam/gdoop-cron/config.yml`; cron expression `0 0/1 * * * ?` (every minute) |
| Spark runtime | Apache Spark 2.4.3 | Installed at `/var/groupon/spark-2.4.3` on job-submitter hosts |
| Artifact repository | Nexus | Release tarballs fetched from `nexus-app1-dev.snc1` |
| Load balancer | None | CLAM has no inbound HTTP traffic |

## Environments

| Environment | Purpose | Region | Hosts |
|-------------|---------|--------|-------|
| staging | Testing / QA | snc1 | `gdoop-metrics-job-submitter1-staging.snc1` |
| production (snc) | Production | snc1 | `gdoop-metrics-job-submitter1.snc1` |
| production (sac) | Production | sac1 | `gdoop-metrics-job-submitter1.sac1` |
| production (dub) | Production | dub1 | `gdoop-metrics-job-submitter1.dub1` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` at repo root
- **Trigger**: On push to `master` branch (release pipeline via `mavenReleasePipeline` shared library)
- **Slack notifications**: `#bot---metrics`

### Pipeline Stages

1. **Build**: Maven compiles source and runs unit tests (`mvn test`); JaCoCo coverage checks enforced (60% line coverage minimum per class)
2. **Package**: Maven Shade Plugin produces a fat JAR; Maven Assembly Plugin packages a distribution tarball (`clam-<version>-distribution.tar.gz`)
3. **Release**: `maven-release-plugin` tags the commit and publishes the artifact to Nexus (`http://nexus-app1-dev.snc1/content/repositories/releases/`)
4. **Deploy (Ansible)**: `ansible/submit.yml` playbook downloads the tarball from Nexus, unpacks it to `/home/svc_clam/releases/<version>/`, updates the `current` symlink, kills the running YARN application, and waits up to 5 minutes for the new application to reach `RUNNING` state

### Deployment Parameters (Ansible)

| Parameter | Purpose |
|-----------|---------|
| `version` | Release version to deploy (e.g., `2.1.24`) |
| `artifact_version` | Optional override for artifact filename version (defaults to `version`) |
| `env` | Target environment (`prod` or `staging`) |
| `region` | Target colo (`snc`, `sac`, `dub`) |
| `delete_hdfs` | If `"true"`, deletes the HDFS checkpoint directory before restarting (use for breaking state changes) |

## Scaling

| Dimension | Strategy | Config (prod-snc) |
|-----------|----------|--------|
| Executor count | Manual (set at job submission) | `--num-executors 50` |
| Executor cores | Manual | `--executor-cores 4` |
| Executor memory | Manual | `--executor-memory 22G` |
| Driver cores | Manual | `--driver-cores 2` |
| Driver memory | Manual | `--driver-memory 8G` |
| Stream repartitioning | Manual (`repartitionCount`) | 200 partitions in production |
| Dynamic allocation | Disabled | `spark.dynamicAllocation.enabled=false` |

## Resource Requirements

| Resource | Driver | Per Executor |
|----------|---------|-------------|
| CPU (cores) | 2 | 4 |
| Memory | 8 GB | 22 GB |
| Disk | Not separately configured | Not separately configured |

### Key Spark Configuration

| Spark Property | Value | Purpose |
|---------------|-------|---------|
| `spark.serializer` | `org.apache.spark.serializer.KryoSerializer` | Efficient serialization for TDigest group state |
| `spark.kryoserializer.buffer.max` | `1024m` | Handles large serialized TDigest state objects |
| `spark.kryoserializer.buffer` | `512` | Default Kryo buffer |
| `spark.speculation` | `true` | Re-launches slow tasks speculatively |
| `spark.speculation.multiplier` | `2` | Threshold multiplier for speculation |
| `spark.speculation.quantile` | `0.90` | 90th-percentile threshold for speculation |
| `spark.driver.maxResultSize` | `5G` | Allows large driver result sets |
| `spark.network.timeout` | `250` (seconds) | Network timeout for executor communication |
| `spark.sql.broadcastTimeout` | `1200` (seconds) | Timeout for broadcast join operations |
| `spark.yarn.submit.waitAppCompletion` | `false` | Submit returns immediately; YARN manages lifetime |
