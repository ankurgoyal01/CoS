---
service: "kafka-docs"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "vm"
environments: [production-snc1, production-sac1, production-dub1, staging-snc1, development-snc1, uat-snc1, cloud-gensandbox, cloud-grpn-dse-dev]
---

# Deployment

## Overview

The `kafka-docs` documentation site is deployed as a static site via GitHub Pages. The site build uses `make publish` in the `docs/` directory, which runs GitBook CLI to produce static HTML, then pushes the output to the `gh-pages` orphan branch. An ogwall redirect serves the site at `http://kafka-docs.groupondev.com`.

The underlying Kafka clusters are deployed as bare-metal VMs in Groupon data centers (SNC1, SAC1, DUB1) managed via the `ops-config` system and provisioned using Ansible playbooks from the `dse-utils` repo. AWS MSK clusters are managed via AWS in us-west-2.

## Infrastructure

### Kafka Docs Site

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | Static site; no container |
| Orchestration | GitHub Pages | `gh-pages` branch in `github.groupondev.com/data/kafka-docs` |
| Build | Make + GitBook CLI 3.2.2 | `docs/Makefile`: `make setup`, `make server`, `make publish` |
| CDN / Hosting | GitHub Pages | `https://pages.github.groupondev.com/data/kafka-docs/` |
| Redirect | ogwall | `http://kafka-docs.groupondev.com` points to GitHub Pages |

### Kafka Broker Clusters (On-Prem)

| Component | Technology | Details |
|-----------|-----------|---------|
| Broker hosts | Bare-metal VM (B96H or equivalent, RAID 10 + BBU) | Provisioned via `ops-config` host templates |
| Orchestration | Ansible (`dse-utils/ansible`) | Rolling restart playbooks; inventory files per cluster |
| Package deployment | Roller | Deploys `kafka_broker` packages; tracks version via `ops-config` |
| Load balancer | Hardware VIP | Per-cluster VIP managed via NetOps; firewall rules per broker IP |
| ZooKeeper | Apache ZooKeeper 3.3.6 | 5-node clusters per colo; dedicated ZK VIPs |
| Active audit | kafka-active-audit daemon | Dedicated `kafka-active-audit` hosts per cluster/colo |

### AWS MSK Clusters (Cloud)

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | AWS Managed | AWS-managed Kafka; no broker access |
| Orchestration | AWS MSK | Managed via AWS console / Terraform (not documented here) |
| Endpoint type | Friendly DNS | `kafka-grpn.gensandbox.us-west-2.aws.groupondev.com:9092` (stable endpoint; cluster resized transparently) |

## Environments

### Kafka Docs Site

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Production (GitHub Pages) | Published documentation | github.groupondev.com | `http://kafka-docs.groupondev.com` |
| Local development | Author and preview docs | Developer workstation | `http://localhost:4000` (via `make server`) |

### Kafka Clusters (On-Prem)

| Environment | Cluster Type | COLO | Endpoint |
|-------------|-------------|------|----------|
| Production | Local | SNC1 | `kafka.snc1:9092` |
| Production | Local | SAC1 | `kafka-broker-lb.sac1:9092` |
| Production | Local | DUB1 | `kafka.dub1:9092` |
| Production | Aggregate | SNC1 | `kafka-aggregate.snc1:9092` |
| Production | Aggregate | SAC1 | `kafka-aggregate.sac1:9092` |
| Staging | Local | SNC1 | `kafka-08-broker-staging-vip.snc1:9092` |
| Staging | Aggregate | SNC1 | `kafka-aggregate-staging.snc1:9092` |
| Development | Local | SNC1 | `kafka-08-broker-dev-vip.snc1:9092` |
| UAT | Aggregate | SNC1 | `kafka-aggregate-broker-uat.snc1:9092` |

## CI/CD Pipeline

### Kafka Docs Site

- **Tool**: Manual (`make` commands)
- **Config**: `docs/Makefile`
- **Trigger**: Manual (author runs `make publish` after merging to `master`)

#### Pipeline Stages

1. **Setup**: `make setup` — runs `gitbook install` and `npm install` to install GitBook plugins and Node dependencies
2. **Build**: `make server` (local preview only) — starts GitBook dev server at `localhost:4000`
3. **Publish**: `make publish` — builds static site via GitBook CLI, then force-pushes output to `gh-pages` branch

### Kafka Broker Rolling Restart (Ansible)

- **Tool**: Ansible (`dse-utils/ansible`)
- **Config**: `dse-utils/ansible/kafka-playbooks/`
- **Trigger**: Manual (run by Data Systems team)

#### Pipeline Stages

1. **Pre-check**: `kafka_poll_underreplicated.yml` — verifies no under-replicated partitions before rolling
2. **Rolling restart**: `kafka_roll_broker.yml` — restarts one broker at a time; prompts operator before each broker; verifies cluster health between each step
3. **Controller last**: Controller broker is always restarted last to avoid multiple controller elections

## Cluster Node Counts (Production)

| Cluster | COLO | Broker Count | ZK Count | Active-Audit Hosts |
|---------|------|-------------|----------|-------------------|
| Local | SNC1 | kafka-08-broker{12-21} + kafka-broker{1-10} (~20) | 5 | 2 |
| Local | SAC1 | kafka-broker{1-10} (10) | 5 | 2 |
| Local | DUB1 | kafka-broker{1-10} (10) | 5 | 4 |
| Aggregate | SNC1 | kafka-aggregate1-broker{1-20} (20) | 5 | 2 |
| Aggregate | SAC1 | kafka-aggregate1-broker{1-20} (20) | 5 | 2 |

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Broker capacity | Manual horizontal — add new broker hosts | Provision at 80% disk utilization; rebalance partitions after adding |
| Partition count | Manual — `kafka-topics.sh --alter --partitions` | Default 25; increase for consumer parallelism |
| Retention tuning | Manual — `kafka-topics.sh --alter --config retention.ms=` | Reduce on specific topics when disk approaches 90% |

## Resource Requirements

> No evidence found in codebase for specific CPU/memory values. Broker hosts are B96H class bare-metal servers with RAID 10 + BBU. Storage is on `/var/groupon` mount; disk capacity tracked via Wavefront cluster dashboard.
