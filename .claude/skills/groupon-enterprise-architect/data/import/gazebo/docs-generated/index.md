---
service: "gazebo"
title: "Gazebo (Writers' App) Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumGazebo"
  containers: [continuumGazeboWebApp, continuumGazeboWorker, continuumGazeboMbusConsumer, continuumGazeboCron, continuumGazeboMysql, continuumGazeboRedis]
tech_stack:
  language: "Ruby 2.1.2"
  framework: "Rails 4.1"
  runtime: "Ruby 2.1.2 via RVM, Unicorn 4.8.3"
---

# Gazebo (Writers' App) Documentation

Editorial copy creation and management tool for Groupon site content editing and publishing.

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
| Language | Ruby 2.1.2 |
| Framework | Rails 4.1 |
| Runtime | Ruby 2.1.2 via RVM, Unicorn 4.8.3 |
| Build tool | Bundler 1.16.6, npm, Gulp 3.9.0, Rake |
| Platform | Continuum |
| Domain | Editorial / Content Management |
| Team | gazebo@groupon.com |
