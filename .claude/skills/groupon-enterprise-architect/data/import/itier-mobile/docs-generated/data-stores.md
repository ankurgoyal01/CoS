---
service: "itier-mobile"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

`itier-mobile` is a stateless service. It does not own or directly manage any databases, caches, or persistent storage. All state relevant to request handling — user-agent, cookies, query parameters, country codes — is derived from the inbound HTTP request. Static data (app association files, localization bundles, campaign download links) is embedded in the application code and distributed as part of the Docker image. Log output is shipped via Filebeat to Kafka and on to the ELK stack, but that pipeline is infrastructure-managed, not owned by this service.

## Stores

> This service is stateless and does not own any data stores.

## Caches

> No evidence found in codebase. Asset files served by this service (e.g., `/apple-app-site-association`) are cached at the Akamai CDN layer via `Cache-Control` response headers, but no application-level cache store is managed by the service itself.

## Data Flows

> Not applicable. The service reads from inbound HTTP requests and writes to HTTP responses or outbound Twilio API calls. No ETL, CDC, or replication pipelines are present.
