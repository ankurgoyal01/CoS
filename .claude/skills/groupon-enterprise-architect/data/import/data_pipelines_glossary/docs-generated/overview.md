---
service: "data_pipelines_glossary"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Data Pipelines"
platform: "Continuum"
team: "grpn-gcloud-data-pipelines"
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

# Data Pipelines Glossary Overview

## Purpose

The Data Pipelines Glossary is a static documentation site that serves as the primary point of entry and navigation hub for all data pipeline workflow repositories in Groupon's data platform. It provides a unified index so that engineers and data practitioners can discover and navigate to the correct workflow repository for a given data pipeline concern. The service does not process data itself; it exists to reduce discovery friction across the data engineering landscape.

## Scope

### In scope

- Providing a navigational index to all data pipeline workflow repositories
- Serving as a canonical reference point for the data platform's repository landscape
- Documenting naming conventions, taxonomy, and ownership for data pipeline workflows

### Out of scope

- Executing or orchestrating data pipeline jobs (handled by individual workflow repositories)
- Storing or transforming data (handled by downstream pipeline services)
- Serving API endpoints or processing application traffic

## Domain Context

- **Business domain**: Data Pipelines
- **Platform**: Continuum
- **Upstream consumers**: Data engineers and platform teams navigating to workflow repositories
- **Downstream dependencies**: Individual data pipeline workflow repositories (linked by content, not by runtime dependency)

## Stakeholders

| Role | Description |
|------|-------------|
| Data Engineers | Primary audience; use the glossary to locate the correct workflow repository |
| Platform Team (grpn-gcloud-data-pipelines) | Owns and maintains the glossary content and structure |
| Architecture Team | References the glossary as a container within the Continuum platform model |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Type | Static site | N/A | `architecture/models/containers.dsl` — technology: "Static site" |

### Key Libraries

> No evidence found in codebase. The service is declared as a static site with no dependency manifests (no `package.json`, `go.mod`, `pom.xml`, or `Dockerfile` present in the repository).
