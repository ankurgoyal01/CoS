---
service: "web-config"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for web-config.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Config Generation](config-generation.md) | batch | Operator runs `fab generate:{ENV}` or CI build starts | Reads YAML data and Mustache templates; renders all nginx config files for a target environment |
| [Config Deployment](config-deployment.md) | batch | Operator runs `fab {ENV} deploy:{REVISION}` | Packages generated config and deploys it to routing hosts via SSH, then reloads nginx |
| [Redirect Automation](redirect-automation.md) | batch | Operator runs `create-redirects -e {ENV}` | Reads Jira redirect tickets, generates nginx rewrite rules, pushes a Git branch, and opens a GitHub PR |
| [CI/CD Pipeline](cicd-pipeline.md) | batch | Push to `master` or `release` branch | Builds and validates environment-tagged Docker images; publishes images; updates deployment manifests |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 4 |

## Cross-Service Flows

- The **Config Deployment** flow terminates at `apiProxy` — the `routing-deployment` Kubernetes manifests pull the config Docker image and mount it into the nginx pod. See [Config Deployment](config-deployment.md).
- The **Redirect Automation** flow spans `continuumWebConfigService`, `continuumJiraService`, `cloudPlatform`, and `githubEnterprise`. See [Redirect Automation](redirect-automation.md).
- The **CI/CD Pipeline** flow spans `continuumWebConfigService` and `githubEnterprise` (via the `routing-deployment` repo). See [CI/CD Pipeline](cicd-pipeline.md).
