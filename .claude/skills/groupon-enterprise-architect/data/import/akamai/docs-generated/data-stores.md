---
service: "akamai"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. The akamai repository contains only YAML configuration metadata and architecture DSL definitions. All persistent state — WAF rule sets, bot management policies, and security analytics — is maintained by Akamai as a SaaS vendor within their own platform (`https://control.akamai.com`). Groupon's Cyber Security team manages this state through the Akamai Security Center UI and API, not through any Groupon-owned data store.

## Stores

> Not applicable — no Groupon-owned data stores are used.

## Caches

> Not applicable — no caches are used by this service.

## Data Flows

> Not applicable — there are no data flows between Groupon-managed stores for this service. Security analytics data resides in Akamai's cloud platform and is accessed directly via the Akamai Security Center dashboards referenced in `akamaiSecurityDashboards`.
