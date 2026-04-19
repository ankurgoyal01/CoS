---
service: "mds"
title: "Feed Generation"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "feed-generation"
flow_type: batch
trigger: "Scheduled cron job or API-triggered request"
participants:
  - "continuumMarketingDealService"
  - "continuumMarketingDealDb"
  - "continuumMarketingPlatform"
architecture_ref: "dynamic-mds-feed-generation"
---

# Feed Generation

## Summary

The feed generation flow produces structured data feeds of enriched deal information for distribution to partner channels, advertising systems, and the Marketing Platform. The Feed Generator component reads enriched deal data from PostgreSQL, applies partner-specific formatting and filtering rules, and exports the generated feeds. This flow runs on a scheduled basis (typically daily or more frequently) and can also be triggered on-demand via the MDS API. Generated feeds are served to the Marketing Platform and partner integration endpoints.

## Trigger

- **Type**: schedule / api-call
- **Source**: Cron schedule (`FEED_GENERATION_SCHEDULE`) or POST to `/feeds/generate` API endpoint
- **Frequency**: Scheduled (typically daily); on-demand as needed

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Controller | Receives on-demand feed generation requests | `mds_api` |
| Feed Generator | Reads deal data, applies formatting, produces feeds | `mds_feedGenerator` |
| Marketing Deal Service Database | Source of enriched deal data | `continuumMarketingDealDb` |
| Marketing Platform | Receives generated feed data | `continuumMarketingPlatform` |

## Steps

1. **Initiate feed generation**: Either the scheduled cron job fires or a client sends POST to `/feeds/generate`. The API Controller delegates to the Feed Generator.
   - From: Scheduler / API Client
   - To: `mds_api` -> `mds_feedGenerator`
   - Protocol: in-process / REST

2. **Query enriched deal data**: Feed Generator reads enriched deal records from PostgreSQL, filtering by active status, division, and deal type as required by feed specifications.
   - From: `mds_feedGenerator`
   - To: `continuumMarketingDealDb`
   - Protocol: JDBC

3. **Apply partner formatting rules**: Feed Generator transforms deal data into partner-specific formats (XML, JSON, CSV, etc.), applying field mappings, value transformations, and filtering rules per feed specification.
   - From: `mds_feedGenerator`
   - To: internal (in-process transformation)
   - Protocol: in-process

4. **Generate feed output**: Feed Generator produces the final feed files or payloads, including metadata such as generation timestamp, deal count, and feed version.
   - From: `mds_feedGenerator`
   - To: internal (in-process)
   - Protocol: in-process

5. **Publish to Marketing Platform**: Generated feed data is published to the Marketing Platform for consumption by advertising, SEM, and partner distribution systems.
   - From: `mds_feedGenerator`
   - To: `continuumMarketingPlatform`
   - Protocol: HTTP + Events

6. **Update feed status**: Feed generation status is recorded, making it queryable via the `/feeds/status` API endpoint.
   - From: `mds_feedGenerator`
   - To: `continuumMarketingDealDb`
   - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| PostgreSQL read failure | Feed generation aborted; error logged | Feed not generated; previous feed remains current. Alert fires on generation failure. |
| Transformation error (malformed deal data) | Affected deals skipped; logged individually | Partial feed generated with skipped deals logged for investigation |
| Marketing Platform unavailable | Feed generation completes locally; delivery retried | Feed data available via API; Marketing Platform receives on reconnect |
| Feed generation exceeds time window | Alert fires; generation continues to completion | Downstream consumers receive delayed feed update |

## Sequence Diagram

```
Scheduler/Client -> mds_api: POST /feeds/generate (or cron trigger)
mds_api -> mds_feedGenerator: generateFeeds()
mds_feedGenerator -> continuumMarketingDealDb: SELECT enriched deals (filtered)
continuumMarketingDealDb --> mds_feedGenerator: deal dataset
mds_feedGenerator -> mds_feedGenerator: apply formatting rules
mds_feedGenerator -> mds_feedGenerator: produce feed output
mds_feedGenerator -> continuumMarketingPlatform: POST feed data
continuumMarketingPlatform --> mds_feedGenerator: 200 OK
mds_feedGenerator -> continuumMarketingDealDb: UPDATE feed_status
mds_feedGenerator --> mds_api: generation complete
mds_api --> Scheduler/Client: 200 OK {status: completed}
```

## Related

- Architecture dynamic view: `dynamic-mds-feed-generation`
- Related flows: [Deal Enrichment Pipeline](deal-enrichment-pipeline.md), [Deal Event Consumption](deal-event-consumption.md)
