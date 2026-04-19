---
service: "jtier-oxygen"
title: "Greeting CRUD"
generated: "2026-03-03"
type: flow
flow_name: "greeting-crud"
flow_type: synchronous
trigger: "API call — POST /greetings or GET /greetings/{name}"
participants:
  - "oxygenHttpApi"
  - "oxygenDataAccess"
  - "continuumOxygenPostgres"
architecture_ref: "dynamic-oxygen-runtime-flow"
---

# Greeting CRUD

## Summary

The greeting CRUD flow exercises JTier's DaaS (Postgres) building block via JDBI3. A caller posts a key-value pair (name + greeting text) which is persisted to Postgres. A subsequent GET request retrieves the greeting by name. This flow validates the full path from HTTP request through the JDBI DAO layer to the managed Postgres connection pool and back.

## Trigger

- **Type**: API call
- **Source**: HTTP client (JTier engineer, `oxy-broadcast` CLI, or automated test)
- **Frequency**: On-demand (per-request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| HTTP Resources | Receives and validates greeting request; returns response | `oxygenHttpApi` |
| Persistence Adapters | Executes JDBI SQL for greeting read/write | `oxygenDataAccess` |
| Oxygen Postgres | Stores greeting key-value data | `continuumOxygenPostgres` |

## Steps

### Write Path

1. **Receive greeting write request**: Caller sends `POST /greetings` with JSON body `{"key": "name", "value": "greeting text"}`.
   - From: `HTTP client`
   - To: `oxygenHttpApi`
   - Protocol: REST (HTTP)

2. **Delegate to data access layer**: HTTP Resources passes the `KeyValue` model to the Persistence Adapters.
   - From: `oxygenHttpApi`
   - To: `oxygenDataAccess`
   - Protocol: Direct (in-process)

3. **Persist greeting**: Persistence Adapters executes an upsert SQL statement via JDBI3 DAO to store the key-value pair.
   - From: `oxygenDataAccess`
   - To: `continuumOxygenPostgres`
   - Protocol: JDBC (DaaS-managed pool)

4. **Return response**: Postgres acknowledges the write; response propagates back to the caller.
   - From: `continuumOxygenPostgres` → `oxygenDataAccess` → `oxygenHttpApi`
   - To: `HTTP client`
   - Protocol: JDBC → Direct → REST

### Read Path

1. **Receive greeting read request**: Caller sends `GET /greetings/{name}`.
   - From: `HTTP client`
   - To: `oxygenHttpApi`
   - Protocol: REST (HTTP)

2. **Delegate lookup**: HTTP Resources passes the name key to Persistence Adapters.
   - From: `oxygenHttpApi`
   - To: `oxygenDataAccess`
   - Protocol: Direct (in-process)

3. **Query Postgres**: Persistence Adapters executes a SELECT query via JDBI3 DAO.
   - From: `oxygenDataAccess`
   - To: `continuumOxygenPostgres`
   - Protocol: JDBC (DaaS-managed pool)

4. **Return greeting**: Postgres returns the row; the `KeyValue` model is serialized to JSON and returned with `200 OK`.
   - From: `continuumOxygenPostgres` → `oxygenDataAccess` → `oxygenHttpApi`
   - To: `HTTP client`
   - Protocol: JDBC → Direct → REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Postgres unavailable | Connection pool throws exception | `500 Internal Server Error` returned to caller |
| Key not found on GET | DAO returns empty result | `200 OK` with null/empty value, or `404` depending on DAO implementation |

## Sequence Diagram

```
Client -> oxygenHttpApi: POST /greetings {key, value}
oxygenHttpApi -> oxygenDataAccess: save(KeyValue)
oxygenDataAccess -> continuumOxygenPostgres: SQL UPSERT greetings
continuumOxygenPostgres --> oxygenDataAccess: OK
oxygenDataAccess --> oxygenHttpApi: success
oxygenHttpApi --> Client: 200 OK

Client -> oxygenHttpApi: GET /greetings/{name}
oxygenHttpApi -> oxygenDataAccess: findByKey(name)
oxygenDataAccess -> continuumOxygenPostgres: SQL SELECT greetings WHERE key = name
continuumOxygenPostgres --> oxygenDataAccess: KeyValue row
oxygenDataAccess --> oxygenHttpApi: KeyValue
oxygenHttpApi --> Client: 200 OK {key, value}
```

## Related

- Architecture dynamic view: `dynamic-oxygen-runtime-flow`
- Related flows: [Broadcast Lifecycle](broadcast-lifecycle.md)
- API surface: [Greetings endpoints](../api-surface.md)
- Data store: [Oxygen Postgres](../data-stores.md)
