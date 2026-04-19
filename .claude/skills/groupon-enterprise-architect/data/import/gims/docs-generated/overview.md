---
service: "gims"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Shared Infrastructure / Media"
platform: "continuum"
team: "Media / Platform team"
status: active
tech_stack:
  language: "Java"
  language_version: "(not specified)"
  framework: "Continuum / JTier (inferred)"
  framework_version: "(not specified)"
  runtime: "JVM"
  runtime_version: "(not specified)"
  build_tool: "Maven (inferred)"
  package_manager: "Maven (inferred)"
---

# GIMS (Groupon Image Management Service) Overview

## Purpose

GIMS is Groupon's centralized image management service within the Continuum platform. It provides image storage, transformation, retrieval, and delivery capabilities for the entire Groupon ecosystem. GIMS integrates with Akamai CDN for edge delivery, enabling high-performance, globally distributed image serving for consumer-facing and merchant-facing applications alike.

## Scope

### In scope

- Image upload and storage (file-based and URL-based uploads)
- Image transformation and processing (resizing, cropping, format conversion)
- Signed URL generation for secure image access
- Image metadata management and retrieval
- CDN integration with Akamai for edge delivery and caching
- Map image request signing for location-based content
- Campaign and editorial image asset management
- Theme and custom asset storage for merchant experiences

### Out of scope

- Video processing and storage (handled by media-service and Encore Video)
- Digital asset management workflows (handled by bynder-integration-service)
- Image editorial tagging and taxonomy (handled by marketing-and-editorial-content-service)
- Frontend image rendering and display logic (handled by consuming services)
- CDN configuration and edge rules management (owned by infrastructure/CDN team)

## Domain Context

- **Business domain**: Shared Infrastructure / Media
- **Platform**: Continuum
- **Upstream consumers**: Metro Draft Service, Merchant Page Service, MyGroupons Service, Messaging Service, Marketing Editorial Content Service, Image Service Primer, Media Service, UGC Async Service, Bynder Integration Service (via Image Service), Encore Images (next-gen wrapper)
- **Downstream dependencies**: Akamai CDN (edge delivery), image storage backend

## Stakeholders

| Role | Description |
|------|-------------|
| Media / Platform team | Owns and operates GIMS; maintains image APIs and storage infrastructure |
| Merchant Tools teams | Upload and manage deal and merchant images via Metro Draft and merchant pages |
| Marketing / Editorial team | Upload and retrieve editorial image assets via Bynder integration and MECS |
| Consumer Experience teams | Depend on GIMS for fast image delivery via CDN to consumer-facing pages |
| Encore Platform team | Building next-gen Images service that wraps GIMS for the Encore platform |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | (not specified) | `containers.dsl` — `"Java"` |
| Framework | Continuum / JTier (inferred) | (not specified) | Service follows Continuum platform conventions |
| Runtime | JVM | (not specified) | Java-based service |
| Build tool | Maven (inferred) | (not specified) | Standard for Continuum Java services |
| Package manager | Maven (inferred) | | |

### Key Libraries

> No evidence found in codebase. The GIMS source repository is not federated into the architecture repo. Library details should be obtained from the service's `pom.xml` or build manifest.

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
