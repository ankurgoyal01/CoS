---
service: "salesforce-cache"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Salesforce Cache uses the Groupon Messagebus (`mbus-client` version 1.4.0) as part of its replication worker pipeline. The `salesforceCacheReplicationWorker` produces events or notifications after persisting Salesforce record updates. Event production is handled by the `salesforceUpdatePersister` component, which also triggers the `quantumLeadUpdater` for lead-related changes. The API component does not publish or consume async events.

## Published Events

> No evidence found of specific named topic configurations in the open repository inventory. The `mbus-client` dependency is present in `pom.xml` (version 1.4.0) and event production is architecturally documented as part of the Cacher pipeline, but specific topic names are not exposed in the publicly inventoried configuration files.

The Replication Worker (`salesforceCacheReplicationWorker`) publishes metrics events to the metrics pipeline via Telegraf after each replication batch completes.

## Consumed Events

> No evidence found of the Salesforce Cache service consuming async events from any message bus topic. Data ingestion is poll-based (Quartz-scheduled Salesforce API calls), not event-driven.

## Dead Letter Queues

> No evidence found in codebase.

## Downstream Notifications

Although not a formal event bus interaction, the `Salesforce Update Persister` component sends HTTP-based lead update notifications to the Quantum Lead system (`quantumLeadSystem`) as a synchronous side effect of each replication batch. This is documented in the architecture DSL as a direct HTTP relationship rather than an async event.
