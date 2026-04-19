---
service: "lead-gen"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Sales / Lead Generation"
platform: "Continuum"
team: "Sales Engineering"
status: active
tech_stack:
  language: "Java"
  language_version: "21"
  framework: "Spring Boot"
  framework_version: "3.x"
  runtime: "Java"
  runtime_version: "21"
  build_tool: "Gradle"
  package_manager: "Gradle"
---

# LeadGen Service Overview

## Purpose

LeadGen Service is the prospect acquisition and outreach engine for Groupon's Sales organization. It automates the full lead lifecycle: scraping potential merchant leads from web sources via Apify, enriching them with business intelligence from the PDS inference engine and merchant quality scoring, conducting email outreach campaigns through Mailgun, and synchronizing qualified prospects into Salesforce as Accounts and Contacts. The service exists to increase sales pipeline volume and reduce manual prospecting effort for the Sales team.

## Scope

### In scope

- Web scraping of prospect leads using Apify actors
- Lead deduplication against existing database records and Salesforce
- Enrichment of leads with PDS (Probabilistic Data Service) inference data
- Enrichment of leads with merchant quality scores from the AIDG quality scoring service
- Validation and scoring of enriched leads for outreach readiness
- Email outreach campaign execution via Mailgun
- Inbox warmup and deliverability management
- Account and Contact creation in Salesforce for qualified leads
- n8n workflow orchestration for scheduled scraping, enrichment, and distribution jobs
- Workflow status tracking and logging

### Out of scope

- Direct Google Places API calls (handled by Apify actors internally)
- Clay-based automated lead sourcing (Clay operates externally and uses Encore wrappers for AIDG)
- Bird messaging integration (preferred provider for Clay path, not directly used by LeadGen service)
- Merchant onboarding beyond CRM record creation (handled by downstream sales processes)
- Deal creation and pricing (handled by Deal Catalog and commerce services)
- Payment processing and invoicing (handled by Accounting Service)

## Domain Context

- **Business domain**: Sales / Lead Generation
- **Platform**: Continuum
- **Upstream consumers**: Sales team (via Salesforce), n8n workflow scheduler (automated triggers)
- **Downstream dependencies**: `apify` (web scraping), `inferPDS` (PDS enrichment), `merchantQuality` (quality scoring), `mailgun` (email outreach), `salesForce` (CRM sync), `leadGenDb` (PostgreSQL persistence)

## Stakeholders

| Role | Description |
|------|-------------|
| Sales Engineering | Service owner team; builds and operates the lead generation pipeline |
| Sales Operations | Primary consumer of generated leads in Salesforce; defines outreach criteria |
| AIDG Team | Owns the inferPDS and merchantQuality enrichment services consumed by LeadGen |
| Data Platform | Provides PDS inference data used for lead enrichment |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 21 | DSL container description |
| Framework | Spring Boot | 3.x | DSL container description |
| Runtime | Java | 21 | DSL container description |
| Build tool | Gradle | — | Inferred from Java service conventions |
| Workflow engine | n8n | — | `leadGenWorkflows` container definition |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Spring Boot | 3.x | http-framework | Core application framework and REST API layer |
| Spring Data JPA | — | orm | ORM and repository abstraction for PostgreSQL access |
| PostgreSQL JDBC | — | db-client | JDBC driver for leadGenDb connectivity |
| n8n | — | scheduling | Workflow orchestration for scraping, enrichment, and distribution jobs |
| Apify Client | — | http-framework | SDK for invoking Apify scraping actors |
| Mailgun SDK | — | http-framework | Client for Mailgun email outreach API |
| Salesforce REST API | — | http-framework | Client for Salesforce Account/Contact creation |

> Only the most important libraries are listed here -- the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
