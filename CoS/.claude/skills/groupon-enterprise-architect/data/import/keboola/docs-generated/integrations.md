---
service: "keboola"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 0
---

# Integrations

## Overview

Keboola Connection integrates with three external systems: Salesforce as a data source, BigQuery as an analytics destination, and Google Chat for operational alerting. All integrations are outbound from `continuumKeboolaConnectionService`. There are no internal Groupon service dependencies; Keboola operates as a standalone integration runtime.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | HTTPS/API | Extracts CRM and merchant datasets for pipeline processing | yes | `salesForce` |
| BigQuery | HTTPS/Batch Load | Writes transformed datasets for analytics consumption | yes | `bigQuery` |
| Google Chat | Webhook | Sends operational alerts and support notifications for pipeline run status | no | `googleChat` |

### Salesforce Detail

- **Protocol**: HTTPS/API
- **Base URL / SDK**: Salesforce REST API (configuration managed within Keboola connector settings)
- **Auth**: Configured within the Keboola Salesforce extraction connector; credentials managed by Keboola platform secrets
- **Purpose**: Extracts CRM records and merchant datasets as the primary source for Groupon's data integration pipelines
- **Failure mode**: Extraction runs fail and the `kbcOpsNotifier` emits a failure alert to Google Chat; no data is written to BigQuery for that run
- **Circuit breaker**: Managed by the Keboola platform; Groupon-level circuit breaker configuration is not applicable

### BigQuery Detail

- **Protocol**: HTTPS/Batch Load
- **Base URL / SDK**: Google BigQuery API (configuration managed within Keboola destination writer settings)
- **Auth**: Configured within the Keboola BigQuery destination writer; GCP service account credentials managed by Keboola platform
- **Purpose**: Destination warehouse for all transformed datasets produced by Keboola ETL pipelines, consumed by Groupon analytics teams
- **Failure mode**: Load stage fails and the `kbcOpsNotifier` emits a failure alert to Google Chat; previously extracted and transformed data remains in Keboola staging
- **Circuit breaker**: Managed by the Keboola platform

### Google Chat Detail

- **Protocol**: Webhook (outbound HTTP POST)
- **Base URL / SDK**: Google Chat incoming webhook URL (managed in Keboola Ops Notifier configuration; GChat space ID `AAAArqovlCY` referenced in `.service.yml`)
- **Auth**: Webhook URL contains embedded auth token managed by Google Chat
- **Purpose**: Receives operational run status notifications, failure alerts, and escalation messages from the `kbcOpsNotifier` component
- **Failure mode**: Notification delivery failure is non-critical; pipeline execution continues regardless
- **Circuit breaker**: Not applicable

## Internal Dependencies

> Not applicable. Keboola Connection does not call any other Groupon-internal services. It operates as a standalone integration runtime connected only to external systems.

## Consumed By

> Upstream consumers are tracked in the central architecture model. Groupon data engineering and analytics teams consume the BigQuery datasets produced by Keboola pipelines; they do not call Keboola directly.

## Dependency Health

Health checks for external dependencies are managed within the Keboola platform. Pipeline run failures trigger immediate Google Chat notifications via the `kbcOpsNotifier`. Groupon does not have direct access to dependency health dashboards; operational issues are reported through Keboola's in-platform support system (see [Runbook](runbook.md)).
