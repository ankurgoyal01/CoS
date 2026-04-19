---
service: "deal-alerts"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Supply & Merchant Operations"
platform: "Continuum"
team: "Deal Alerts"
status: active
tech_stack:
  language: "TypeScript"
  language_version: "5.9"
  framework: "Next.js"
  framework_version: "16"
  runtime: "Node.js"
  runtime_version: "22"
  build_tool: "Turbo"
  package_manager: "pnpm"
---

# Deal Alerts Overview

## Purpose

Deal Alerts is a supply automation platform that ingests Groupon deal data from the Marketing Deal Service (MDS), tracks full history with field-level deltas, generates alerts when supply-critical events occur (sold-out, deal ending, deal ended), and orchestrates downstream actions including Salesforce task creation, SMS merchant notifications, and daily email summaries. It provides a Next.js operational UI for alert configuration, observability, and debugging.

## Scope

### In scope
- Ingesting and snapshotting deal data from MDS API
- Computing field-level deltas between successive snapshots
- Generating alerts from supply events (SoldOut, DealEnding, DealEnded, OptionSoldOut)
- Importing external alert signals from BigQuery
- Configuring alert-to-action mappings with severity matrices
- Orchestrating actions: Salesforce task creation, chat messages, SMS notifications
- Sending SMS notifications via Twilio with reply handling and opt-out management
- Generating daily summary emails for stakeholders
- Attributing inventory replenishment to alert actions
- Muting alerts per account or opportunity
- Full-text search across deal snapshots
- BetterAuth SSO with Google OAuth restricted to Groupon domain

### Out of scope
- Deal creation or modification (owned by MDS / Continuum commerce)
- Merchant portal UI (owned by MBNXT)
- Payment processing
- Consumer-facing deal pages

## Domain Context

- **Business domain**: Supply & Merchant Operations
- **Platform**: Continuum
- **Upstream consumers**: Internal operations teams, merchant success managers via the web app
- **Downstream dependencies**: Marketing Deal Service (MDS), Salesforce, Twilio, BigQuery

## Stakeholders

| Role | Description |
|------|-------------|
| Merchant Success Managers | Primary users who receive alerts about deal supply issues and take action |
| Supply Operations Team | Monitors deal inventory and replenishment patterns |
| Deal Alerts Engineering | Builds and operates the platform |
| Analytics Team | Consumes BigQuery alert signals and attribution data |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | TypeScript | 5.9 | `apps/web/package.json` devDependencies |
| Framework | Next.js | 16.0.1-canary.5 | `apps/web/package.json` dependencies |
| Runtime | Node.js | 22 | `Dockerfile` base image |
| Build tool | Turbo | 2.5 | `package.json` devDependencies |
| Package manager | pnpm | 9.0.0 | `package.json` packageManager field |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Kysely | 0.28 | db-client | Type-safe SQL query builder for PostgreSQL |
| oRPC | 1.10 | http-framework | Type-safe RPC framework for client-server communication |
| TanStack Query | 5.90 | state-management | Server state management and data fetching/caching |
| Zod v4 | 4.1 | validation | Runtime schema validation for API inputs and outputs |
| BetterAuth | 1.3 | auth | Google SSO authentication with domain allowlist |
| pg | 8.16 | db-client | PostgreSQL connection pool driver |
| Radix UI | 1.4 | ui-framework | Accessible headless UI primitives |
| Tailwind CSS | 4.1 | ui-framework | Utility-first CSS framework |
| Recharts | 2.15 | ui-framework | Charting library for SMS analytics visualization |
| date-fns | 4.1 | utility | Date manipulation and formatting |
| dbmate | 2.21 | db-client | Database migration tool |
| Testcontainers | 11.5 | testing | Ephemeral PostgreSQL containers for integration tests |
| Biome | 2.2 | linting | Fast formatter and linter (via Ultracite) |
| Luxon | 3.7 | utility | Date/time library used in n8n-blocks package |
| template-renderer | workspace | library | Shared template rendering engine for notification previews |

> Only the most important libraries are listed here -- the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
