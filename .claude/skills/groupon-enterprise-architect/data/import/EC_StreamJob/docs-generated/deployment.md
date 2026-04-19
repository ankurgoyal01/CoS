---
service: "EC_StreamJob"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "yarn"
environments: ["uat", "staging", "emea_staging", "production", "production_emea"]
---

# Deployment

## Overview

EC_StreamJob is deployed as a fat JAR (assembled via `maven-shade-plugin`) submitted directly to a Hadoop YARN cluster using `spark-submit`. It is not containerized. Deployment is managed by Capistrano (`uber_deploy`) which copies the JAR from Nexus to a designated folder on a Spark job-submitter host, then symlinks it. The operator manually triggers `spark-submit` on the submitter host after deployment. Two independent instances run permanently — one per data center (snc1 for NA, dub1 for EMEA).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | No Docker or container runtime; plain JAR deployment |
| Orchestration | Apache YARN | Spark job submitted with `--master yarn` |
| Build artifact | Maven shade + assembly JAR | `target/EC_StreamJob-{version}-jar-with-dependencies.jar` |
| Nexus repository | Nexus | `http://nexus-dev.snc1/content/repositories/releases/com/groupon/utility/EC_StreamJob/` |
| Artifact storage on host | `/var/groupon/artifacts/EC_StreamJob/` | On the Spark job-submitter host |
| Load balancer | None | No inbound HTTP; job connects outbound to TDM VIPs |
| CDN | None | Not applicable |

## Environments

| Environment | Purpose | Region / Cluster | Job Submitter Host |
|-------------|---------|-----------------|-------------------|
| `uat` | User acceptance testing | snc1 | `gdoop-job-submitter5.snc1` |
| `staging` | NA staging | snc1 | `gdoop-job-submitter5.snc1` |
| `emea_staging` | EMEA staging | snc1 (cross-submits to dub1) | `gdoop-job-submitter5.snc1` |
| `production` | NA production | snc1 | `gdoop-job-submitter5.snc1` |
| `production_emea` | EMEA production | dub1 | `gdoop-job-submitter1.dub1` |

YARN resource manager monitoring URLs:
- NA: `http://gdoop-resourcemanager2.snc1:8088/cluster/apps/RUNNING`
- EMEA: `http://gdoop-resourcemanager2.dub1:8088/cluster/apps/RUNNING`

## CI/CD Pipeline

- **Tool**: Capistrano 2 (`uber_deploy` 3.1.0) — manual operator-driven deploys; no automated CI pipeline detected
- **Config**: `Capfile`
- **Trigger**: Manual — operator runs `cap {env} deploy VERSION={version} TYPE=release`

### Pipeline Stages

1. **Artifact preparation**: Capistrano downloads the versioned JAR from Nexus (`nexus-dev.snc1`) to `/var/groupon/artifacts/EC_StreamJob/` on the job-submitter host
2. **JAR transfer**: Rsync copies the JAR from the utility host to the Spark job-submitter host's designated stream folder (e.g., `stream_staging/`, `stream_production/`)
3. **Symlink**: Creates `EC_StreamJob.jar` symlink pointing to the versioned JAR file on the job-submitter host
4. **Deploy notification**: Posts a deploy message to `#emerging-channel-noti` Slack channel via webhook

### Build

```
mvn install && mvn clean compile assembly:single
```

For release:

```
mvn clean release:clean release:prepare && mvn release:perform && git push && git push --tags
```

### Manual Run (after deploy)

```
$SPARK_HOME/bin/spark-submit \
  --master yarn \
  --executor-memory 1g \
  --queue public \
  --driver-memory 1g \
  --executor-cores 4 \
  --class com.groupon.sparkStreamJob.RealTimeJob \
  EC_StreamJob.jar {colo} {env} {appName}
```

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Manual — one job per colo (NA/EMEA) | Fixed: 1 driver + N executors per cluster |
| Memory (executor) | Fixed at submit time | `--executor-memory 1g` |
| Memory (driver) | Fixed at submit time | `--driver-memory 1g` |
| CPU (executor) | Fixed at submit time | `--executor-cores 4` |
| Backpressure | Spark adaptive | `spark.streaming.backpressure.enabled = true` |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| Executor memory | 1 GB | 1 GB (fixed) |
| Driver memory | 1 GB | 1 GB (fixed) |
| Executor cores | 4 | 4 (fixed) |
| Thread pool per partition | 10 threads | 10 threads (hardcoded) |
| Driver max result size | 5 GB | `spark.driver.maxResultSize = 5g` |
