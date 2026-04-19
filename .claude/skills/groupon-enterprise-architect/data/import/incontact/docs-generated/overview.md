---
service: "incontact"
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

# InContact Overview

## Purpose

InContact is a third-party SaaS platform that provides cloud contact centre capabilities used by Groupon's Global Support Systems (GSS) team. It enables GSS agents to handle customer interactions (voice, chat, and digital channels) and is integrated into Groupon's Continuum platform as a declared dependency. This repository captures the service metadata and architecture boundary for InContact within Groupon's Architecture-as-Code model.

## Scope

### In scope

- Representation of the InContact SaaS integration as a Continuum platform container
- Ownership and on-call metadata for the GSS team's InContact dependency
- Declared service dependencies on `ogwall` and `global_support_systems`
- Architecture boundary definition within the Continuum system context

### Out of scope

- Internal implementation of the InContact SaaS platform (vendor-managed)
- Agent desktop or telephony hardware configuration
- Customer-facing commerce flows (handled by other Continuum services)
- CRM data storage (owned by `global_support_systems`)

## Domain Context

- **Business domain**: Global Support Systems (GSS) — Customer contact centre operations
- **Platform**: Continuum
- **Upstream consumers**: Not discoverable from this repository; upstream consumers are tracked in the central architecture model.
- **Downstream dependencies**: `ogwall`, `global_support_systems`

## Stakeholders

| Role | Description |
|------|-------------|
| Service owner | flueck (GSS team lead) |
| Team | GSS (Global Support Systems) — gss@groupon.com |
| SRE on-call | gss-dev@groupon.pagerduty.com, PagerDuty service PN9TCKJ |
| Operations | GSS Slack channel CFED5CCSV, Google Chat space AAAArQs1V3g |

## Tech Stack

### Core

> No evidence found in codebase.

InContact is a vendor-managed SaaS platform. No source code, build manifests (package.json, go.mod, pom.xml), or Dockerfile are present in this repository. The repository serves solely as an architecture metadata and service registry entry.

### Key Libraries

> No evidence found in codebase.

No internal libraries are declared; InContact functionality is consumed as a SaaS service.
