---
service: "gdpr"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Consumer Compliance / Support Operations"
platform: "Continuum"
team: "Analytics & Automation (AA)"
status: active
tech_stack:
  language: "Go"
  language_version: "1.23.5"
  framework: "Gin"
  framework_version: "1.10.1"
  runtime: "Alpine Linux"
  runtime_version: "3.21"
  build_tool: "go build"
  package_manager: "Go Modules"
---

# GDPR Offboarding Tool Overview

## Purpose

The GDPR Offboarding Tool (`gdpr`) is an internal support service that automates the collection of a Groupon consumer's personal data across multiple backend systems in response to a GDPR Subject Access Request (SAR) or offboarding request. It aggregates orders, preferences, subscriptions, user-generated content, profile addresses, billing information, and Groupon Bucks data into a ZIP archive of CSV files, then delivers that archive to the requesting support agent. The service exists to allow Application Operations agents to fulfil GDPR data export obligations without requiring direct database access.

## Scope

### In scope
- Accepting GDPR data export requests via a web form (web mode) or command-line invocation (manual mode)
- Authenticating against `cs-token-service` to obtain scoped access tokens for downstream APIs
- Collecting order history from `api-lazlo` (Lazlo service)
- Collecting consumer preference data from `api-lazlo`
- Collecting subscription data from `global-subscription-service`
- Collecting user-generated reviews from `ugc-api-jtier`
- Enriching review records with place/merchant details from `m3-placeread`
- Collecting profile address data from `consumer-data-service`
- Packaging all collected data into a ZIP archive of CSV files
- Delivering the archive via HTTP file download and email to the requesting agent
- Cleaning up all temporary files after delivery

### Out of scope
- Permanent storage of consumer data (all files are ephemeral)
- Direct database queries (all data is fetched via internal service APIs)
- Consumer identity deletion / right-to-erasure (this tool handles data export only)
- Automated scheduling or batch processing of requests

## Domain Context

- **Business domain**: Consumer Compliance / Support Operations
- **Platform**: Continuum
- **Upstream consumers**: Application Operations support agents (human users via the web UI); automation scripts via CLI
- **Downstream dependencies**: `cs-token-service`, `api-lazlo`, `global-subscription-service`, `ugc-api-jtier`, `m3-placeread`, `consumer-data-service`

## Stakeholders

| Role | Description |
|------|-------------|
| Application Operations Agents | Primary end users — initiate GDPR data export requests and receive the resulting ZIP archive |
| Analytics & Automation (AA) Team | Owns and maintains the service |
| Customer Support Engineering | Manages agent IDs for the Cyclops system used for token issuance |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Go | 1.23.5 | `go.mod` |
| Framework | Gin | 1.10.1 | `go.mod` |
| Runtime | Alpine Linux | 3.21 | `Dockerfile` |
| Build tool | go build | — | `Dockerfile` |
| Package manager | Go Modules | — | `go.mod` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `github.com/gin-gonic/gin` | 1.10.1 | http-framework | HTTP router and web server for the web UI mode |
| `github.com/BurntSushi/toml` | 1.5.0 | config | Parses `config/config.toml` service configuration file |
| `github.com/gammazero/workerpool` | 1.1.3 | scheduling | Manages a bounded worker pool (size 2) for background export tasks |
| `github.com/gin-contrib/sessions` | 1.0.3 | auth | Cookie-based session store for flash messages and form validation |
| `github.com/foolin/goview` | 0.3.0 | ui-framework | Go HTML template rendering engine for the Gin web UI |
| `github.com/goccy/go-json` | 0.10.5 | serialization | High-performance JSON unmarshalling of API responses |
| `gopkg.in/gomail.v2` | 2.0.0 | messaging | Sends the completed ZIP archive via SMTP email to the agent |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
