---
service: "jira"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "vm"
environments: ["production"]
---

# Deployment

## Overview

Jira is deployed as a traditional Java web application on a bare-metal or VM host within the `snc1` data center colo. It runs inside Apache Tomcat (Catalina) with no Docker containerization or Kubernetes orchestration. Deployment is managed by the Systems Engineering team using host-provisioning tooling (ops-package-recipes). The application binary is the standard Atlassian Jira Server distribution; customizations are applied by copying the compiled `GwallAuthenticator.class` and modified config files into the Jira installation directory.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | Not containerized; bare Atlassian Jira Server distribution |
| Orchestration | VM (bare-metal / VM host) | `snc1` data center colo |
| Web/App server | Apache Tomcat (Catalina) | Started via `setenv.sh` + Catalina start scripts |
| Database | MySQL | `jira-db-master-vip.snc1:3306` — managed by DaaS MySQL |
| Load balancer | Not specified in source evidence | Likely upstream load balancer or direct DNS |
| CDN | None | Internal tool; no CDN |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| production | Production issue tracking for all Groupon teams | `snc1` | `http://jira.groupondev.com` |

## CI/CD Pipeline

> No evidence found in codebase. Deployment configuration managed externally by Systems Engineering. The Owners Manual is at `https://github.groupondev.com/ProdSysAdmin/Jira/wiki/Jira-Owners-Manual`.

### Pipeline Stages

> No evidence found in codebase.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Manual (single-node deployment per evidence) | One application node in `snc1` |
| Memory | Fixed JVM heap | `-Xms8192m -Xmx10240m` (from `sys_config/setenv.sh`) |
| PermGen | Conditional | `-XX:MaxPermSize=384m` if supported by JVM |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| Memory (JVM heap min) | 8192 MB | 10240 MB (configured in `sys_config/setenv.sh`) |
| Memory (PermGen) | Not set | 384 MB (applied conditionally) |
| CPU | Not specified | Not specified |
| Disk | Not specified | Log files rotate at 20 MB, retaining 5 backups per appender |
