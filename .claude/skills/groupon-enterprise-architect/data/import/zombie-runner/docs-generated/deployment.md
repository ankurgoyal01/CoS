---
service: "zombie-runner"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "gcp-dataproc"
environments: [sandbox, production]
---

# Deployment

## Overview

Zombie Runner is deployed as a pre-installed Python package on a custom Google Cloud Dataproc image (image family: `zombie-runner`). It is not containerized with Docker and is not orchestrated by Kubernetes or ECS. Each Dataproc cluster is an ephemeral compute environment spun up on demand by a data engineer or automated pipeline. The cluster hosts Zombie Runner and all its dependencies; the operator SSHes into the primary node and invokes the `zombie_runner run` CLI. Clusters are configured to auto-delete after 12 hours of idle time.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | Zombie Runner runs as a Python process directly on the Dataproc VM |
| Orchestration | Google Cloud Dataproc | Custom Dataproc image family `zombie-runner`; single-node or multi-node clusters |
| Package artifact | Python sdist (.tar.gz) | Published to `https://artifacts-generic.groupondev.com/python/zombie-runner/` on tagged releases |
| CI/CD | Jenkins | `Jenkinsfile` in repo root; Docker image `docker.groupondev.com/python:2.7.18` |
| Load balancer | None | Direct SSH access via IAP tunnel (`--tunnel-through-iap`) |
| CDN | None | Not applicable |

## Environments

| Environment | Purpose | Region | Notes |
|-------------|---------|--------|-------|
| Sandbox | Development and proof-of-concept testing | `us-central1` | GCP project `prj-grp-general-sandbox-7f70`; metastore `grp-dpms-sandbox-1` |
| Production | Production data pipeline execution | GCP region (per pipeline) | Configured at cluster creation time via `gcloud` parameters |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: On push to `master` or `development` branches (build); on Git tag push (publish artifact)
- **Test runner**: `nosetests -v ./zombie_runner/test/` (`.ci.yml`)

### Pipeline Stages

1. **Prepare**: Extracts library name from `setup.py`; determines artifact version from Git tag or defaults to `build-snapshot`
2. **Build**: Substitutes version into `setup.py`; runs `python2 setup.py sdist` to produce `.tar.gz` artifact
3. **Publish**: (Tagged releases only) PUTs the `.tar.gz` artifact to `https://artifacts-generic.groupondev.com/python/zombie-runner/<artifact-name>` via `curl`; validates HTTP 201 response

## Cluster Lifecycle

### Starting a Dataproc Cluster

```
gcloud dataproc clusters create <cluster-name> \
    --region=<region> \
    --no-address \
    --subnet=<subnet> \
    --service-account=<service-account> \
    --single-node \
    --tags allow-iap-ssh,dataproc-vm \
    --dataproc-metastore=<dataproc-metastore> \
    --image=<dataproc-image-family> \
    --max-idle=12h
```

Key parameters:

| Parameter | Purpose |
|-----------|---------|
| `--image` | Specifies the custom Dataproc image from image family `zombie-runner` |
| `--dataproc-metastore` | Hive Metastore service used by HiveTask operators |
| `--service-account` | IAM service account granting S3, EMR, and GCP resource access |
| `--max-idle=12h` | Auto-deletes the cluster after 12 hours of inactivity |
| `--tags allow-iap-ssh,dataproc-vm` | Enables IAP SSH tunnel access and Dataproc firewall rules |

### Accessing the Cluster

```
gcloud compute ssh --zone <zone> "<cluster-name>-m" --tunnel-through-iap --project <project>
```

### Running a Workflow

```
sudo su
cd /root
gsutil cp -r gs://<bucket>/<workflow>/* /root
zombie_runner run /root/<workflow_dir>/
```

### Deleting a Cluster

```
gcloud dataproc clusters delete <cluster-name> --region=<region>
```

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Manual — create additional single-node clusters per pipeline; do not share clusters | One cluster per pipeline recommended |
| Worker nodes | Dataproc multi-node if MapReduce/Spark scale-out is needed | `--num-workers` at cluster creation |
| Task parallelism | Controlled by `resources` section in workflow YAML and `--parallelism` CLI flag | Per-workflow |

## Resource Requirements

> Deployment configuration managed externally. Compute resource sizing (CPU, memory, disk) is determined at Dataproc cluster creation time and varies by pipeline workload. No fixed request/limit values are defined in the Zombie Runner repository itself.
