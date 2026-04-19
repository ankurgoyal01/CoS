---
service: "ckod-backend-jtier"
title: "Cost Alert Query"
generated: "2026-03-03"
type: flow
flow_name: "cost-alert-query"
flow_type: synchronous
trigger: "HTTP call to /costAlert/* endpoints"
participants:
  - "continuumCkodBackendJtier"
  - "continuumCkodMySql"
architecture_ref: "dynamic-ckod-deployment-tracking-flow"
---

# Cost Alert Query

## Summary

CKOD provides a family of cost alert endpoints that allow consumers to manage alert configurations, query KBC telemetry data, retrieve BigQuery workspace cost figures, and look up service-to-alert mappings. All data originates from MySQL tables populated by external ETL processes. The CKOD API exposes read and write operations over these tables via `CostAlertService`, which delegates to `CostAlertReadDao` and `CostAlertWriteDao`.

## Trigger

- **Type**: api-call
- **Source**: CKOD UI, on-call automation, or data engineer calls one of the `/costAlert/*` REST endpoints
- **Frequency**: On-demand (per consumer request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CKOD API Resource (`CostAlertResource`) | Receives requests and delegates to service layer | `continuumCkodBackendJtier` |
| CKOD Domain Service (`CostAlertService`) | Applies business logic, delegates to DAOs | `continuumCkodBackendJtier` |
| CKOD Persistence (`CostAlertReadDao`, `CostAlertWriteDao`) | Executes MySQL queries and mutations | `continuumCkodBackendJtier` |
| CKOD MySQL | Stores cost alert configs, telemetry, and BQ cost data | `continuumCkodMySql` |

## Steps

### Read flow (e.g., `GET /costAlert/{date}`)

1. **Receive query request**: `CostAlertResource` receives the request with path/query parameters (date, IDs, project ID, etc.).
   - From: Caller
   - To: `continuumCkodApiResources`
   - Protocol: REST

2. **Delegate to service**: `CostAlertResource` invokes the appropriate `CostAlertService` method.
   - From: `continuumCkodApiResources`
   - To: `continuumCkodDomainServices`
   - Protocol: Direct (in-process)

3. **Query MySQL**: `CostAlertReadDao` runs a Hibernate/JPA query against the appropriate entity (`CostAlertEntity`, `KbcTelemetryEntity`, `KbcWsCostEntity`, `CostAlertConfigEntity`, or `ServiceAlertConfigEntity`).
   - From: `continuumCkodPersistenceDaos`
   - To: `continuumCkodMySql`
   - Protocol: JDBC/MySQL

4. **Map and return**: Results are mapped to model objects and serialised as JSON.
   - From: `continuumCkodApiResources`
   - To: Caller
   - Protocol: REST/JSON

### Write flow (e.g., `POST /costAlert/createAlertConfig`)

1. **Receive mutation request**: `CostAlertResource` receives request parameters (`alert_name`, `check_lookback`, `baseline_lookback`, `threshold`).
   - From: Caller
   - To: `continuumCkodApiResources`
   - Protocol: REST

2. **Delegate to service**: `CostAlertResource` invokes `CostAlertService.createAlertConfig()`.
   - From: `continuumCkodApiResources`
   - To: `continuumCkodDomainServices`
   - Protocol: Direct (in-process)

3. **Persist to MySQL**: `CostAlertWriteDao` writes a new `CostAlertConfigEntity` or `ServiceAlertConfigEntity` row.
   - From: `continuumCkodPersistenceDaos`
   - To: `continuumCkodMySql`
   - Protocol: JDBC/MySQL

4. **Return confirmation**: Result (new entity or confirmation) serialised as JSON response.
   - From: `continuumCkodApiResources`
   - To: Caller
   - Protocol: REST/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Record not found | Returns empty list or null in payload | Caller receives empty response |
| MySQL query failure | Exception propagated to Dropwizard error handler | HTTP 500 returned to caller |
| Invalid query parameters | No explicit validation layer found; Dropwizard default handling applies | HTTP 4xx returned |

## Sequence Diagram

```
Caller -> CostAlertResource: GET /costAlert/{date}
CostAlertResource -> CostAlertService: getCostAlertData(date)
CostAlertService -> CostAlertReadDao: query CostAlertEntity by date
CostAlertReadDao -> continuumCkodMySql: SELECT * FROM cost_alert WHERE date=?
continuumCkodMySql --> CostAlertReadDao: CostAlertEntity[]
CostAlertReadDao --> CostAlertService: model list
CostAlertService --> CostAlertResource: model list
CostAlertResource --> Caller: JSON response
```

## Related

- Architecture dynamic view: `dynamic-ckod-deployment-tracking-flow`
- Related flows: [Keboola Job Polling](keboola-job-polling.md)
- See also: [Data Stores](../data-stores.md) for entity and table details
