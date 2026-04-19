---
service: "gazebo"
title: "Salesforce Data Sync"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "salesforce-data-sync"
flow_type: scheduled
trigger: "Cron job executes on a configured schedule"
participants:
  - "continuumGazeboCron"
  - "continuumGazeboMysql"
  - "salesForce"
architecture_ref: "dynamic-gazebo-salesforce-data-sync"
---

# Salesforce Data Sync

## Summary

A scheduled cron job running in the `continuumGazeboCron` container periodically queries Salesforce CRM using the Restforce Ruby SDK to retrieve up-to-date opportunity and deal data. The fetched records are compared against Gazebo's local MySQL store and updated records are written, keeping the editorial team's view of CRM data current without requiring manual intervention.

## Trigger

- **Type**: schedule
- **Source**: `continuumGazeboCron` container running a Rake task on a configured cron interval
- **Frequency**: Periodic schedule (exact interval not specified in inventory; daily or sub-daily interval expected)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Gazebo Cron | Initiates and orchestrates the sync job | `continuumGazeboCron` |
| Salesforce CRM | Source of truth for opportunity and deal CRM data | `salesForce` |
| Gazebo MySQL | Target store receiving the synced CRM data | `continuumGazeboMysql` |

## Steps

1. **Cron job triggered**: The cron scheduler in `continuumGazeboCron` fires the Salesforce sync Rake task at the configured interval.
   - From: `continuumGazeboCron` (scheduler)
   - To: `continuumGazeboCron` (Rake task)
   - Protocol: direct

2. **Restforce client authenticates**: The Restforce gem authenticates with Salesforce using the configured `SALESFORCE_CLIENT_ID` and `SALESFORCE_CLIENT_SECRET` OAuth credentials.
   - From: `continuumGazeboCron`
   - To: `salesForce`
   - Protocol: Restforce SDK (HTTPS / OAuth 2.0)

3. **Opportunity and deal records queried**: Restforce executes SOQL queries against Salesforce to retrieve updated opportunity and deal records since the last sync.
   - From: `continuumGazeboCron`
   - To: `salesForce`
   - Protocol: Restforce SDK (SOQL over HTTPS)

4. **Salesforce returns record set**: Salesforce responds with the matching records payload (opportunities, deal fields, contact references).
   - From: `salesForce`
   - To: `continuumGazeboCron`
   - Protocol: Restforce SDK (HTTPS)

5. **Records mapped to local schema**: The Rake task maps the Salesforce record fields to Gazebo's MySQL schema (deals, tasks, and related entities).
   - From: `continuumGazeboCron` (mapper)
   - To: `continuumGazeboCron` (mapper)
   - Protocol: direct

6. **MySQL records updated**: The cron job writes the mapped data to MySQL, performing upsert operations on the `deals` table and related tables.
   - From: `continuumGazeboCron`
   - To: `continuumGazeboMysql`
   - Protocol: MySQL

7. **Sync job completes**: The Rake task logs completion status (success or partial failure) and the scheduler marks the job done until the next interval.
   - From: `continuumGazeboCron`
   - To: `continuumGazeboCron` (logger)
   - Protocol: direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce authentication failure (expired credentials) | Restforce raises OAuth error; job logs error and exits | Sync does not run; stale data remains in MySQL until credentials are fixed and job re-runs |
| Salesforce API rate limit exceeded | Restforce raises API limit error | Sync pauses or fails for this run; retried at next scheduled interval |
| Salesforce API timeout | Typhoeus/Restforce timeout exception raised | Job logs error and exits; partial records may have been written; next run will catch remaining |
| MySQL write failure | ActiveRecord exception raised; transaction rolled back for affected batch | Partial sync; affected records remain stale; next run will retry |
| Salesforce service unavailable | Restforce connection error | Sync fails entirely; stale MySQL data remains until service recovers |

## Sequence Diagram

```
continuumGazeboCron -> continuumGazeboCron: cron schedule fires Rake task
continuumGazeboCron -> salesForce: authenticate (OAuth via Restforce)
salesForce --> continuumGazeboCron: access token
continuumGazeboCron -> salesForce: SOQL query (opportunities, deals, updated_since)
salesForce --> continuumGazeboCron: CRM records payload
continuumGazeboCron -> continuumGazeboCron: map Salesforce fields to MySQL schema
continuumGazeboCron -> continuumGazeboMysql: upsert deals + related records
continuumGazeboMysql --> continuumGazeboCron: write confirmation
continuumGazeboCron -> continuumGazeboCron: log sync completion
```

## Related

- Architecture dynamic view: `dynamic-gazebo-salesforce-data-sync`
- Related flows: [Message Bus Event Processing](message-bus-event-processing.md), [Editorial Copy Creation](editorial-copy-creation.md)
