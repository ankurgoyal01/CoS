---
service: "janus-web-cloud"
title: "GDPR Report Generation Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "gdpr-report-generation"
flow_type: synchronous
trigger: "API call to POST /gdpr/ with a GDPR data subject request"
participants:
  - "jwc_apiResources"
  - "jwc_domainServices"
  - "jwc_integrationAdapters"
  - "jwc_mysqlDaos"
  - "janusOperationalSchema"
  - "bigtableRealtimeStore"
architecture_ref: "components-janus-web-cloud-component-view"
---

# GDPR Report Generation Flow

## Summary

The GDPR Report Generation flow handles data subject access or erasure report requests by querying Bigtable/HBase for all event records associated with the specified subject identifier. The service retrieves relevant event type metadata from MySQL to contextualise the raw Bigtable records, assembles a structured GDPR report, and returns it to the caller. This flow supports Groupon's GDPR compliance obligations by providing a complete audit trail of events associated with a data subject.

## Trigger

- **Type**: api-call
- **Source**: Internal compliance tooling or operator calling `POST /gdpr/` with a data subject identifier and report scope
- **Frequency**: On demand (per compliance request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Resources | Receives GDPR request; validates HTTP contract and routes to Domain Services | `jwc_apiResources` |
| Domain Services | Coordinates metadata lookup and report assembly; applies subject-scoping logic | `jwc_domainServices` |
| MySQL DAOs | Reads event type and attribute definitions to contextualise raw Bigtable records | `jwc_mysqlDaos` |
| Janus Operational Schema | Stores event definitions, attribute mappings, and context metadata used to annotate the report | `janusOperationalSchema` |
| Integration Adapters | Executes HBase/Bigtable queries for the subject's event records | `jwc_integrationAdapters` |
| Bigtable Realtime Store | Source of GDPR-relevant event records keyed by subject identifier | `bigtableRealtimeStore` |

## Steps

1. **Receive GDPR report request**: API Resources receives `POST /gdpr/` with a request body containing the data subject identifier (e.g., user ID or hashed identifier) and report scope (time range, event types).
   - From: External caller (compliance tooling)
   - To: `jwc_apiResources`
   - Protocol: REST / HTTP

2. **Validate request parameters**: API Resources validates required fields and routes to Domain Services.
   - From: `jwc_apiResources`
   - To: `jwc_domainServices`
   - Protocol: Direct (in-process)

3. **Load event metadata from MySQL**: Domain Services instructs MySQL DAOs to load the relevant event type definitions, attribute schemas, and context mappings needed to annotate the Bigtable records.
   - From: `jwc_domainServices`
   - To: `jwc_mysqlDaos` -> `janusOperationalSchema`
   - Protocol: Direct / JDBC

4. **Query Bigtable for subject events**: Domain Services instructs Integration Adapters to execute a HBase scan or get on the Bigtable realtime store, scoped to the data subject identifier and optional time range.
   - From: `jwc_domainServices` -> `jwc_integrationAdapters`
   - To: `bigtableRealtimeStore`
   - Protocol: HBase API (hbase-client 2.2.3 + bigtable-hbase 1.26.3)

5. **Assemble GDPR report**: Domain Services joins the raw Bigtable event records with the MySQL event type metadata to produce a structured, human-readable GDPR report containing event names, attribute values, timestamps, and context labels.
   - From: `jwc_domainServices`
   - To: in-process assembly
   - Protocol: Direct

6. **Return report response**: API Resources serialises the assembled report to JSON and returns `200 OK` to the caller.
   - From: `jwc_apiResources`
   - To: External caller
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing subject identifier | Validation failure in API Resources | `400 Bad Request` with error message |
| Bigtable connectivity failure | Exception from Integration Adapters propagated | `503 Service Unavailable` or `500 Internal Server Error`; error logged to `loggingStack` |
| No events found for subject | Bigtable scan returns empty result | `200 OK` with empty events list in report |
| MySQL metadata load failure | JDBI exception propagated | `500 Internal Server Error`; report cannot be contextualised |
| GCP credentials expired | HBase client authentication failure | `500 Internal Server Error`; credentials rotation required |

## Sequence Diagram

```
Compliance tooling -> jwc_apiResources: POST /gdpr/ (subjectId, timeRange, eventTypes)
jwc_apiResources -> jwc_domainServices: Validate and initiate GDPR report
jwc_domainServices -> jwc_mysqlDaos: Load event type definitions and attribute schemas
jwc_mysqlDaos -> janusOperationalSchema: SELECT event_types, attributes, contexts
janusOperationalSchema --> jwc_mysqlDaos: Metadata rows
jwc_mysqlDaos --> jwc_domainServices: Event metadata
jwc_domainServices -> jwc_integrationAdapters: Query Bigtable for subject events
jwc_integrationAdapters -> bigtableRealtimeStore: HBase scan (subjectId, timeRange)
bigtableRealtimeStore --> jwc_integrationAdapters: Raw event records
jwc_integrationAdapters --> jwc_domainServices: Event record list
jwc_domainServices -> jwc_domainServices: Assemble GDPR report (join event records + metadata)
jwc_domainServices --> jwc_apiResources: Structured report
jwc_apiResources --> Compliance tooling: 200 OK (GDPR report JSON)
```

## Related

- Architecture dynamic view: `components-janus-web-cloud-component-view`
- Related flows: [Metadata Management](metadata-management.md) (event and attribute definitions used to contextualise GDPR report)
- See [API Surface](../api-surface.md) for `/gdpr/*` endpoint details
- See [Integrations](../integrations.md) for Bigtable/HBase dependency details
- See [Data Stores](../data-stores.md) for `bigtableRealtimeStore` access patterns
