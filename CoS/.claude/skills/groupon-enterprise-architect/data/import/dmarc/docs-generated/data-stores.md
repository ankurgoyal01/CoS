---
service: "dmarc"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "dmarc-log-file"
    type: "file"
    purpose: "Rotating JSON log output consumed by Filebeat"
  - id: "geoip-dat"
    type: "file"
    purpose: "MaxMind legacy GeoIP country database bundled in container image"
---

# Data Stores

## Overview

The DMARC service is largely stateless. It does not own a relational database, cache, or object store. Its two storage artefacts are both file-based: a rotating application log file that acts as the output buffer for parsed DMARC records (consumed by Filebeat), and the bundled GeoIP binary database used for IP-to-country enrichment at parse time.

## Stores

### Application Log File (`dmarc-log-file`)

| Property | Value |
|----------|-------|
| Type | Rotating flat file (JSON-per-line) |
| Architecture ref | `dmarcService` (logWriter component) |
| Purpose | Buffer for structured DMARC JSON records, consumed by Filebeat sidecar |
| Ownership | owned |
| Path | `/app/logs/dmarc_log.log` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `JsonRecord` (log line) | One log line per DMARC `<record>` element | `report_metadata`, `policy_published`, `data` (source IP, count, policy evaluation), `identifiers` (header_from, envelope_from), `auth_results` (DKIM/SPF), `country_code`, `message_id`, `attachment_id`, `cursor_value` |

#### Access Patterns

- **Read**: Filebeat sidecar tails the file continuously and ships log lines to ELK (`sourceType: mta_dmarc`).
- **Write**: Log Writer component appends one JSON line per parsed DMARC record. lumberjack rotates at 200 MB, retains 10 backups, compresses old files, purges after 5 days.
- **Indexes**: None (flat file).

### GeoIP Database (`geoip-dat`)

| Property | Value |
|----------|-------|
| Type | Binary flat file (MaxMind legacy GeoIP v1 `.dat` format) |
| Architecture ref | `dmarcService` (geoIpLookup component) |
| Purpose | Map source IP addresses to two-letter country codes at parse time |
| Ownership | bundled (read-only, baked into container image at `COPY GeoIP.dat /app/GeoIP.dat`) |
| Path | `/app/GeoIP.dat` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Country record | IP-to-country mapping | Source IP → ISO 3166-1 alpha-2 country code |

#### Access Patterns

- **Read**: Point lookup per parsed DMARC record source IP. Called synchronously during XML parsing.
- **Write**: Read-only; the file is bundled at image build time and never modified at runtime.
- **Indexes**: MaxMind internal B-tree index within the `.dat` binary.

## Caches

> No caches used. GeoIP lookups are performed in-process against the in-memory-mapped `.dat` file.

## Data Flows

Parsed DMARC records flow from the in-process `QueueRecords` channel to the Log Writer, which appends them to `/app/logs/dmarc_log.log`. Filebeat reads from this file and ships records to ELK for long-term storage and dashboarding. No CDC, ETL pipelines, or materialized views exist within this service.
