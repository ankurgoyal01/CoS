---
service: "web-config"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumWebConfigService]
---

# Architecture Context

## System Context

`continuumWebConfigService` sits at the edge of the Continuum platform as the configuration authority for Groupon's global nginx routing layer. It does not handle live HTTP traffic; instead, it produces the nginx config artifacts that the `apiProxy` (grout) routing process consumes. The service interacts with Jira to process redirect requests and with GitHub Enterprise to deliver those changes via pull requests. AWS Secrets Manager provides credentials for the Jira integration. On the Kubernetes side, the generated config Docker images are consumed by the `routing-deployment` repository via kustomize image-tag updates.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| web-config | `continuumWebConfigService` | Service | Python 2.7, Fabric, Go | — | Generates routing web-server configuration from templates and data, and automates redirect updates via Jira/GitHub workflows |

## Components by Container

### web-config (`continuumWebConfigService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Virtual Host Assembly | Builds per-virtual-host and include configurations from YAML inputs and rewrite rule files | Python module (`generator/vhost.py`) |
| Template Rendering Engine | Renders nginx/apache Mustache templates and writes generated config files to target paths | Python module (`generator/template.py`) |
| Deployment Automation Tasks | Fabric tasks used to generate, validate, and deploy config to routing hosts via SSH | Python module (`fabfile.py`) |
| Redirect Automation CLI | Reads Jira redirect tickets, parses source/destination URLs, prepends rewrite rules to data files, then pushes a Git branch and opens a GitHub PR | Go CLI (`go/redirect-requests`) |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumWebConfigService` | `apiProxy` | Publishes generated web-server config and error pages | SSH/Fabric |
| `continuumWebConfigService` | `continuumJiraService` | Reads redirect tickets and updates workflow states | HTTPS API |
| `continuumWebConfigService` | `cloudPlatform` | Retrieves Jira credential secret (`hybrid-boundary-svc-user-jira`) | AWS SDK |
| `continuumWebConfigService` | `githubEnterprise` | Pushes branches and creates pull requests for rewrite updates | Git + GitHub API |
| `webConfigDeployAutomation` | `webConfigVhostAssembly` | Invokes generation pipeline for environment config | direct |
| `webConfigVhostAssembly` | `webConfigTemplateRenderer` | Uses template renderer to produce conf artifacts | direct |
| `webConfigDeployAutomation` | `webConfigRedirectAutomation` | Runs redirect generation workflow as needed | direct |

## Architecture Diagram References

- Component: `components-web-config`
