---
service: "JLA_Airflow"
title: "DB Gatekeeper — Governed SQL Execution"
generated: "2026-03-03"
type: flow
flow_name: "db-gatekeeper"
flow_type: batch
trigger: "Manual — triggered by an FSA engineer via Airflow UI with `script_list` configuration"
participants:
  - "continuumJlaAirflowOrchestrator"
  - "continuumJlaAirflowMetadataDb"
  - "teradata-dwh_fsa_prd"
  - "jira-api"
  - "github-raw"
  - "googleChat"
architecture_ref: "dynamic-continuumJlaAirflow"
---

# DB Gatekeeper — Governed SQL Execution

## Summary

DB Gatekeeper (`db-gatekeeper`) is the FSA team's governed interface for executing SQL scripts against FSA databases. An engineer triggers the DAG manually via the Airflow UI, providing a list of raw GitHub URLs pointing to SQL files. The DAG enforces naming conventions (filename must match `[TICKET_PREFIX]-NNNN_short_description.sql`), verifies the Jira ticket in the filename is valid, fetches and parses the scripts, executes them against Teradata (in order), logs every query execution for audit, and posts a completion summary. It supports an optional DDL diff mode that compares the to-be-executed scripts against the current database object definitions without executing.

## Trigger

- **Type**: manual
- **Source**: FSA engineer via Airflow UI "Trigger w/ config" providing `script_list` parameter
- **Frequency**: On-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| DAG Execution Engine | Runs the Gatekeeper DAG on manual trigger | `continuumJlaAirflowOrchestrator` |
| Data Warehouse Connector | Executes validated SQL against Teradata | `continuumJlaAirflowOrchestrator` |
| Airflow Metadata Store | Stores process UUID, validated script list via XCom | `continuumJlaAirflowMetadataDb` |
| Teradata (`dwh_fsa_prd`) | Target database for script execution; audit log store | `unknown_teradata_platform` (stub) |
| Jira API | Validates that the Jira ticket embedded in each filename exists | External (connection: `jira_api`) |
| GitHub (raw) | Source of SQL scripts (`raw.github.groupondev.com`) | External |
| Google Chat | Receives failure alerts | `googleChat` |

## Steps

1. **Start DAG**: `dag_start` empty operator marks DAG start.

2. **Branch — DDL Diff or Execute**: `BranchPythonOperator` checks `params['show_DDL_diff']`. If `True`, routes to `get_diff`; otherwise routes to `get_process_uuid`.
   - From: `continuumJlaAirflowOrchestrator`

3. **[Diff path] Get DDL diff**: Fetches each script from GitHub, extracts DDL object names using regex (`CREATE|REPLACE|ALTER` + `PROCEDURE|TABLE|VIEW|FUNCTION`), executes `SHOW {kind} {object}` against Teradata, and prints a line-by-line diff comparison. No changes are made to the database. Ends DAG.
   - From: `continuumJlaAirflowOrchestrator`
   - To: GitHub (raw URL fetch), `teradata-dwh_fsa_prd` (SHOW statements)
   - Protocol: HTTPS (fetch), JDBC/SQL (SHOW)

4. **Generate process UUID**: Creates a UUID `process_id` and pushes to XCom.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `continuumJlaAirflowMetadataDb` (XCom)
   - Protocol: Airflow XCom

5. **Create process log**: Inserts run record via `ProcessLog.create()` into `acct_jla_run_process`.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd`
   - Protocol: JDBC/SQL

6. **Pre-validate scripts**: For each URL in `script_list`:
   - Verifies the URL is from `raw.github.groupondev.com`
   - Verifies the branch is `main` in production
   - Validates the filename matches `^[A-Z]+[-]\d{2,7}[_]\w+[\.]sql`
   - Calls the Jira API (`/rest/api/2/issue/{ticket}`) to verify the ticket exists
   - Fetches the script content; checks no single line exceeds 3000 bytes
   - Validates the `database` folder in the URL matches a supported connection name
   - Pushes the validated list to XCom
   - From: `continuumJlaAirflowOrchestrator`
   - To: Jira API (HTTP), GitHub (raw URL fetch)
   - Protocol: HTTPS

7. **Execute scripts**: For each validated script:
   - Creates a Gatekeeper log entry in `meta_db_gatekeeper_log`
   - Parses SQL with `sqlparse` (or passes full script for procedures)
   - Applies `Env.replace()` substitutions for environment-specific schema names
   - Executes each statement against Teradata; creates a `meta_db_gatekeeper_log_query` entry per statement
   - On failure, updates the query log with the error message and raises `AirflowFailException`
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd`
   - Protocol: JDBC/SQL

8. **Update process log**: Marks process as successful via `ProcessLog.success()`.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd`
   - Protocol: JDBC/SQL

9. **Post status summary**: Queries `meta_db_gatekeeper_log` and `meta_db_gatekeeper_log_query` to produce a summary of all files processed, query counts, start/end times, and durations. Prints to Airflow task logs.
   - From: `continuumJlaAirflowOrchestrator`
   - To: `teradata-dwh_fsa_prd`
   - Protocol: JDBC/SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| URL not from `raw.github.groupondev.com` | Pre-validation raises `AirflowFailException` | DAG fails; no SQL executed |
| Branch is not `main` in production | Pre-validation raises `AirflowFailException` | DAG fails; no SQL executed |
| Filename violates naming convention | Pre-validation raises `AirflowFailException` | DAG fails; no SQL executed |
| Jira ticket does not exist | Pre-validation raises `AirflowFailException` | DAG fails; no SQL executed |
| Line > 3000 bytes in script | Pre-validation raises `AirflowFailException` | DAG fails; no SQL executed |
| SQL execution error | Logs failure to `meta_db_gatekeeper_log_query`; raises `AirflowFailException` | DAG fails; `on_failure_callback` sends Google Chat alert; partial execution logged |

## Sequence Diagram

```
FSA Engineer -> Airflow UI: trigger db-gatekeeper with {script_list: [...]}
db-gatekeeper -> GitHub (raw): fetch each SQL script
db-gatekeeper -> Jira API: GET /rest/api/2/issue/{ticket}
db-gatekeeper -> teradata (dwh_fsa_prd): INSERT meta_db_gatekeeper_log
db-gatekeeper -> teradata (dwh_fsa_prd): execute SQL statements (in order)
db-gatekeeper -> teradata (dwh_fsa_prd): INSERT/UPDATE meta_db_gatekeeper_log_query (per statement)
db-gatekeeper -> teradata (dwh_fsa_prd): post_status query
```

## Related

- Architecture dynamic view: `dynamic-continuumJlaAirflow`
- Related flows: [DB Watchman — Database Monitoring](db-watchman.md)
- Jira: FINS-738
