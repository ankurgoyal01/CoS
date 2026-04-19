---
service: "zendesk"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Global Support Systems"
platform: "Continuum"
team: "gss"
status: active
tech_stack:
  language: "N/A"
  language_version: "N/A"
  framework: "N/A"
  framework_version: "N/A"
  runtime: "N/A"
  runtime_version: "N/A"
  build_tool: "N/A"
  package_manager: "N/A"
---

# Zendesk Overview

## Purpose

Zendesk is an externally hosted SaaS support platform used by Groupon's Global Support Systems (GSS) team to manage customer-facing support tickets and case lifecycles. Groupon integrates with Zendesk via its REST API to create, update, and resolve support cases triggered by commerce events such as order issues, refund requests, and customer complaints. The platform serves as the central hub for agent workflows in Groupon's customer support operations.

## Scope

### In scope

- Customer support ticket creation, updating, and resolution
- Case lifecycle management for GSS support agents
- Read and write access to support data via the Zendesk API integration layer
- Synchronization of support case information with Salesforce CRM
- Integration with Groupon's internal services (OgWall, Cyclops, Global Support Systems)

### Out of scope

- Self-hosted infrastructure or deployment management (Zendesk is fully managed SaaS)
- Internal Groupon service-to-service communication (handled by Continuum platform services)
- Order processing or commerce logic (handled upstream by Continuum commerce services)
- Customer identity and authentication (handled by OgWall)

## Domain Context

- **Business domain**: Global Support Systems (GSS)
- **Platform**: Continuum
- **Upstream consumers**: Groupon's GSS agent tools and workflows; Continuum commerce platform services that trigger support cases
- **Downstream dependencies**: Salesforce (CRM sync), OgWall (identity), Cyclops (internal tooling), Global Support Systems service

## Stakeholders

| Role | Description |
|------|-------------|
| GSS Team (gss) | Primary owner and operator; manages agent workflows, configuration, and integration health |
| Team Owner (flueck) | Named service owner responsible for operational decisions |
| SRE / On-call | Responds to PagerDuty alerts via gss-dev@groupon.pagerduty.com |
| GSS Agents | End users who manage support tickets within the Zendesk interface |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Platform | SaaS (Zendesk) | N/A | `.service.yml` — `description: "SaaS Platform"` |
| Integration | Zendesk REST API | N/A | `models/components/continuumZendesk.dsl` |

### Key Libraries

> Not applicable. Zendesk is a SaaS platform. There is no hosted application code or dependency manifest in this repository. All integration logic is managed through the Zendesk API surface and configuration within Zendesk's hosted environment.
