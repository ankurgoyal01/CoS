---
service: "deal_wizard"
title: "deal_wizard Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumDealWizardWebApp]
tech_stack:
  language: "Ruby 1.9.3"
  framework: "Rails 3.2.22.5"
  runtime: "Unicorn 6.1.0"
---

# Deal Wizard Documentation

Internal sales tool providing guided, wizard-based deal creation flows with Salesforce integration for the Continuum platform.

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
| Language | Ruby 1.9.3 |
| Framework | Rails 3.2.22.5 |
| Runtime | Unicorn 6.1.0 |
| Build tool | Bundler |
| Platform | Continuum |
| Domain | Deal Creation / Sales Integration |
| Team | sfint-dev@groupon.com (dbertelkamp) |
