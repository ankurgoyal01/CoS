---
service: "dmarc"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [dmarcService]
---

# Architecture Context

## System Context

The DMARC service is a `continuumSystem` workload that sits within Groupon's Continuum Platform. It operates as a scheduled poller with no inbound traffic from other internal services. Its two external integration points are the Google Gmail API (source of DMARC RUA report emails) and the Elastic logging stack (destination for structured JSON records, via a Filebeat sidecar). No other Continuum services call or depend on the DMARC service directly; its output is consumed exclusively through the shared ELK observability pipeline.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| DMARC Service | `dmarcService` | Service | Go, Docker | Go 1.21 | Processes DMARC RUA reports from Gmail and writes structured logs |

## Components by Container

### DMARC Service (`dmarcService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Gmail Poller | Periodic poller and scheduler for the DMARC mailbox. In production mode fires every 1 minute via `time.Ticker`; in staging mode runs once. | Go |
| Gmail Client | Gmail API client for listing unread messages, fetching full message metadata, retrieving attachments, and removing the UNREAD label. | Go |
| Report Processor | Reads the raw attachment stream, detects gzip or zip encoding, decompresses, and XML-parses the DMARC `<feedback>` document into typed Go structs. Dispatches one `JsonRecord` per `<record>` element to the Log Writer queue. | Go |
| GeoIP Lookup | Opens the MaxMind legacy `GeoIP.dat` database and resolves a source IP address to a two-letter country code. Also performs reverse-DNS and base-domain lookups to populate `reverse_dns` and `base_domain` fields. | Go |
| Log Writer | Consumes `JsonRecord` values from the in-process channel, serialises them to JSON, and appends each as a single line to the rotating log file managed by lumberjack. | Go |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `gmailPoller` | `gmailClient` | Triggers mailbox fetch on every tick | in-process |
| `gmailClient` | `reportProcessor` | Delivers Gmail message + attachment stream via channel | in-process channel |
| `reportProcessor` | `geoIpLookup` | Enriches each record's source IP with country code | in-process |
| `reportProcessor` | `logWriter` | Emits JSON record via channel | in-process channel |
| `dmarcService` | Gmail API (external) | Fetches DMARC RUA messages and attachments | HTTPS / OAuth2 |
| `dmarcService` | Elastic Logging (external) | Ships processing logs via Filebeat sidecar | Filebeat / HTTPS |

## Architecture Diagram References

- Component: `dmarcServiceComponents`
- Dynamic view: `dmarcProcessing`
