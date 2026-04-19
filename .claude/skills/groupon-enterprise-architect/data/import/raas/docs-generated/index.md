---
service: "raas"
title: "raas Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumRaasInfoService"
    - "continuumRaasApiCachingService"
    - "continuumRaasMonitoringService"
    - "continuumRaasChecksRunnerService"
    - "continuumRaasConfigUpdaterService"
    - "continuumRaasTerraformAfterhookService"
    - "continuumRaasAnsibleAdminService"
    - "continuumRaasMetadataMysql"
    - "continuumRaasMetadataPostgres"
tech_stack:
  language: "Ruby 2.5.0 / Go 1.12"
  framework: "Rails 5.1.4"
  runtime: "Puma 3.7+"
---

# RaaS (Redis-as-a-Service) Documentation

RaaS is Groupon's internal platform for managing, monitoring, and operating managed Redis clusters — providing metadata APIs, health monitoring, Kubernetes config sync, and database provisioning across Redislabs and AWS ElastiCache.

## Contents

| Document | Description |
|----------|-------------|
| [Overview](overview.md) | Service identity, purpose, domain context, tech stack |
| [Architecture Context](architecture-context.md) | Containers, components, C4 references |
| [API Surface](api-surface.md) | Endpoints, contracts, protocols |
| [Events](events.md) | Async messages published and consumed |
| [Data Stores](data-stores.md) | Databases, caches, storage |
| [Integrations](integrations.md) | External and internal dependencies |
| [Configuration](configuration.md) | Environment, flags, secrets |
| [Flows](flows/index.md) | Process and flow documentation |
| [Deployment](deployment.md) | Infrastructure and environments |
| [Runbook](runbook.md) | Operations, monitoring, troubleshooting |

## Quick Facts

| Property | Value |
|----------|-------|
| Language | Ruby 2.5.0 (Info Service, Monitoring, Admin); Go 1.12 (Config Updater) |
| Framework | Rails 5.1.4 (Info Service); Ansible/Python (Admin) |
| Runtime | Puma 3.7+ (Info Service) |
| Build tool | Bundler (Ruby); Go modules (Go) |
| Platform | Continuum |
| Domain | Infrastructure / Redis Operations |
| Team | raas-team (raas-team@groupon.com) |
