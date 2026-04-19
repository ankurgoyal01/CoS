---
service: "doorman"
title: "Doorman Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumPlatform"
  containers: ["continuumDoormanService"]
tech_stack:
  language: "Ruby 3.1.3"
  framework: "Sinatra"
  runtime: "Puma"
---

# Doorman Documentation

Doorman provides Okta-based SAML SSO authentication for internal Groupon users accessing internal tools built on the GAPI/GEARS platform.

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
| Language | Ruby 3.1.3 |
| Framework | Sinatra |
| Runtime | Puma |
| Build tool | Rake |
| Platform | Continuum (internal tooling) |
| Domain | Identity and Access Management |
| Team | Users Team (users-team@groupon.com) |
