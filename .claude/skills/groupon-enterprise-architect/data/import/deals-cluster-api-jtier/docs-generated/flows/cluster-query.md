---
service: "deals-cluster-api-jtier"
title: "Cluster Query"
generated: "2026-03-03"
type: flow
flow_name: "cluster-query"
flow_type: synchronous
trigger: "GET /clusters or GET /clusters/{id} API call"
participants:
  - "continuumDealsClusterApi"
  - "continuumDealsClusterDatabase"
architecture_ref: "components-deals-cluster-api-components"
---

# Cluster Query

## Summary

A consumer (navigation surface, marketing tool, or Spark Job) calls `GET /clusters` or `GET /clusters/{id}` to retrieve deal cluster data. The Deals Cluster Resource delegates to the Deals Cluster DAO Service, which queries the PostgreSQL database via JDBI, and returns the matching cluster records with deal UUIDs and statistical data.

## Trigger

- **Type**: api-call
- **Source**: Any authorized HTTP client calling `GET /clusters` or `GET /clusters/{id}`
- **Frequency**: on-demand (per-request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| HTTP client | Initiates the query with filter parameters | — |
| Deals Cluster Resource | Receives the HTTP request, validates parameters | `continuumDealsClusterApi` |
| Deals Cluster DAO Service | Applies business logic for cluster lookup | `continuumDealsClusterApi` |
| Deals Cluster DAO | Executes JDBI query against PostgreSQL | `continuumDealsClusterApi` |
| Deals Cluster Postgres | Stores and returns cluster data | `continuumDealsClusterDatabase` |

## Steps

1. **Receives cluster query request**: HTTP client sends `GET /clusters` with optional filter parameters (`country`, `ruleName`, `ruleId`, `deal`, `channel`, `category`, `division_id`, `city`, `clusterUuid`, `limit`, `offset`).
   - From: HTTP client
   - To: `dealsClusterResource` (Deals Cluster Resource)
   - Protocol: REST/HTTP

2. **Delegates to business logic**: Deals Cluster Resource passes the validated filter parameters to the Deals Cluster DAO Service.
   - From: `dealsClusterResource`
   - To: `dealsClusterDaoService`
   - Protocol: direct (in-process)

3. **Constructs and executes database query**: Deals Cluster DAO Service calls the Deals Cluster DAO to build and execute a JDBI query against `continuumDealsClusterDatabase`, applying all filter conditions.
   - From: `dealsClusterDaoService`
   - To: `dealsClusterDao` -> `continuumDealsClusterDatabase`
   - Protocol: JDBC/PostgreSQL

4. **Returns cluster records**: PostgreSQL returns the matching cluster rows. The DAO maps results to cluster objects including `uuid`, `clusterName`, `dealsCount`, `dealDataFrom`, `updatedAt`, `clusterDefinition`, and the list of deal UUIDs.
   - From: `continuumDealsClusterDatabase`
   - To: `dealsClusterDaoService` -> `dealsClusterResource`
   - Protocol: JDBC

5. **Returns JSON response**: Deals Cluster Resource serializes the cluster list to JSON and returns a 200 OK response.
   - From: `dealsClusterResource`
   - To: HTTP client
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid filter parameter | JAX-RS validation returns 400 Bad Request | Client receives error response |
| Cluster UUID not found (`GET /clusters/{id}`) | DAO returns no result; resource returns 404 | Client receives 404 Not Found |
| Database connection failure | JDBI propagates exception; Dropwizard returns 500 | Client receives 500 Internal Server Error; alert triggers on Wavefront |

## Sequence Diagram

```
Client -> DealsClusterResource: GET /clusters?country=NL&ruleName=COUNTRY
DealsClusterResource -> DealsClusterDaoService: findClusters(filters)
DealsClusterDaoService -> DealsClusterDao: query(filterConditions)
DealsClusterDao -> ContinuumDealsClusterDatabase: SELECT * FROM clusters WHERE ...
ContinuumDealsClusterDatabase --> DealsClusterDao: cluster rows
DealsClusterDao --> DealsClusterDaoService: List<Cluster>
DealsClusterDaoService --> DealsClusterResource: List<Cluster>
DealsClusterResource --> Client: 200 OK [{"uuid": "...", "clusterName": "...", ...}]
```

## Related

- Architecture dynamic view: `components-deals-cluster-api-components`
- Related flows: [Rule Management](rule-management.md), [Spark Job Rule Fetch and Cluster Write](spark-job-cluster-write.md)
