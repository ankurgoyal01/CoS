---
service: "mbus-sigint-configuration-v2"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 1
---

# Integrations

## Overview

The service integrates with three external systems via outbound HTTP REST calls and one SSH-based automation runtime. All integrations are handled by the `mbsc_integrationClients` component (Jersey HTTP clients). Jira ticket management and ProdCat approval are critical to the change-request promotion flow. Ansible orchestration is invoked for actual Artemis configuration deployment. The primary internal dependency is the PostgreSQL DaaS database.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Jira API | HTTPS/REST | Creates, links, and transitions Jira tickets for change requests and gprod changes | yes | `unknown_jiraapi_89f846f2` (stub) |
| ProdCat API | HTTPS/REST | Requests approval signals for production (gprod) change submissions | yes | `unknown_prodcatapi_7034a45a` (stub) |
| Ansible Automation Runtime | SSH / async task | Renders Artemis broker configuration and executes deployment scripts on the Ansible host | yes | `unknown_ansible_automation_d51d5ee1` (stub) |

### Jira API Detail

- **Protocol**: HTTPS/REST (Atlassian REST API v2)
- **Base URL**: Staging: `https://jira-staging.groupondev.com` / `https://groupondev-sandbox-572.atlassian.net`; Production: `https://jira.groupondev.com` / `https://groupondev.atlassian.net`
- **Auth**: API token (`JIRA_API_PASSWORD` env var), user `mbus-jira@groupon.com`
- **Purpose**: Automates Jira ticket creation (`JiraCreateJob`), links MBC tasks to GPROD tickets (`JiraLinkingJob`), and transitions ticket statuses in sync with change-request workflow state (`ChangeRequestJiraTransitionJob`, `GprodJiraTransitionJob`)
- **Failure mode**: Jira Quartz jobs are queued and retried; change requests can continue without Jira linkage in degraded mode
- **Circuit breaker**: No evidence found in codebase

### ProdCat API Detail

- **Protocol**: HTTPS/REST
- **Base URL**: Staging: `http://prodcat.staging.service/v1/changes/`; Production: `http://prodcat.production.service/v1/changes/`
- **Auth**: No evidence found in codebase of explicit auth for ProdCat calls
- **Purpose**: Submits production change approval requests so that MBus configuration deployments to `PROD` environments are tracked and approved in the production change management system
- **Failure mode**: Production promotion is blocked if ProdCat approval cannot be obtained
- **Circuit breaker**: No evidence found in codebase

### Ansible Automation Runtime Detail

- **Protocol**: SSH to remote Ansible host
- **Base URL / Endpoint**:
  - Staging: `ssh svc_mbus_sigint@mbus1-na-ansible.us-central1.mbus.stable.gcp.groupondev.com`
  - Production: `ssh svc_mbus_sigint@mbus1-na-ansible.us-central1.mbus.prod.gcp.groupondev.com`
  - Command: `cd /var/groupon/mbusible/deploy-mbus/ && ./artemis_config_deploy.sh #CLUSTER# #ENVIRONMENT#`
- **Auth**: SSH service account `svc_mbus_sigint` with StrictHostKeyChecking disabled (`accept-new`)
- **Purpose**: Executes the Artemis configuration deployment script after config rendering by the `mbsc_configRenderingTask` component
- **Failure mode**: `DeployConfigJob` records deployment as `FAILED_TEST` or `FAILED_PROD`; the request status is updated accordingly and the job can be retried via re-schedule or admin endpoint
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| MBus Sigint Configuration Database (PostgreSQL DaaS) | JDBC | All reads and writes for configuration, request, and scheduling state | `continuumMbusSigintConfigurationDatabase` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| `mbusible` (MBus operator tooling) | REST/HTTP | Reads and writes cluster configuration, submits change requests, manages deploy schedules |
| Artemis broker infrastructure | REST/HTTP | Fetches deployment-ready configuration via `/config/deployment/{clusterId}/{environmentType}` |

> Upstream consumers beyond `mbusible` are tracked in the central architecture model.

## Dependency Health

- The `mbsc_healthChecks` component exposes Dropwizard health checks that verify PostgreSQL connectivity via `mbsc_persistenceAdapters`.
- Admin port 8081 exposes the `/healthcheck` endpoint for dependency status.
- Jira and Ansible connectivity are not independently health-checked at startup; failures surface during scheduled job execution.
