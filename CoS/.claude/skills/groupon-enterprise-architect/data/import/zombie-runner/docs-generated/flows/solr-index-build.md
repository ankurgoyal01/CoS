---
service: "zombie-runner"
title: "Solr Index Build"
generated: "2026-03-03"
type: flow
flow_name: "solr-index-build"
flow_type: batch
trigger: "Task nodes scheduled by zrTaskOrchestrator as part of a search index refresh workflow"
participants:
  - "zrTaskOrchestrator"
  - "zrOperatorAdapters"
  - "solrCluster"
architecture_ref: "dynamic-zombie-runner-workflow-execution"
---

# Solr Index Build

## Summary

The Solr Index Build flow describes how Zombie Runner refreshes Solr search indexes using a blue/green core swap pattern. A typical Solr pipeline in Zombie Runner consists of four sequential tasks: generate schema, create a new staging core, load data from a CSV file in batches via the Solr JSON update endpoint, then swap the staging core into production and reload both cores. The `SolrTask` operators in `solr_task.py` manage all interactions with the Solr Admin HTTP API.

## Trigger

- **Type**: schedule (within workflow DAG)
- **Source**: `zrTaskOrchestrator` schedules Solr task nodes after upstream data extraction and transformation tasks complete
- **Frequency**: Typically nightly or weekly, as part of search index refresh pipelines

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Task Orchestrator | Schedules Solr task nodes in dependency order | `zrTaskOrchestrator` |
| Operator Adapters (SolrTask) | Generates schema XML; calls Solr Admin API; loads data via JSON update endpoint | `zrOperatorAdapters` |
| Solr Cluster | Hosts Solr cores; processes Admin API requests; indexes documents | `solrCluster` |

## Steps

1. **Generate Solr schema XML** (`SolrGenSchemaTask`): Reads the `schema` key from the task YAML (a list of field definitions with name, type, indexed, stored, multiValued attributes); renders them into a Solr `schema.xml` file at `schema_file_location`.
   - From: `zrOperatorAdapters`
   - To: filesystem (schema XML file write)
   - Protocol: direct

2. **Create staging Solr core** (`SolrCreateCoreTask`): Calls `GET http://<solr_host>:<solr_port>/solr/admin/cores?action=CREATE&name=<core_name>&instanceDir=<dir>&dataDir=<data_dir>&config=solrconfig.xml&schema=schema.xml&persist=true`. Assumes schema and config files are already deployed at the Solr instance directory.
   - From: `zrOperatorAdapters`
   - To: `solrCluster`
   - Protocol: HTTP GET (Solr Admin API)

3. **Delete existing staging data** (optional, `SolrDeleteCoreDataTask`): Calls `POST http://<solr_host>:<solr_port>/solr/<core_name>/update/json?commit=true` with body `{"delete":{"query":"*:*"}}` to clear any existing documents from the core before loading fresh data.
   - From: `zrOperatorAdapters`
   - To: `solrCluster`
   - Protocol: HTTP POST (Solr Update API)

4. **Load CSV data into core** (`SolrLoadFromFileTask`): Reads the source CSV file at `data_file_location` in batches of `batch_size` (default: 1000 rows) using `csv.DictReader`; serializes each batch to JSON; POSTs to `/solr/<core_name>/update/json?commit=true`. Records the total number of inserted documents via `_statput("num_solr_records_inserted_<core>", num_recs)`.
   - From: `zrOperatorAdapters`
   - To: `solrCluster`
   - Protocol: HTTP POST (Solr Update API, JSON)

5. **Swap cores** (`SolrCoreSwapTask`): Calls `GET /solr/admin/cores?action=SWAP&core=<staging_core>&other=<production_core>` to atomically swap the staging and production core names; then RELOADs both cores.
   - From: `zrOperatorAdapters`
   - To: `solrCluster`
   - Protocol: HTTP GET (Solr Admin API)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Solr Admin API returns non-200 | `RuntimeError` raised: "error response code returned: [N]" | Task fails; orchestrator retries |
| Solr Update API returns non-2XX | `RuntimeError` raised | Batch load fails; partial data may be indexed; orchestrator retries from start |
| Schema file write failure | OS exception raised | Task fails; check `schema_file_location` path permissions |
| Core already exists on CREATE | Solr returns error (core name collision) | Task fails; use `SolrDeleteCoreDataTask` or manually delete the core before re-run |
| Core swap fails | Solr returns error | Production core is unchanged; staging core remains; orchestrator retries |

## Sequence Diagram

```
zrTaskOrchestrator -> zrOperatorAdapters: execute(SolrGenSchemaTask, context)
zrOperatorAdapters -> filesystem: write schema.xml
zrTaskOrchestrator -> zrOperatorAdapters: execute(SolrCreateCoreTask, context)
zrOperatorAdapters -> solrCluster: GET /solr/admin/cores?action=CREATE&name=<staging_core>
solrCluster --> zrOperatorAdapters: 200 OK
zrTaskOrchestrator -> zrOperatorAdapters: execute(SolrLoadFromFileTask, context)
loop [batch_size rows at a time]
  zrOperatorAdapters -> solrCluster: POST /solr/<staging_core>/update/json?commit=true [JSON batch]
  solrCluster --> zrOperatorAdapters: 2XX OK
end
zrTaskOrchestrator -> zrOperatorAdapters: execute(SolrCoreSwapTask, context)
zrOperatorAdapters -> solrCluster: GET /solr/admin/cores?action=SWAP&core=<staging>&other=<prod>
solrCluster --> zrOperatorAdapters: 200 OK
zrOperatorAdapters -> solrCluster: GET /solr/admin/cores?action=RELOAD&core=<staging>
zrOperatorAdapters -> solrCluster: GET /solr/admin/cores?action=RELOAD&core=<prod>
solrCluster --> zrOperatorAdapters: 200 OK (both reloads)
zrOperatorAdapters --> zrTaskOrchestrator: output_context
```

## Related

- Architecture dynamic view: `dynamic-zombie-runner-workflow-execution`
- Related flows: [Workflow Execution](workflow-execution.md)
