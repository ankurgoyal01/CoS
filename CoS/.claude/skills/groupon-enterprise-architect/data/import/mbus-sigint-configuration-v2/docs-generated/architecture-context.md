---
service: "mbus-sigint-configuration-v2"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMbusSigintConfigurationService, continuumMbusSigintConfigurationDatabase]
---

# Architecture Context

## System Context

The MBus Sigint Configuration Service sits within the **Continuum Platform** (`continuumSystem`) as a governance and control-plane component for Groupon's Global Message Bus. It is called by MBus operator tooling (`mbusible`) and by Artemis broker instances that fetch their running configuration. The service orchestrates outbound calls to Jira (ticket management), ProdCat (production approval), and Ansible (configuration deployment) to automate the full lifecycle of message bus topology changes.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| MBus Sigint Configuration Service | `continuumMbusSigintConfigurationService` | Backend API | Java, Dropwizard | 11 / jtier 5.14.1 | Centralized service for message bus configuration management, change workflows, and deployment orchestration |
| MBus Sigint Configuration Database | `continuumMbusSigintConfigurationDatabase` | Database | PostgreSQL | 12 (local dev) | PostgreSQL persistence for clusters, destinations, credentials, requests, schedules, and deployment metadata |

## Components by Container

### MBus Sigint Configuration Service (`continuumMbusSigintConfigurationService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Resources (`mbsc_apiResources`) | Exposes HTTP endpoints for configuration, cluster, change-request, deploy-schedule, delete-request, gprod-config, and admin operations | JAX-RS Resources |
| Domain Services (`mbsc_domainServices`) | Implements business workflows for configuration changes, deployment scheduling, approvals, and request lifecycle transitions | Service Layer |
| Scheduler Jobs (`mbsc_schedulerJobs`) | Runs Quartz cron jobs: `DeployConfigJob`, `DeployRescheduleJob`, `RequestPromoterJob`, `JiraCreateJob`, `JiraLinkingJob`, `ChangeRequestJiraTransitionJob`, `GprodJiraTransitionJob` | Quartz Jobs |
| Persistence Adapters (`mbsc_persistenceAdapters`) | JDBI DAOs and row mappers for all persisted entities (clusters, destinations, diverts, credentials, requests, schedules, gprod config) | JDBI |
| Integration Clients (`mbsc_integrationClients`) | Outbound Jersey HTTP clients for Jira API, ProdCat, and Ansible orchestration | Jersey Clients |
| Config Rendering Task (`mbsc_configRenderingTask`) | Template rendering (FreeMarker/StringTemplate) and SSH execution to generate and deploy Ansible configuration output | Task + Template Engine |
| Health Checks (`mbsc_healthChecks`) | Dropwizard health checks verifying DB connectivity and service readiness | Dropwizard HealthCheck |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMbusSigintConfigurationService` | `continuumMbusSigintConfigurationDatabase` | Reads and writes configuration, request, and scheduling data | JDBC |
| `continuumMbusSigintConfigurationService` | Jira API | Creates and updates change-request tickets | HTTPS/REST |
| `continuumMbusSigintConfigurationService` | ProdCat API | Requests approval signals for gprod changes | HTTPS/REST |
| `continuumMbusSigintConfigurationService` | Ansible Automation Runtime | Renders and deploys message-bus configuration via SSH | Async task / SSH |
| `mbsc_apiResources` | `mbsc_domainServices` | Invokes use cases for reads/writes and workflow transitions | Direct |
| `mbsc_domainServices` | `mbsc_persistenceAdapters` | Persists and queries configuration state | Direct |
| `mbsc_domainServices` | `mbsc_integrationClients` | Calls external systems for approvals and ticket automation | Direct |
| `mbsc_schedulerJobs` | `mbsc_domainServices` | Executes scheduled deployment and promotion workflows | Direct |
| `mbsc_schedulerJobs` | `mbsc_integrationClients` | Transitions and links Jira tickets during scheduled jobs | Direct |
| `mbsc_configRenderingTask` | `mbsc_integrationClients` | Triggers Ansible-backed rendering and deployment orchestration | Direct |
| `mbsc_healthChecks` | `mbsc_persistenceAdapters` | Verifies DB-backed service health | Direct |

## Architecture Diagram References

- Component: `components-continuum-mbus-sigint-configuration-service`
