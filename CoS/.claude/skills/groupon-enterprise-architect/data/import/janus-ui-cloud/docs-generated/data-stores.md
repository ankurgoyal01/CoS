---
service: "janus-ui-cloud"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

Janus UI Cloud is stateless and does not own any data stores. All persistent data — including schema definitions, attribute mappings, canonical events, destinations, subscribers, UDFs, alerts, and user records — is owned and stored by the `continuumJanusWebCloudService` (Janus metadata service). The UI retrieves and mutates this data exclusively via the proxied `/api/*` endpoint.

The only client-side state is held in the Redux store in memory within the browser session. No local storage persistence has been detected (the `redux-localstorage` and `redux-localstorage-filter` packages appear in devDependencies only, indicating they were used in development experiments but are not part of the production bundle).

## Stores

> This service is stateless and does not own any data stores.

## Caches

> Not applicable. No server-side caching is configured.

## Data Flows

All data flows pass through the `continuumJanusUiCloudGateway` proxy to the `continuumJanusWebCloudService`. The UI reads data on page load and module navigation; it writes data when users submit create/edit forms. See [Integrations](integrations.md) for dependency details and [Flows](flows/index.md) for end-to-end flow documentation.
