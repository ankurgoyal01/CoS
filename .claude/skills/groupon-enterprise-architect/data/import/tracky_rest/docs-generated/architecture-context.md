---
service: "tracky-rest"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumTrackyRestService", "continuumTrackyJsonLogFiles"]
---

# Architecture Context

## System Context

Tracky REST is a container within the `continuumSystem` (Continuum Platform). It sits at the ingestion boundary between arbitrary HTTP clients (browsers, internal services) and the Groupon data pipeline. Clients POST JSON events directly to this service; the service writes them to local log files, which are then shipped by an external log-transport mechanism to the `tracky_json_nginx` Kafka topic consumed by downstream analytics systems.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Tracky REST Service | `continuumTrackyRestService` | Service | Nginx + Perl | unspecified | Nginx endpoint that accepts JSON payloads and writes Tracky log events for downstream transport |
| Tracky JSON Log Files | `continuumTrackyJsonLogFiles` | Storage | Filesystem | unspecified | Local filesystem logs (`tracky_json`) written per request and rotated hourly |

## Components by Container

### Tracky REST Service (`continuumTrackyRestService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| HTTP Endpoint (`httpEndpoint`) | Nginx `location /tracky` — handles POST requests and CORS preflight OPTIONS; enforces POST-only; adds CORS headers | Nginx |
| Tracky Perl Handler (`perlHandler`) | Parses the JSON request body; enriches events with HTTP metadata headers; writes each event object to the cronolog pipe | Perl |
| Cronolog Log Writer (`cronologWriter`) | Receives JSON lines from the Perl handler; writes to hourly-rotated log files at `/var/groupon/log/tracky_json/rotated/tracky_json.<pid>.log`; maintains a symlink at `/var/groupon/log/tracky_json/tracky_json.<pid>.log` | cronolog |
| Post-Rotate Hook (`postRotateHook`) | Executed by cronolog upon each hourly rotation; appends a `_tracky_hourly_canary_event_2` marker event to the completed log file so downstream parsers can detect file completion | Ruby |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `clientApplications` (external) | `continuumTrackyRestService` | POST `/tracky` JSON events | HTTP |
| `continuumTrackyRestService` | `continuumTrackyJsonLogFiles` | Writes Tracky JSON logs (one line per event) | Filesystem write |
| `continuumTrackyJsonLogFiles` | `kafkaTrackyJsonNginxTopic` (external) | Log shipping transports events to Kafka | Log shipping (external) |

## Architecture Diagram References

- Component: `trackyRestServiceComponents`
- Dynamic (request flow): `trackyRestRequestFlow`
