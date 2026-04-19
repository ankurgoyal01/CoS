---
service: "bynder-integration-service"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Editorial / Digital Asset Management"
platform: "continuum"
team: "Editorial / Gazebo team (gazebo-dev@groupon.com)"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "JTier (Dropwizard-based)"
  framework_version: "5.14.1"
  runtime: "OpenJDK"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Bynder Integration Service Overview

## Purpose

The bynder-integration-service bridges Groupon's Editorial team workflow with the Continuum image infrastructure. It continuously synchronizes images and metadata from the Bynder Digital Asset Management (DAM) system and an Image Asset Manager (IAM) into Groupon's local image database and Image Service, acting as the single source of truth for all editorially managed image assets. It also exposes an API for querying, updating, and uploading images, and manages taxonomy and keyword metadata used for content organization.

## Scope

### In scope

- Scheduled and on-demand synchronization of images from Bynder DAM to the local image database and Image Service
- Scheduled and on-demand synchronization of images from IAM (Image Asset Manager)
- REST API for image metadata retrieval, update, and upload
- Taxonomy metadata synchronization from the Taxonomy Service
- Keyword and source metadata management
- Async message event processing for Bynder, IAM, and Taxonomy updates
- Stock image recommendations

### Out of scope

- Original image hosting or CDN delivery (handled by Image Service)
- Deal or voucher data management (handled by Deal Catalog Service)
- User authentication and authorization (handled by upstream auth services)
- Editorial content authoring workflows beyond image asset management

## Domain Context

- **Business domain**: Editorial / Digital Asset Management
- **Platform**: Continuum
- **Upstream consumers**: Editorial Client App, internal services consuming image metadata
- **Downstream dependencies**: Bynder DAM, Image Service, Deal Catalog Service, Taxonomy Service, Message Bus, Keywords Model API

## Stakeholders

| Role | Description |
|------|-------------|
| Editorial Team | Primary users who manage image assets in Bynder and consume synchronized data via the Editorial Client App |
| Platform / Engineering | Operates and monitors the synchronization pipeline and integration health |
| Deal Catalog Service | Downstream consumer of synchronized image metadata |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | Inventory / `pom.xml` |
| Framework | JTier (Dropwizard-based) | 5.14.1 | `jtier-service-pom 5.14.1` |
| Runtime | OpenJDK | 11 | Inventory |
| Build tool | Maven | 3 | `pom.xml` |
| Package manager | Maven | 3 | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-service-pom | 5.14.1 | http-framework | JTier parent POM; Dropwizard-based service foundation |
| cronus | 0.1.0-rc8 | scheduling | Distributed cron/scheduled job support |
| jtier-daas-mysql | — | db-client | JTier MySQL data access abstraction |
| jtier-jdbi | — | orm | JDBI-based data access layer |
| jtier-messagebus-client | — | message-client | JTier message bus publish/subscribe client |
| jtier-quartz-bundle | — | scheduling | Quartz scheduler integration bundle |
| jtier-auth-bundle | 0.2.3 | auth | JTier authentication bundle |
| retrofit2 | 2.3.0 | http-framework | Type-safe HTTP client for Bynder and downstream REST calls |
| bynder-java-sdk | — | http-framework | Bynder official Java SDK for DAM API access |
| lombok | 1.18.2 | serialization | Boilerplate reduction via annotations |
| gson | 2.7 | serialization | JSON serialization/deserialization |
| wiremock | 2.3.1 | testing | HTTP mock server for integration testing |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
