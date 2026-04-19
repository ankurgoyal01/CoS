---
service: "place-service"
title: "Salesforce Place Synchronization"
generated: "2026-03-03"
type: flow
flow_name: "salesforce-sync"
flow_type: event-driven
trigger: "Salesforce place record change event consumed by sf-m3-synchronizer-worker"
participants:
  - "sf-m3-synchronizer-worker"
  - "continuumPlacesServicePostgres"
  - "continuumPlacesServiceOpenSearch"
architecture_ref: "dynamic-place-read-flow"
---

# Salesforce Place Synchronization

## Summary

The Salesforce place synchronization flow is operated by the `sf-m3-synchronizer-worker` — a separate Kubernetes deployment that runs as a sidecar within the `m3-placeread` service boundary. It consumes events from the Groupon internal message bus (mbus) representing Salesforce place record changes and translates them into M3 place create or update operations. The worker supports a wide range of place data sources beyond Salesforce, including crowdsourced, third-party aggregator, and internal Groupon sources.

## Trigger

- **Type**: event
- **Source**: Groupon internal message bus (mbus); events originating from Salesforce and other configured source systems
- **Frequency**: Continuous (worker maintains persistent message bus subscription)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| sf-m3-synchronizer-worker | Consumes sync events; translates Salesforce records into M3 place writes | External worker image (`docker-conveyor.groupondev.com/m3/sf-m3-synchronizer`) |
| Place Postgres | Destination for place record create/update | `continuumPlacesServicePostgres` |
| Place OpenSearch | Index updated following place write | `continuumPlacesServiceOpenSearch` |

## Source Names Processed

The worker is configured with a `SOURCE_NAMES` environment variable mapping source IDs to display names. Supported sources include (non-exhaustive):

| Source ID | Display Name |
|-----------|-------------|
| `salesforce` | Salesforce |
| `salesforce_account` | Account |
| `salesforce_lead` | Lead |
| `salesforce_performer` | Performer |
| `salesforce_account_international` | Salesforce Account International |
| `salesforce_account_address` | Salesforce Account Address |
| `m3` | M3 |
| `crowd_sourced` | CrowdSource |
| `google_places` | Google |
| `yelp` | Yelp |
| `foursquare` | Foursquare |
| `tripadvisor` | TripAdvisor |
| `factual` | Factual |
| `localeze` | Localeze |
| `facebook` | Facebook |
| `groupon_production` | Groupon App |

## Steps

1. **Consume sync event**: Worker receives a place change event from the Groupon message bus for a supported source (Salesforce account, lead, or other configured source).
   - From: Groupon message bus (mbus)
   - To: `sf-m3-synchronizer-worker`
   - Protocol: mbus consumer

2. **Parse and validate event payload**: Worker extracts place record data from the event (source ID, external ID, name, address, phone, status, extended attributes).
   - From: `sf-m3-synchronizer-worker` (internal processing)
   - Protocol: local computation

3. **Map to M3 place model**: Worker translates the source record format into the M3 `InputPlace` model, applying source-specific field mappings.
   - From: `sf-m3-synchronizer-worker` (internal transformation)
   - Protocol: local computation

4. **Write place record**: Worker submits the translated place record as a create or update operation to Postgres (via place service write pipeline or directly).
   - From: `sf-m3-synchronizer-worker`
   - To: `continuumPlacesServicePostgres`
   - Protocol: TCP/PostgreSQL or HTTP to place write endpoint

5. **Update search index**: Following a successful place write, the OpenSearch index document is updated.
   - From: write pipeline / `sf-m3-synchronizer-worker`
   - To: `continuumPlacesServiceOpenSearch`
   - Protocol: HTTPS

6. **Acknowledge event**: Worker acknowledges the message bus event upon successful processing.
   - From: `sf-m3-synchronizer-worker`
   - To: Groupon message bus (mbus)
   - Protocol: mbus ack

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Event parse failure | Logged; message may be nacked or sent to DLQ (behavior in worker image) | Event not processed; monitoring alert |
| Place write failure | Logged; retry or DLQ behavior per worker image configuration | Place record not updated; event may be retried |
| OpenSearch index failure | Logged; place persisted in Postgres but not in search index | Search results may be stale until next index refresh |
| Worker pod failure | Kubernetes restarts pod (liveness probe: `pgrep java`) | Brief processing gap until pod restarts |

> Detailed error handling, retry, and DLQ configuration is managed within the `sf-m3-synchronizer` image repository, not in this codebase.

## Sequence Diagram

```
SalesforceSystem -> GrouponMbus: place_changed event (source=salesforce_account, externalId=xxx)
GrouponMbus -> sf-m3-synchronizer-worker: deliver event
sf-m3-synchronizer-worker -> sf-m3-synchronizer-worker: parse event payload
sf-m3-synchronizer-worker -> sf-m3-synchronizer-worker: map to M3 InputPlace model
sf-m3-synchronizer-worker -> continuumPlacesServicePostgres: INSERT/UPDATE place record
continuumPlacesServicePostgres --> sf-m3-synchronizer-worker: persisted
sf-m3-synchronizer-worker -> continuumPlacesServiceOpenSearch: upsert index document
continuumPlacesServiceOpenSearch --> sf-m3-synchronizer-worker: indexed
sf-m3-synchronizer-worker -> GrouponMbus: ack event
```

## Related

- Architecture dynamic view: `dynamic-place-read-flow`
- Related flows: [Place Write / Create](place-write.md)
