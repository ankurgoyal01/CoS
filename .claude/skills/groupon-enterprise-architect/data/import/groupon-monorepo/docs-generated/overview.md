---
service: "groupon-monorepo"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Internal Admin & B2B Operations"
platform: "Encore Cloud"
team: "Encore Core Team, B2B Team"
status: active
tech_stack:
  language: "TypeScript, Go, Python"
  language_version: "TS 5.9, Go 1.24, Python 3.x"
  framework: "Encore"
  framework_version: "1.54 (TS), 1.48 (Go)"
  runtime: "Node.js 22, Go 1.24.5, Docker"
  runtime_version: "Node 22, Go 1.24.5"
  build_tool: "Turborepo, Encore CLI"
  package_manager: "pnpm 9.0"
---

# Encore Platform Overview

## Purpose

The Encore Platform is Groupon's next-generation commerce backbone, built as a multi-language monorepo to power internal admin tools, B2B merchant operations, deal management, AI-driven content generation, and cross-platform integrations. It replaces and extends core capabilities from the legacy Continuum platform, offering modern microservices architecture with TypeScript and Go backends, React frontends, and Python AI/ML microservices. The platform is designed for scalability, extensibility, and rapid feature development across Groupon's business domains.

## Scope

### In scope
- Internal admin dashboard for Groupon operators (deal management, merchant ops, order tracking)
- B2B merchant-facing tools (accounts, salesforce integration, deal performance, reporting)
- AI-driven deal generation (AIDG) and content creation workflows
- Deal lifecycle management (creation, versioning, sync, publishing, alerts)
- Authentication and authorization for internal users (Google OAuth, JWT)
- Workflow orchestration via Temporal for long-running business processes
- Integration proxies for legacy Continuum services (orders, merchants, deals)
- Video processing and media management (Mux integration)
- Notification and messaging services (email via SendGrid, SMS via Twilio)
- Kafka consumer bridge for legacy event streams
- BigQuery analytics proxy and reporting
- Python-based AI/ML microservices (image classification, merchant quality, deal content generation)
- Go-based search and recommendation services (Vespa.ai, Booster API)
- Microfrontend architecture for embedded UI modules
- Chrome extension for internal productivity (IQ)

### Out of scope
- Consumer-facing marketplace frontend (handled by MBNXT platform)
- Core payment processing (handled by Continuum platform)
- Legacy Continuum service internals (Encore wraps but does not own them)
- Infrastructure provisioning (managed by Cloud Platform team)

## Domain Context

- **Business domain**: Internal Admin & B2B Operations, Deal Management, AI Content Generation
- **Platform**: Encore Cloud (GCP-backed)
- **Upstream consumers**: Groupon admin users, sales representatives, merchant partners (via admin UIs), MBNXT consumer frontend (via APIs)
- **Downstream dependencies**: Salesforce (CRM), BigQuery (analytics), Mux (video), Twilio (SMS), SendGrid (email), Bloomreach (personalization), Continuum legacy services (orders, merchants, deals), Vespa.ai (search), Kafka (event streaming), Teradata EDW

## Stakeholders

| Role | Description |
|------|-------------|
| Encore Core Team | Core platform ownership, infrastructure, shared services, authentication |
| Encore B2B Team | B2B domain services: deals, accounts, merchants, salesforce, reporting |
| RAPI Team | Collaborating team for Go-based recommendation and search integrations |
| Administrator | Groupon internal admin user operating the platform |
| Sales Representative | Sales user managing merchant accounts and deals |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | TypeScript | 5.9 | `apps/encore-ts/package.json` (devDependencies) |
| Language | Go | 1.24 | `apps/encore-go/go.mod` |
| Language | Python | 3.x | `apps/microservices-python/Dockerfile` |
| Framework | Encore (TS) | 1.54 | `apps/encore-ts/package.json` (encore.dev) |
| Framework | Encore (Go) | 1.48 | `apps/encore-go/go.mod` (encore.dev) |
| Framework | Next.js | 15.5 | `apps/admin-react-fe/package.json` |
| Framework | FastAPI | latest | `apps/microservices-python/` |
| Runtime | Node.js | 22+ | `package.json` (engines) |
| Runtime | Go | 1.24.5 | `apps/encore-go/go.mod` (toolchain) |
| Build tool | Turborepo | 2.5 | `package.json` (devDependencies) |
| Build tool | Encore CLI | latest | README.md |
| Package manager | pnpm | 9.0.5 | `package.json` (packageManager) |
| Linter/Formatter | Biome | 2.3.2 | `biome.json` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| encore.dev | 1.54.2 | http-framework | Backend framework for TypeScript microservices |
| drizzle-orm | 0.44.7 | orm | SQL database ORM for service data access |
| kafkajs | 2.2.4 | message-client | Kafka consumer for legacy event bridge |
| jsforce | 3.9.1 | integration | Salesforce CRM integration client |
| @temporalio/workflow | 1.13.0 | scheduling | Temporal workflow orchestration |
| @langchain/openai | 0.6.4 | ai | LLM integration for AI-driven features |
| @langchain/anthropic | 0.3.26 | ai | Anthropic Claude integration |
| langfuse | 3.38.5 | metrics | AI/LLM observability and tracing |
| ioredis | 5.4.1 | cache | Redis client for caching |
| pg | 8.13.3 | db-client | PostgreSQL database driver |
| mongodb | 6.20.0 | db-client | MongoDB client for document storage |
| zod | 3.23.8 | validation | Runtime schema validation |
| react | 19.1.2 | ui-framework | Frontend UI framework |
| antd | 5.24.3 | ui-framework | UI component library for admin dashboards |
| swr | 2.3.3 | state-management | Data fetching and caching for frontends |
| @mux/mux-node | 11.1.0 | integration | Video streaming and processing |
| twilio | 5.11.2 | integration | SMS messaging |
| @sendgrid/mail | 8.1.4 | integration | Email delivery |
| sharp | 0.33.5 | media | Image processing |
| puppeteer | 24.26.1 | automation | Browser automation for scraping |

> Only the most important libraries are listed here -- the ones that define how the platform works. Transitive and trivial dependencies are omitted. See each app's package.json or go.mod for full dependency lists.
