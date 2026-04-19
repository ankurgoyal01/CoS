---
service: "deals-cluster-api-jtier"
title: "Rule Management"
generated: "2026-03-03"
type: flow
flow_name: "rule-management"
flow_type: synchronous
trigger: "POST /rules, DELETE /rules/{id}, GET /rules, or GET /rules/{id} API call"
participants:
  - "continuumDealsClusterApi"
  - "continuumDealsClusterDatabase"
architecture_ref: "components-deals-cluster-api-components"
---

# Rule Management

## Summary

Operators and automated systems manage cluster rule definitions through the Rules API. Rules define how the Deals Cluster Spark Job groups deals (e.g., by country, division, category). The Rules Resource provides CRUD operations backed by the Deals Cluster Rules DAO, persisting all rule configurations to PostgreSQL. The same pattern applies to top cluster rules via the `/topclustersrules` endpoints.

## Trigger

- **Type**: api-call
- **Source**: Operator or automated tooling calling `GET /rules`, `GET /rules/{id}`, `POST /rules`, or `DELETE /rules/{id}`
- **Frequency**: on-demand (infrequent; rule changes are configuration events)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator / tooling | Initiates rule create, read, update, or delete | — |
| Rules Resource | Receives HTTP request, validates rule payload | `continuumDealsClusterApi` |
| Deals Cluster Rules Service | Applies business logic for rule management | `continuumDealsClusterApi` |
| Deals Cluster Rules DAO | Executes JDBI read/write against PostgreSQL | `continuumDealsClusterApi` |
| Deals Cluster Postgres | Persists rule definitions | `continuumDealsClusterDatabase` |

## Steps

### Create / Update Rule (POST /rules)

1. **Receives rule payload**: Operator sends `POST /rules` with a JSON rule object containing `name`, `filters`, `customFields`, `groupBy`, `outputData`, and `clusterFilters`.
   - From: Operator
   - To: `rulesResource`
   - Protocol: REST/HTTP

2. **Delegates to rules service**: Rules Resource passes the rule object to the Deals Cluster Rules Service for validation and persistence.
   - From: `rulesResource`
   - To: `dealsClusterRulesService`
   - Protocol: direct (in-process)

3. **Persists rule to database**: Deals Cluster Rules Service calls the Deals Cluster Rules DAO to insert or update the rule record in `continuumDealsClusterDatabase`.
   - From: `dealsClusterRulesService`
   - To: `dealsClusterRulesDao` -> `continuumDealsClusterDatabase`
   - Protocol: JDBC/PostgreSQL

4. **Returns created/updated rule**: Rule record (with `id`, `createdAt`, `updatedAt`) is returned to the caller.
   - From: `rulesResource`
   - To: Operator
   - Protocol: REST/HTTP (200 OK with rule object)

### Delete Rule (DELETE /rules/{id})

1. **Receives delete request**: Operator sends `DELETE /rules/{id}`.
   - From: Operator
   - To: `rulesResource`
   - Protocol: REST/HTTP

2. **Deletes rule record**: Rules Resource -> Deals Cluster Rules Service -> Deals Cluster Rules DAO executes DELETE against `continuumDealsClusterDatabase`.
   - From: `dealsClusterRulesService`
   - To: `dealsClusterRulesDao` -> `continuumDealsClusterDatabase`
   - Protocol: JDBC/PostgreSQL

3. **Returns 204 No Content**: Successful deletion returns HTTP 204.
   - From: `rulesResource`
   - To: Operator
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Rule not found on DELETE | DAO returns no rows affected; resource returns 404 | Client receives 404 Not Found |
| Invalid rule payload on POST | JAX-RS validation returns 400 Bad Request | Client receives error details |
| Database write failure | JDBI exception propagated; Dropwizard returns 500 | Client receives 500 Internal Server Error |

## Sequence Diagram

```
Operator -> RulesResource: POST /rules {name, filters, groupBy, ...}
RulesResource -> DealsClusterRulesService: createOrUpdateRule(rule)
DealsClusterRulesService -> DealsClusterRulesDao: upsert(rule)
DealsClusterRulesDao -> ContinuumDealsClusterDatabase: INSERT/UPDATE rules
ContinuumDealsClusterDatabase --> DealsClusterRulesDao: saved rule record
DealsClusterRulesDao --> DealsClusterRulesService: Rule
DealsClusterRulesService --> RulesResource: Rule
RulesResource --> Operator: 200 OK {id, name, createdAt, updatedAt, ...}
```

## Related

- Architecture dynamic view: `components-deals-cluster-api-components`
- Related flows: [Cluster Query](cluster-query.md), [Spark Job Rule Fetch and Cluster Write](spark-job-cluster-write.md)
