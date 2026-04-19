---
service: "tracky-rest"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [kafka]
---

# Events

## Overview

Tracky REST does not directly publish to Kafka. Instead, it writes enriched JSON events to local filesystem log files, which are consumed by an external log-shipping pipeline that transports them to the `tracky_json_nginx` Kafka topic. The service is therefore an indirect Kafka producer: it owns the event schema and enrichment but delegates transport to the log shipper. The service does not consume any Kafka topics.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `tracky_json_nginx` | Arbitrary caller-defined JSON events + enrichment | HTTP POST to `/tracky` | `__http_timestamp`, `__http_vhost_name`, `__http_xff`, `__http_client_ip`, `__http_x_request_id`, `__http_xrepsheet` + all caller-supplied fields |
| `tracky_json_nginx` | `_tracky_hourly_canary_event_2` (marker) | Hourly log rotation via cronolog post-rotate hook | `event_name`, `event_id`, `web_host`, `event_client_timestamp`, `date_hr`, `num_workers`, `__http_vhost_name`, `__http_xff`, `__http_timestamp`, `__http_client_ip` |

### Caller-defined Tracky Event Detail

- **Topic**: `tracky_json_nginx`
- **Trigger**: Every valid HTTP POST to `/tracky` containing a JSON object or array of objects.
- **Payload**: All caller-supplied key-value pairs, plus server-side enrichment fields (`__http_timestamp`, `__http_vhost_name`, `__http_xff`, `__http_client_ip`, `__http_x_request_id`, `__http_xrepsheet`). Each object in an array is written as a separate log line.
- **Consumers**: Bloodhound user-interaction pipeline and downstream analytics systems (tracked externally in the central architecture model).
- **Guarantees**: At-least-once — events are written to disk before acknowledgement; Kafka delivery guarantee depends on the external log shipper.

### `_tracky_hourly_canary_event_2` Marker Event Detail

- **Topic**: `tracky_json_nginx`
- **Trigger**: Each hourly log file rotation triggered by `cronolog`.
- **Payload**: `event_name` = `_tracky_hourly_canary_event_2`, `event_id` = `<hostname>-<filename>-<pid>`, `web_host` = server hostname, `event_client_timestamp` = Unix epoch (integer), `date_hr` = `<hostname>-YYYY-MM-DD-HH`, `num_workers` = count of nginx worker processes, plus standard HTTP enrichment fields (`__http_vhost_name`, `__http_xff`, `__http_timestamp`, `__http_client_ip`).
- **Consumers**: Downstream parsers that detect end-of-file markers to confirm log file completeness before archiving.
- **Guarantees**: At-least-once — appended directly to the completed log file by the post-rotate Ruby script.

## Consumed Events

> No evidence found in codebase. Tracky REST does not consume any Kafka topics or async queues.

## Dead Letter Queues

> No evidence found in codebase. Dead-letter handling, if any, is managed by the external log-shipping pipeline.
