---
service: "momo-config"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "vm"
environments: [lab, stable]
---

# Deployment

## Overview

`momo-config` is a configuration-only repository for Momentum (Ecelerity) MTA clusters running on Linux VMs in AWS (`us-west-1` region is referenced for the stable sink host). The Ecelerity process runs directly on OS-managed VMs — no Docker or Kubernetes orchestration is evidenced in the repository. Configuration files are deployed to each cluster node by pushing to the `master` branch; the CI workflow (currently commented out) was designed to create semantic version tags on each master push. The repository is organized by region (`eu/`) and cluster role (`email`, `trans`, `inbound`, `smtp`, `sink`).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | Ecelerity runs natively on Linux VMs; no Dockerfile present |
| Orchestration | VM (Linux) | Self-hosted runners referenced in GitHub Actions (`mta-self-hosted`, `linux`) |
| Load balancer | Not evidenced | MX-based DNS load distribution across cluster nodes via `continuumMtaDnsService` |
| CDN | None | Not applicable for SMTP delivery |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| lab | Development / testing; sink routing disabled; debug logging suppressed | EU (AWS) | — |
| stable | Production-equivalent; sink routing active for non-production domains; debug logging enabled; sink host `mta-sink-stable.grpn-mta-stable.us-west-1.aws.groupondev.com` | EU + US West (AWS) | — |

## CI/CD Pipeline

- **Tool**: GitHub Actions
- **Config**: `.github/workflows/master.yaml` (currently commented out / disabled)
- **Trigger**: Push to `master` branch (when enabled)

### Pipeline Stages

1. **Checkout**: Checks out repository code at the pushed commit
2. **Generate version**: Reads latest semver tag from remote (`git ls-remote --tags`), increments minor version, sets `NEW_TAG` env var
3. **Create tag**: Creates and pushes new semver tag to remote (`git tag $NEW_TAG && git push origin $NEW_TAG`)

> Note: The CI pipeline is currently commented out in `.github/workflows/master.yaml`. Configuration deployment to cluster nodes is managed operationally (method not evidenced in repository).

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Multiple cluster nodes per role; DNS-based distribution | Managed via `continuumMtaDnsService` zone definitions |
| Outbound connections | Per-process global limit | `Server_Max_Outbound_Connections = 20000` per node |
| File descriptors | Per-process limit | `Server_Max_File_Descriptors = 80000` per node |
| Thread pools | Fixed concurrency | `accept` pool: 1 thread; `pool` event loop: 10 threads; `SwapIn`/`SwapOut`: 20 threads each |
| Message queue | Bounded in-memory | `max_resident_messages = 256000` (email/trans); `Max_Resident_Messages = 65536` (inbound/smtp) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not evidenced | Not evidenced |
| Memory | `Memory_Goal = 90%` (soft) | `Memory_HWM = 95%` (hard — Ecelerity begins throttling intake) |
| Disk | `/var/spool/ecelerity` (message spool); `/var/log/ecelerity/` (log files); `/opt/msys/leveldb/` (adaptive backstore) | Not evidenced |

> Deployment configuration for node provisioning and capacity managed externally (not present in this repository).
