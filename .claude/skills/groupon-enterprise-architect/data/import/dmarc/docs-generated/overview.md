---
service: "dmarc"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Email / MTA"
platform: "Continuum"
team: "MTA"
status: active
tech_stack:
  language: "Go"
  language_version: "1.21"
  framework: "stdlib net/http"
  framework_version: ""
  runtime: "Alpine Linux"
  runtime_version: "3.19+"
  build_tool: "go build"
  package_manager: "Go modules"
---

# DMARC Service Overview

## Purpose

The DMARC service is Groupon's MTA (Mail Transfer Agent) tool for processing DMARC RUA (Aggregate Report) emails. It polls the Gmail mailbox `svc_dmarc@groupon.com` (queried via label `rua is:unread`) at one-minute intervals, extracts the attached XML report files (delivered as `.zip` or `.gz` archives), parses them according to RFC 7489, enriches each source IP record with a country code via GeoIP lookup, and writes structured JSON log records to disk. These logs are then shipped to ELK by a Filebeat sidecar for visibility into Groupon's email authentication posture (DKIM, SPF, and DMARC pass/fail rates).

## Scope

### In scope
- Polling the Gmail API for unread DMARC RUA report emails on a configurable query
- Fetching and decoding email attachments (gzip and zip formats)
- Parsing DMARC Aggregate Report XML (RFC 7489 `<feedback>` schema)
- Enriching each record's source IP with a GeoIP-derived country code and reverse-DNS hostname
- Writing one JSON record per DMARC `<record>` to a rotating log file (`/app/logs/dmarc_log.log`)
- Exposing an HTTP health-check endpoint (`/grpn/healthcheck`) for Kubernetes liveness probing
- Operating in two modes: one-shot staging mode (single message) and continuous production polling mode

### Out of scope
- Sending or modifying email messages (service is read-only, with soft delete capability)
- Enforcement of DMARC policy (policy is reported, not applied)
- DMARC forensic/failure (RUF) report processing
- Long-term persistent storage of parsed records (ELK handles retention)
- Direct exposure of parsed records via HTTP API

## Domain Context

- **Business domain**: Email / MTA — email authentication monitoring and compliance reporting
- **Platform**: Continuum
- **Upstream consumers**: ELK/Kibana (via Filebeat log shipping); dashboards at `https://logging-us.groupondev.com/goto/a69682a0-eaa1-11ee-873b-8d61e2168108`
- **Downstream dependencies**: Gmail API (Google), GeoIP database (`GeoIP.dat`, MaxMind legacy format)

## Stakeholders

| Role | Description |
|------|-------------|
| MTA Team | Owns and operates the service; responsible for Gmail OAuth credentials and token rotation |
| Security / Email Ops | Consumers of DMARC reports in ELK for authentication monitoring |
| Deliverability | Uses DMARC pass/fail data to investigate sending issues |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Go | 1.21 | `go.mod` |
| HTTP server | stdlib `net/http` | (Go stdlib) | `heartbeat.go` |
| Container base (build) | golang:alpine3.19 | alpine3.19 | `Dockerfile` |
| Container base (runtime) | alpine:latest | latest | `Dockerfile` |
| Build tool | go build | — | `Dockerfile`, `README.md` |
| Package manager | Go modules | — | `go.mod` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `google.golang.org/api` | v0.169.0 | http-client | Gmail API client (message listing, attachment fetch, label modification) |
| `golang.org/x/oauth2` | v0.17.0 | auth | Google OAuth2 authentication with offline token caching |
| `github.com/abh/geoip` | v0.0.0-20160510155516 | enrichment | MaxMind GeoIP legacy database lookup for country codes |
| `github.com/bobesa/go-domain-util` | v0.0.0-20190911083921 | enrichment | Extracts base domain from reverse-DNS PTR records |
| `github.com/pelletier/go-toml/v2` | v2.2.0 | serialization | TOML configuration file parsing |
| `gopkg.in/natefinch/lumberjack.v2` | v2.2.1 | logging | Rotating log file management (max 200 MB, 10 backups, 5-day retention, compressed) |
| `encoding/xml` (stdlib) | (Go stdlib) | serialization | DMARC aggregate report XML parsing |
| `encoding/json` (stdlib) | (Go stdlib) | serialization | JSON marshalling of parsed records to log output |
| `archive/zip` + `compress/gzip` (stdlib) | (Go stdlib) | serialization | Decompression of email attachment archives |
