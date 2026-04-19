---
service: "tronicon-ui"
title: "Bootstrap Config Sync"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "bootstrap-config-sync"
flow_type: synchronous
trigger: "Application startup — Gunicorn worker process initialization"
participants:
  - "troniconUiWeb"
  - "bootstrapService"
  - "troniconUi_integrationClients"
  - "gconfigService"
  - "continuumTroniconUiDatabase"
architecture_ref: "dynamic-troniconUi-bootstrap-config-sync"
---

# Bootstrap Config Sync

## Summary

This flow describes how Tronicon UI loads and synchronizes its initial configuration when the application starts. On startup, the Bootstrap & Config Loader component reads environment variables from the `.env` file, loads card property configuration from `gconfig/cardatron.json`, and optionally fetches remote configuration values from the Gconfig Service (`gconfigService`). The resulting merged configuration is made available in-process for all web controllers and integration clients. This flow runs once per Gunicorn worker process initialization and is not triggered by operator actions.

## Trigger

- **Type**: application startup (Gunicorn worker process initialization)
- **Source**: Gunicorn starts a new worker process — either on initial deploy, after a restart, or when a worker is recycled
- **Frequency**: Once per worker process startup; not on-demand per request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Gunicorn Worker | Initializes the WSGI application, triggering bootstrap | `troniconUiWeb` |
| Bootstrap & Config Loader | Orchestrates config loading from all sources | `bootstrapService` |
| Integration Clients | Initialized with service URLs and credentials from loaded config | `troniconUi_integrationClients` |
| Tronicon UI Database | Connection pool established using loaded DB credentials | `continuumTroniconUiDatabase` |
| Gconfig Service | Provides remote configuration values (stub integration) | `gconfigService` |

## Steps

1. **Gunicorn starts worker process**: Gunicorn initializes a new WSGI application worker, triggering the web.py application startup sequence.
   - From: `Gunicorn`
   - To: `troniconUiWeb`
   - Protocol: WSGI process startup

2. **Loads .env file**: Bootstrap & Config Loader uses python-dotenv to read the `.env` file and populate environment variables into the process environment.
   - From: `bootstrapService`
   - To: `.env file` (local filesystem)
   - Protocol: direct (file read)

3. **Loads cardatron.json config**: Bootstrap & Config Loader reads `gconfig/cardatron.json` to load card property schema and field definitions used by the Cardatron card management system.
   - From: `bootstrapService`
   - To: `gconfig/cardatron.json` (local filesystem)
   - Protocol: direct (file read)

4. **Fetches remote config from Gconfig Service**: Bootstrap & Config Loader calls `gconfigService` to retrieve any remote configuration overrides. If the service is unavailable, local defaults are used.
   - From: `troniconUi_integrationClients`
   - To: `gconfigService`
   - Protocol: REST/HTTP

5. **Receives remote config values**: Gconfig Service returns key-value configuration overrides; Bootstrap & Config Loader merges these with the locally loaded config, with remote values taking precedence.
   - From: `gconfigService`
   - To: `bootstrapService`
   - Protocol: REST/HTTP

6. **Initializes database connection pool**: Bootstrap & Config Loader passes the loaded `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` environment variables to SQLAlchemy to establish the connection pool to `continuumTroniconUiDatabase`.
   - From: `bootstrapService`
   - To: `continuumTroniconUiDatabase`
   - Protocol: SQL over TCP (connection pool initialization)

7. **Initializes integration clients**: Bootstrap & Config Loader provides loaded service URLs and credentials to the Integration Clients component, initializing HTTP client configurations for Campaign Service, Alligator, Groupon API, Taxonomy Service, and others.
   - From: `bootstrapService`
   - To: `troniconUi_integrationClients`
   - Protocol: direct (in-process)

8. **Serves /config.json**: Once bootstrap completes, the `GET /config.json` endpoint becomes available to return the active configuration to the frontend JavaScript application.
   - From: `troniconUiWeb`
   - To: `Operator browser`
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `.env` file missing or unreadable | python-dotenv raises error or silently skips | Required env vars absent; application may fail to start or run with missing config |
| `gconfig/cardatron.json` missing | File read raises IOError | Cardatron card property schema unavailable; card management features may fail |
| Gconfig Service unavailable at startup | HTTP error caught; local defaults used | Remote config overrides not applied; service starts with local-only configuration |
| Database connection pool fails to initialize | SQLAlchemy raises OperationalError | Application cannot serve database-backed requests; Gunicorn worker may fail to start |

## Sequence Diagram

```
Gunicorn -> troniconUiWeb: Initialize WSGI worker
troniconUiWeb -> bootstrapService: Start bootstrap sequence
bootstrapService -> .env: Read environment variables
.env --> bootstrapService: Env vars loaded
bootstrapService -> gconfig/cardatron.json: Read card property schema
gconfig/cardatron.json --> bootstrapService: Card config loaded
bootstrapService -> gconfigService: GET /config (remote overrides)
gconfigService --> bootstrapService: Remote config values (or timeout/error)
bootstrapService -> bootstrapService: Merge local + remote config
bootstrapService -> continuumTroniconUiDatabase: Initialize connection pool
continuumTroniconUiDatabase --> bootstrapService: Pool ready
bootstrapService -> troniconUi_integrationClients: Initialize with service URLs + credentials
troniconUi_integrationClients --> bootstrapService: Clients ready
bootstrapService --> troniconUiWeb: Bootstrap complete

Operator -> troniconUiWeb: GET /config.json
troniconUiWeb --> Operator: Active config JSON
```

## Related

- Architecture dynamic view: `dynamic-troniconUi-bootstrap-config-sync`
- Related flows: [Theme Configuration](theme-configuration.md)
- See [Configuration](../configuration.md) for environment variable definitions and config file paths
- See [Integrations](../integrations.md) for Gconfig Service (`gconfigService`) details
