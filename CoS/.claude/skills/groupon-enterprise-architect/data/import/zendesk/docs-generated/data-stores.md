---
service: "zendesk"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "zendesk-saas-storage"
    type: "SaaS-managed"
    purpose: "Ticket and case data managed by Zendesk SaaS"
---

# Data Stores

## Overview

Zendesk is a fully managed SaaS platform. All ticket, case, and agent data is stored and managed within Zendesk's hosted infrastructure. Groupon does not own or operate any of the underlying data stores. There is no database, cache, or persistent store owned or managed by Groupon as part of this service. Data access is entirely via the Zendesk REST API.

## Stores

> No evidence found in codebase of Groupon-owned data stores. All data persistence is external to Groupon and managed by Zendesk SaaS.

This service is stateless from Groupon's infrastructure perspective and does not own any data stores. Ticket and case data is persisted within Zendesk's managed environment.

## Caches

> No evidence found in codebase. No Groupon-owned caches are configured for this service.

## Data Flows

Support data flows into Zendesk via the `zendeskApi` integration component when Groupon services submit or update tickets. Zendesk synchronizes relevant support and CRM information outbound to Salesforce (`salesForce`). The direction of data movement is:

- Groupon internal services → `zendeskApi` → `zendeskTicketing` (ticket creation and updates)
- `continuumZendesk` → `salesForce` (CRM synchronization of support records)
