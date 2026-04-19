---
service: "aidg"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Advertising, Sponsored & SEM"
platform: "Continuum"
team: "AIDG / AI & Data"
status: active
tech_stack:
  language: "Java"
  language_version: "Unknown"
  framework: "Unknown"
  framework_version: "Unknown"
  runtime: "JVM"
  runtime_version: "Unknown"
  build_tool: "Unknown"
  package_manager: "Unknown"
---

# AIDG Overview

## Purpose

AIDG (AI-Driven Deal Generation) is a set of internal Java backend services within the Continuum platform that support AI-driven deal generation and merchant quality scoring. The service provides two core capabilities: PDS (Product Data Service) inference enrichment via the InferPDS API, and merchant quality evaluation via the Merchant Quality API. These capabilities enable downstream deal creation and advertising systems to make data-informed decisions about deal quality and merchant reliability.

## Scope

### In scope

- PDS inference enrichment: enriching product data through AI-driven inference models
- Merchant quality scoring: computing and exposing merchant quality scores for use by deal generation and advertising workflows
- Internal API exposure for upstream Continuum services

### Out of scope

- Deal creation and publishing (handled by deal management services)
- Merchant onboarding and profile management (handled by merchant services)
- Ad placement and SEM bidding (handled by advertising delivery systems)
- Consumer-facing deal presentation (handled by frontend/BFF layers)

## Domain Context

- **Business domain**: Advertising, Sponsored & SEM
- **Platform**: Continuum
- **Upstream consumers**: Not documented in federated workspace; tracked in central architecture model
- **Downstream dependencies**: Not documented in federated workspace; tracked in central architecture model

## Stakeholders

| Role | Description |
|------|-------------|
| AIDG / AI & Data Team | Owns service development, deployment, and operations |
| Advertising Engineering | Consumes merchant quality scores for ad targeting and deal ranking |
| Deal Management | Consumes PDS inference results for deal enrichment |
| Data Science | Maintains and improves underlying ML models for inference and scoring |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | Unknown | Architecture DSL (`"Java"` technology tag on both containers) |
| Framework | Unknown | Unknown | No source code available |
| Runtime | JVM | Unknown | Inferred from Java language |
| Build tool | Unknown | Unknown | No source code available |
| Package manager | Unknown | Unknown | No source code available |

### Key Libraries

> No evidence found in codebase. Source code is not available for this service; only architecture DSL definitions exist. Key libraries will be documented when source code is federated.
