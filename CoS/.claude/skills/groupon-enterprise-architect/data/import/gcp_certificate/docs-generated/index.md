---
service: "gcp_certificate"
title: "gcp_certificate Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumPrivateCaModule, continuumCertificatesModule, continuumCertificateTemplateMtlsModule, continuumCertificateTemplateClientAuthModule, continuumCertificateTemplateServerAuthModule, continuumCertificateTemplateCustomModule]
tech_stack:
  language: "HCL (Terraform)"
  framework: "Terragrunt 0.58.4"
  runtime: "GCP Private CA (privateca.googleapis.com)"
---

# GCP Private Certificate Authority Documentation

Manages Groupon's internal GCP-hosted Private Certificate Authority (CA) infrastructure, issuing non-publicly-trusted PKI certificates for internal services across mTLS, client authentication, server authentication, and custom subordinate CA use cases.

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
| Language | HCL (Terraform) |
| Framework | Terragrunt 0.58.4 |
| Runtime | GCP Private CA API (privateca.googleapis.com) |
| Build tool | Make |
| Platform | GCP (grp-security-dev, grp-security-prod) |
| Domain | cyber-security / PKI |
| Team | infosec@groupon.com |
