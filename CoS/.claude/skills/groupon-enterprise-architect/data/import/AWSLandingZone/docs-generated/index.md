---
service: "aws-landing-zone"
title: "AWS Landing Zone Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumLandingZoneTerraform"
    - "continuumLandingZoneCloudFormationBaseline"
    - "continuumLandingZoneCloudCustodian"
    - "continuumLandingZoneCiCd"
    - "continuumLandingZoneDocsPortal"
tech_stack:
  language: "Python 3 / HCL"
  framework: "Terraform / Terragrunt"
  runtime: "Jenkins / Docker"
---

# AWS Landing Zone Documentation

Groupon's official AWS governance layer — manages account provisioning, IAM, VPC networking, guardrails, and DNS across all AWS environments using Terraform, CloudFormation, and Cloud Custodian.

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
| Language | Python 3 / HCL |
| Framework | Terraform / Terragrunt |
| Runtime | Jenkins / Docker |
| Build tool | Make + terrabase CI image |
| Platform | AWS (Continuum Platform) |
| Domain | Cloud Governance / Infrastructure |
| Team | Cloud Core (cloud-core@groupon.com) |
