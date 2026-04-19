---
service: "marketing-and-editorial-content-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Marketing and Editorial Content"
platform: "Continuum"
team: "MARS"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Dropwizard"
  framework_version: "inherited from jtier-service-pom 5.14.1"
  runtime: "JVM"
  runtime_version: "17"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Marketing and Editorial Content Service Overview

## Purpose

The Marketing and Editorial Content Service (MECS) is an internal Groupon platform service that manages editorial assets — images, text content, and classification tags — used by marketing and merchandising workflows. It exposes a RESTful API that allows internal clients to create, search, update, patch, and delete content records, with built-in profanity checking on text submissions and integrated image upload to the shared Global Image Service (GIMS). All mutations are tracked in an audit trail stored in PostgreSQL.

## Scope

### In scope

- CRUD operations for editorial image content records (including file upload via multipart form)
- CRUD operations for editorial text content records (email, push notification, wolfhound text/JSON, testing component types)
- Read-only listing of content classification tags
- Lookup of valid enum values (Project, Locale, ImageType, AuditAction, LocationType, TextComponent, TextContentType, OrderBy)
- Profanity screening of text content before persistence
- Image upload forwarding to the Global Image Service and metadata storage
- Audit trail recording for content INSERT, UPDATE, and DELETE actions
- JSON Patch (RFC 6902) support for partial updates on image and text records

### Out of scope

- Consumer-facing deal or product content delivery
- Email delivery or push notification dispatch (MECS stores the content; other services handle delivery)
- Image transformation or resizing (delegated to Global Image Service and CDN)
- Authentication and identity management (handled by jtier ClientId auth bundle)
- Content delivery to end users

## Domain Context

- **Business domain**: Marketing and Editorial Content
- **Platform**: Continuum
- **Upstream consumers**: Internal Groupon tools including Merch UI (CORS enabled for browser access), and any internal service authenticated via ClientId
- **Downstream dependencies**: MECS Postgres (Write) for mutations, MECS Postgres (Read) for queries, Global Image Service (GIMS) at `https://img.grouponcdn.com` for image storage

## Stakeholders

| Role | Description |
|------|-------------|
| MARS Team | Service owner, responsible for development and operations |
| Merch UI / Editorial Tools | Primary upstream consumers of the content API |
| Marketing Operations | Creates and manages editorial content records |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | `pom.xml` `project.build.targetJdk`, `.java-version` |
| Framework | Dropwizard (via jtier) | jtier-service-pom 5.14.1 | `pom.xml` parent |
| Runtime | JVM | 17 | `.ci/Dockerfile` `dev-java17-maven` |
| Build tool | Maven | inherited | `pom.xml` |
| Package manager | Maven | | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-auth-bundle | from jtier BOM | auth | ClientId-based authentication and authorization |
| jtier-daas-postgres | from jtier BOM | db-client | Managed PostgreSQL connection pooling via jtier DaaS |
| jtier-jdbi3 | from jtier BOM | orm | JDBI 3 integration for SQL data access |
| jtier-migrations | from jtier BOM | db-client | Flyway-based PostgreSQL schema migrations |
| jtier-retrofit | from jtier BOM | http-framework | OkHttp/Retrofit HTTP client for outbound HTTPS calls |
| dropwizard-forms | from jtier BOM | http-framework | Multipart form support for image upload endpoint |
| com.groupon.essence:profanity | 2.2.0 | validation | Language-aware profanity detection on text content |
| com.github.fge:json-patch | 1.13 | validation | RFC 6902 JSON Patch application for partial updates |
| org.jsoup:jsoup | 1.16.1 | validation | HTML sanitization for `@HtmlClean` annotation |
| retrofit2 + okhttp3 | from jtier BOM | http-framework | Retrofit client for Global Image Service HTTPS calls |
| commons-lang | from jtier BOM | validation | String utility methods (StringUtils) |
| commons-io | from jtier BOM | validation | InputStream handling for image byte conversion |
| io.swagger (swagger-annotations) | from jtier BOM | logging | Swagger/OpenAPI annotation-driven API documentation |
