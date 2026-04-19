---
service: "partner-service"
title: "Partner Uptime and Metrics Reporting"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "partner-uptime-and-metrics-reporting"
flow_type: scheduled
trigger: "Quartz scheduled job fires on configured interval"
participants:
  - "continuumPartnerService"
  - "continuumPartnerServicePostgres"
  - "messageBus"
architecture_ref: "dynamic-partner-uptime-and-metrics-reporting"
---

# Partner Uptime and Metrics Reporting

## Summary

The partner uptime and metrics reporting flow is a scheduled batch process that collects uptime signals and operational metrics for all active partners, aggregates them against records in `continuumPartnerServicePostgres`, and publishes the resulting metrics events to MBus for downstream consumption by monitoring and reporting systems. The flow also exposes uptime data via the `/partner-service/v1/auditlog` and uptime-specific API endpoints.

## Trigger

- **Type**: schedule
- **Source**: Quartz job managed by `partnerSvc_mbusAndScheduler`
- **Frequency**: Scheduled interval (specific cron expression managed in service configuration); uptime data is also queryable on-demand via API

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Partner Service | Batch collector and aggregator; reads partner records and uptime signals; publishes metrics | `continuumPartnerService` |
| Partner Service Postgres | Source of partner records and historical uptime state | `continuumPartnerServicePostgres` |
| MBus | Receives published partner metrics and uptime events for downstream consumption | `messageBus` |

## Steps

1. **Quartz job fires**: Scheduled uptime collection job triggers the metrics reporting use case.
   - From: `partnerSvc_mbusAndScheduler`
   - To: `partnerSvc_domainServices`
   - Protocol: direct

2. **Loads active partner records**: Reads the list of active partners requiring uptime evaluation.
   - From: `partnerSvc_domainServices`
   - To: `continuumPartnerServicePostgres`
   - Protocol: JDBC

3. **Reads uptime and operational state**: Retrieves current uptime signals and operational state for each active partner.
   - From: `partnerSvc_domainServices`
   - To: `continuumPartnerServicePostgres`
   - Protocol: JDBC

4. **Aggregates metrics**: Computes uptime percentages, error rates, and operational health metrics per partner.
   - From: `partnerSvc_domainServices`
   - To: `partnerSvc_domainServices`
   - Protocol: direct (in-process aggregation)

5. **Writes updated uptime records**: Persists the latest uptime measurements and aggregated metrics back to the database.
   - From: `partnerSvc_domainServices`
   - To: `continuumPartnerServicePostgres`
   - Protocol: JDBC

6. **Publishes metrics events**: Emits partner uptime and metrics events to MBus for consumption by monitoring and reporting systems.
   - From: `partnerSvc_mbusAndScheduler`
   - To: `messageBus`
   - Protocol: JMS/STOMP

7. **Writes audit log entry**: Records the metrics reporting run in the audit log.
   - From: `partnerSvc_domainServices`
   - To: `continuumPartnerServicePostgres`
   - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Database read failure | Job aborts; scheduled retry on next interval | Metrics collection deferred |
| MBus publish failure | Event publish failure logged; metrics stored locally; retry on next run | Downstream consumers receive delayed metrics |
| Partial partner processing failure | Successfully processed partners committed; failed partners retried next run | Partial metrics report published |
| Aggregation error for single partner | Error logged and partner skipped; remaining partners processed | Incomplete metrics report for that interval |

## Sequence Diagram

```
partnerSvc_mbusAndScheduler -> partnerSvc_domainServices: Trigger uptime metrics job
partnerSvc_domainServices -> continuumPartnerServicePostgres: Load active partner records
continuumPartnerServicePostgres --> partnerSvc_domainServices: Partner list
partnerSvc_domainServices -> continuumPartnerServicePostgres: Read uptime/operational state per partner
continuumPartnerServicePostgres --> partnerSvc_domainServices: Uptime state records
partnerSvc_domainServices -> partnerSvc_domainServices: Aggregate metrics per partner
partnerSvc_domainServices -> continuumPartnerServicePostgres: Write updated uptime records
partnerSvc_domainServices -> continuumPartnerServicePostgres: Write audit log entry
partnerSvc_mbusAndScheduler -> messageBus: Publish partner metrics events
```

## Related

- Architecture dynamic view: `dynamic-partner-uptime-and-metrics-reporting`
- Related flows: [Partner Onboarding Workflow](partner-onboarding-workflow.md), [Deal Mapping Reconciliation](deal-mapping-reconciliation.md)
