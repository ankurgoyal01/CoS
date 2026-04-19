---
service: "ORR"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "none"
environments: ["production"]
---

# Deployment

## Overview

The ORR Audit Toolkit is not deployed as a running service. It is a collection of operator-invoked CLI scripts distributed via a Git repository (`github.groupondev.com/SOC/ORR`). Operators clone the repository to a Linux host (on-prem, e.g., `dev1.snc1`) and run scripts directly. There is no containerization, orchestration, or load balancer involved. The toolkit targets on-prem production infrastructure exclusively.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | none | No Dockerfile — scripts run directly on host OS |
| Orchestration | none | No Kubernetes, ECS, or Lambda — manual operator invocation only |
| Load balancer | none | CLI toolkit; no inbound network traffic |
| CDN | none | Not applicable |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| production (on-prem) | Live audit of production host and VIP monitoring configs | snc1, sac1, dub1 colos | N/A — script output only |

## CI/CD Pipeline

> No evidence found in codebase. The ORR repository has no CI/CD pipeline configuration. Scripts are distributed via git clone and updated via `git pull`. Each script performs a self-version check against `https://raw.github.groupondev.com/SOC/ORR/master/bin/<script>` on startup and instructs operators to pull if a newer version is available.

## Prerequisites for Running

Operators must satisfy the following before executing any audit script:

1. Run on a Linux platform (CentOS) — scripts explicitly check `uname -s == Linux` and exit otherwise
2. Have `jq` installed (`brew install jq` or `sudo yum --enablerepo=repo-vip-epel install jq`)
3. Have `git` installed and the `ops-config` repository cloned to a known path under `~/`
4. Have network access to `http://service-portal-vip.snc1` (intranet or VPN)
5. For VIP audits: network access to `http://lbmsv2-vip.snc1` and `https://raw.github.groupondev.com`
6. For `hosts_without_service.py`: Python 3.7 installed and `pyYAML` available in the active environment
7. Adjust `hosts_dir` variable in `hosts_without_service.py` to match the local `ops-config` clone path

## Scaling

> Not applicable — CLI toolkit with no server component. No scaling dimensions apply.

## Resource Requirements

> Not applicable — resource consumption depends on operator's host capacity and the size of the `ops-config` repository. Scripts process thousands of YAML host files sequentially and may take several minutes to complete.
