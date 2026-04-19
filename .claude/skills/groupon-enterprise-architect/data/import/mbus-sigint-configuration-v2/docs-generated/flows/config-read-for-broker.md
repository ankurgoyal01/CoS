---
service: "mbus-sigint-configuration-v2"
title: "Configuration Read for Broker"
generated: "2026-03-03"
type: flow
flow_name: "config-read-for-broker"
flow_type: synchronous
trigger: "HTTP GET /config/deployment/{clusterId}/{environmentType}"
participants:
  - "continuumMbusSigintConfigurationService"
  - "continuumMbusSigintConfigurationDatabase"
architecture_ref: "components-continuum-mbus-sigint-configuration-service"
---

# Configuration Read for Broker

## Summary

Artemis broker instances and the `mbusible` operator tool read the current active MBus configuration for a cluster and environment via the `/config/deployment/{clusterId}/{environmentType}` endpoint. The service assembles a deployment-ready JSON payload containing queues, topics, user credentials, role assignments, access permissions, and divert settings — all derived from the configuration entries in the `IN_PROD` or `IN_TEST` status for the target environment. This endpoint is the primary integration point between the config service and the broker infrastructure.

## Trigger

- **Type**: api-call
- **Source**: Artemis broker infrastructure or `mbusible` tooling
- **Frequency**: On demand (typically at broker startup or on configuration refresh)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Resources | Receives and routes the GET request | `mbsc_apiResources` |
| Domain Services | Assembles deployment configuration from persisted entities | `mbsc_domainServices` |
| Persistence Adapters | Queries all configuration entities for the cluster and environment | `mbsc_persistenceAdapters` |
| MBus Sigint Configuration Database | Source of truth for active configuration | `continuumMbusSigintConfigurationDatabase` |
| Artemis Broker / mbusible | Consumer of deployment configuration | External caller |

## Steps

1. **Receive GET request**: Broker or tooling calls `GET /config/deployment/{clusterId}/{environmentType}` with a `full-config-reader` or `admin` role header (`x-grpn-username`).
   - From: Artemis broker or `mbusible`
   - To: `mbsc_apiResources`
   - Protocol: REST/HTTP

2. **Authorize caller**: JTier auth bundle validates the `x-grpn-username` header against the `full-config-reader` or `admin` role list.
   - From: `mbsc_apiResources`
   - To: JTier auth bundle (in-process)
   - Protocol: Direct

3. **Query active destinations**: Persistence adapters fetch all destinations (queues/topics) for the cluster that are active in the specified environment (`IN_PROD` or `IN_TEST`).
   - From: `mbsc_domainServices`
   - To: `mbsc_persistenceAdapters` -> `continuumMbusSigintConfigurationDatabase`
   - Protocol: JDBC

4. **Query user credentials**: Persistence adapters fetch all `user_credential` entries for the cluster and environment type.
   - From: `mbsc_domainServices`
   - To: `mbsc_persistenceAdapters` -> `continuumMbusSigintConfigurationDatabase`
   - Protocol: JDBC

5. **Query access permissions**: Persistence adapters fetch all `access_permission` entries mapping roles to destinations (PRODUCER/CONSUMER) for the environment.
   - From: `mbsc_domainServices`
   - To: `mbsc_persistenceAdapters` -> `continuumMbusSigintConfigurationDatabase`
   - Protocol: JDBC

6. **Query diverts**: Persistence adapters fetch all active divert rules (from/to address pairs) for the cluster.
   - From: `mbsc_domainServices`
   - To: `mbsc_persistenceAdapters` -> `continuumMbusSigintConfigurationDatabase`
   - Protocol: JDBC

7. **Query redelivery settings**: Persistence adapters fetch `redelivery_setting` entries for the environment's destinations (max delivery attempts, delays, DLQ flags).
   - From: `mbsc_domainServices`
   - To: `mbsc_persistenceAdapters` -> `continuumMbusSigintConfigurationDatabase`
   - Protocol: JDBC

8. **Assemble DeploymentConfiguration response**: Domain services build the `DeploymentConfiguration` JSON object containing `queue_list`, `topic_list`, `user_credentials`, `roles`, `address_permissions`, and `diverts`.
   - From: `mbsc_domainServices`
   - To: `mbsc_apiResources`
   - Protocol: Direct

9. **Return JSON response**: API resource serializes and returns the `DeploymentConfiguration` JSON with HTTP 200.
   - From: `mbsc_apiResources`
   - To: Artemis broker / `mbusible`
   - Protocol: REST/HTTP (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unknown cluster ID | Persistence adapter returns empty result set | HTTP 200 with empty configuration arrays or HTTP 404 (behavior follows Dropwizard default) |
| Unauthorized caller | JTier auth filter rejects request | HTTP 401/403 |
| PostgreSQL unavailable | JDBC connection fails | HTTP 500; broker must retry or fall back to last known config |

## Sequence Diagram

```
Broker/mbusible  -> mbsc_apiResources       : GET /config/deployment/{clusterId}/{envType}
mbsc_apiResources -> AuthBundle             : validate x-grpn-username role
AuthBundle       --> mbsc_apiResources      : authorized
mbsc_apiResources -> mbsc_domainServices    : assemble deployment config
mbsc_domainServices -> mbsc_persistenceAdapters : query destinations (IN_PROD/IN_TEST)
mbsc_domainServices -> mbsc_persistenceAdapters : query user_credentials
mbsc_domainServices -> mbsc_persistenceAdapters : query access_permissions
mbsc_domainServices -> mbsc_persistenceAdapters : query diverts
mbsc_domainServices -> mbsc_persistenceAdapters : query redelivery_settings
mbsc_persistenceAdapters -> DB             : JDBC queries
DB               --> mbsc_persistenceAdapters : result rows
mbsc_domainServices --> mbsc_apiResources   : DeploymentConfiguration DTO
mbsc_apiResources --> Broker/mbusible       : HTTP 200 JSON (queue_list, topic_list, roles, ...)
```

## Related

- Architecture dynamic view: `components-continuum-mbus-sigint-configuration-service`
- Related flows: [Change Request Lifecycle](change-request-lifecycle.md), [Scheduled Configuration Deployment](scheduled-config-deployment.md)
