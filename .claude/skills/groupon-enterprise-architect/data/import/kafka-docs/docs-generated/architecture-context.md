---
service: "kafka-docs"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumKafkaDocsSite"]
---

# Architecture Context

## System Context

The `kafka-docs` service is a documentation pipeline within the `continuumSystem` (Continuum Platform). It does not process business transactions; instead, it maintains the authoritative reference documentation for Groupon's Kafka streaming infrastructure and publishes it as a static site. The pipeline reads markdown source files authored by the Data Systems team, builds them into a static HTML site via GitBook CLI, and deploys the output to a GitHub Pages branch (`gh-pages`). End users — Groupon service engineers — browse the published site at `http://kafka-docs.groupondev.com` to learn how to produce to, consume from, and operate Kafka clusters.

The underlying Kafka clusters documented here span three on-prem colos (SNC1, SAC1, DUB1) and AWS MSK cloud environments, all managed by the Data Systems team.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Kafka Docs Site | `continuumKafkaDocsSite` | Docs / Static Site | GitBook / Static Site | 3.2.2 | GitBook-based documentation site and publishing pipeline for Kafka usage and operations at Groupon. |

## Components by Container

### Kafka Docs Site (`continuumKafkaDocsSite`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `markdownSource` | Holds all markdown files, runbooks, topic guides, and navigation metadata under `docs/src/` | Markdown |
| `gitbookBuilder` | Executes the build process defined by `docs/Makefile` and `docs/book.json` to produce static site output | GitBook CLI |
| `docsPublisher` | Deploys generated static files to the `gh-pages` branch for GitHub Pages hosting via `make publish` | Make publish |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `markdownSource` | `gitbookBuilder` | Provides markdown content and navigation metadata | File system (build-time) |
| `gitbookBuilder` | `docsPublisher` | Builds static documentation assets for publication | File system (build-time) |
| `docsPublisher` | GitHub Pages (gh-pages branch) | Publishes generated documentation site content | Git push |

## Architecture Diagram References

- Component: `components-continuum-kafka-docs-site`
- Dynamic (build/publish flow): `dynamic-docs-publishing-flow`
