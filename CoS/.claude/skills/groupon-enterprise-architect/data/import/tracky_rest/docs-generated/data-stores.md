---
service: "tracky-rest"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumTrackyJsonLogFiles"
    type: "filesystem"
    purpose: "Hourly-rotated JSON log files used as a staging buffer before Kafka transport"
---

# Data Stores

## Overview

Tracky REST uses the local filesystem as its only data store. Each Nginx worker process maintains an open pipe to `cronolog`, which writes JSON-encoded events to hourly-rotated log files. There are no relational databases, caches, or cloud object stores owned by this service. The filesystem acts as a durable staging buffer between HTTP ingestion and the external log-shipping pipeline.

## Stores

### Tracky JSON Log Files (`continuumTrackyJsonLogFiles`)

| Property | Value |
|----------|-------|
| Type | Filesystem (local disk) |
| Architecture ref | `continuumTrackyJsonLogFiles` |
| Purpose | Staged event buffer — one JSON object per line, rotated hourly for transport to Kafka |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `tracky_json.<pid>.log` (symlink) | Active log file for a given Nginx worker process | All caller-supplied fields + `__http_timestamp`, `__http_vhost_name`, `__http_xff`, `__http_client_ip`, `__http_x_request_id`, `__http_xrepsheet` |
| `tracky_json.YYYY-MM-DD_HH.<pid>.log` (rotated) | Completed hourly log file awaiting archival and shipping | Same schema as active file, plus a trailing `_tracky_hourly_canary_event_2` marker record |
| `tracky_json_archive.log` | Compressed archive inventory log produced by the hourly cron archival job | Gzip compression status lines |

#### Access Patterns

- **Read**: External log-shipping pipeline reads completed rotated files from `/var/groupon/log/tracky_json/rotated/`. No reads are performed by the Tracky REST service itself.
- **Write**: Each validated POST request appends one JSON line per event object to the active log file via the `cronolog` pipe (autoflush enabled). The post-rotate hook appends one marker JSON line to the just-completed file upon rotation.
- **Indexes**: Not applicable — flat JSON line files, no indexing.

#### Filesystem layout

| Path | Contents |
|------|----------|
| `/var/groupon/log/tracky_json/tracky_json.<pid>.log` | Symlink to active rotated log file for worker `<pid>` |
| `/var/groupon/log/tracky_json/rotated/tracky_json.YYYY-MM-DD_HH.<pid>.log` | Completed hourly log files |
| `/var/groupon/log/tracky_json/tracky_json_archive.log` | Archive inventory log |
| `/var/groupon/log/nginx/access.log` | Nginx access log (standard HTTP access) |
| `/var/groupon/log/nginx/error.log` | Nginx error log (notice level) |

#### Retention and Archival

- Cron job at `1 * * * *`: gzip-compresses rotated `tracky_json` log files older than 6 hours (360 minutes).
- Cron job at `15 * * * *`: deletes compressed rotated files older than 7 days (`-ctime +7`).
- Nginx logs rotated by logrotate with 336 rotations kept, compressed with date extension; files in `/var/groupon/log/nginx/rotated` older than 45 days are purged on each rotation.

## Caches

> No evidence found in codebase. This service uses no caches.

## Data Flows

Incoming HTTP events are written synchronously to the local filesystem by the Perl handler. Upon hourly rotation, `cronolog` invokes the post-rotate hook which appends a marker record. An external log-shipping agent (not part of this repository) then reads the completed rotated files and transports their contents to the `tracky_json_nginx` Kafka topic. Gzip archival cron jobs compress and prune old files to manage disk usage.
