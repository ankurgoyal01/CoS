---
service: "lavatoryRunner"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

Lavatory Runner is stateless. It owns no persistent data stores, databases, or caches. All data it reads originates from the Artifactory REST API (via AQL queries at execution time), and all deletions are applied directly to Artifactory. The service itself maintains no local state between runs. Log output is written to host-level log files under `/var/log/lavatory/` and forwarded to Splunk — these are treated as operational logs, not a data store owned by this service.

## Stores

> Not applicable. This service is stateless and does not own any data stores.

## Caches

> Not applicable. No caching layer is used.

## Data Flows

- At execution start, the `artifactoryClient` component queries Artifactory via AQL to retrieve artifact metadata (path, name, updated timestamp, download statistics).
- The `retentionEvaluator` component processes the in-memory result sets in Python to compute purge candidates.
- Purge operations are issued back to Artifactory REST API as DELETE requests.
- No data is persisted locally by the service between runs.
- Logs are written to `/var/log/lavatory/<repo-name>.log` on the host, from which Splunk ingests them as `sourcetype=lavatory`.
