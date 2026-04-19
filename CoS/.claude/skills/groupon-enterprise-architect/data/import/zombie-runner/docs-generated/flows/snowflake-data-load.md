---
service: "zombie-runner"
title: "Snowflake Data Load"
generated: "2026-03-03"
type: flow
flow_name: "snowflake-data-load"
flow_type: batch
trigger: "Task node scheduled by zrTaskOrchestrator when upstream extraction tasks complete"
participants:
  - "zrTaskOrchestrator"
  - "zrOperatorAdapters"
  - "cloudPlatform"
  - "snowflake"
  - "hdfsStorage"
architecture_ref: "dynamic-zombie-runner-workflow-execution"
---

# Snowflake Data Load

## Summary

The Snowflake Data Load flow describes the two-phase process Zombie Runner uses to load data into Snowflake tables. In phase one, source data (from local disk or HDFS) is staged to an AWS S3 bucket that acts as a Snowflake external stage — either directly via `boto3` for local data, or via an EMR streaming step for large HDFS-backed data sets. In phase two, the `SnowflakeWorker` renders a `snowflake-load.tpl` Mako template into a multi-statement SQL sequence and executes COPY INTO against the Snowflake warehouse via ODBC. The S3 staging prefix is cleaned up before each load and again on failure.

## Trigger

- **Type**: schedule (within workflow DAG)
- **Source**: `zrTaskOrchestrator` schedules the Snowflake load task after upstream HiveTask or DataTask nodes complete successfully
- **Frequency**: Once per workflow execution; may be triggered with different `date` context values for backfills

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Task Orchestrator | Schedules and dispatches the Snowflake load task | `zrTaskOrchestrator` |
| Operator Adapters (SnowflakeWorker) | Manages S3 staging, EMR step submission, template rendering, and Snowflake COPY INTO | `zrOperatorAdapters` |
| Cloud Platform (AWS S3 + EMR) | Hosts the S3 external stage bucket; runs EMR streaming jobs for HDFS-to-S3 copy | `cloudPlatform` |
| Snowflake | Target data warehouse; executes COPY INTO from the S3 external stage | `snowflake` |
| HDFS Storage | Source of large data sets that require EMR-based staging | `hdfsStorage` |

## Steps

1. **Initialize SnowflakeWorker**: Task operator reads configuration — `snowflake_stage_loc` (S3 bucket), `snf_ext_stage_name`, `emr_cluster_name`, `delimiter`, `file_type`, `server_side_encryption`, `dest_table`, `schema` — from the YAML task definition.
   - From: `zrOperatorAdapters`
   - To: in-process initialization
   - Protocol: direct

2. **Clean existing S3 prefix**: Before staging, checks whether the target S3 prefix (`load_<dest_table>/<workflow_id>`) already exists. If it does, submits an EMR step to recursively delete it.
   - From: `zrOperatorAdapters` (`EMROperations.clean_s3_prefix`)
   - To: `cloudPlatform` (AWS EMR `add_job_flow_steps`)
   - Protocol: AWS SDK (boto3)

3. **Stage data to S3** (path A — local source): If source data is on local disk, uploads all files in the source path to `s3://<snowflake_stage_loc>/<s3_prefix>/` using `boto3.upload_file` with server-side encryption.
   - From: `zrOperatorAdapters` (`S3Operations.load_local_to_s3`)
   - To: `cloudPlatform` (AWS S3)
   - Protocol: AWS SDK (boto3)

4. **Stage data to S3** (path B — HDFS source): If source data is on HDFS, submits an EMR streaming Hadoop job that reads from HDFS using `-text <hdfs_path>` and writes to `s3a://<s3_prefix>/` with Gzip compression. Polls for step completion.
   - From: `zrOperatorAdapters` (`EMROperations.s3_load_data_emr_step`)
   - To: `hdfsStorage` (source) and `cloudPlatform` (AWS EMR + S3 destination)
   - Protocol: AWS SDK (boto3) for EMR; Hadoop streaming jar for data movement

5. **Render Snowflake load SQL**: Uses the Mako template `snowflake-load.tpl` to generate a sequence of SQL statements: create file format, optional TRUNCATE TABLE, COPY INTO with field delimiter and format options, drop file format.
   - From: `zrOperatorAdapters` (`SnowflakeWorker.data_load_template`)
   - To: in-process Mako renderer
   - Protocol: direct

6. **Execute COPY INTO**: Executes the rendered SQL statements against Snowflake via the ODBC DSN; the COPY INTO command reads from the S3 external stage (`snf_ext_stage_name`) and loads into `<schema>.<dest_table>`.
   - From: `zrOperatorAdapters`
   - To: `snowflake`
   - Protocol: ODBC (`pyodbc` / Snowflake ODBC driver)

7. **Handle load failure cleanup**: If the COPY INTO fails, cleans up the S3 prefix via an EMR step and re-raises the exception.
   - From: `zrOperatorAdapters`
   - To: `cloudPlatform` (AWS EMR + S3)
   - Protocol: AWS SDK (boto3)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| S3 prefix exists before load | Pre-load `clean_s3_prefix()` EMR step removes it | Load proceeds with clean prefix; idempotent |
| Local file path not found | `OSError` raised in `load_local_to_s3` | Task fails; check source path in workflow context |
| EMR step fails or cancelled | Exception raised; `clean_s3_prefix()` called to remove partial data | Task fails; orchestrator retries |
| EMR step poll timeout (300 attempts × 10s = 50 min) | Exception raised: "Max attempts exceeded" | Task fails; investigate EMR cluster state |
| Snowflake COPY INTO error | Exception raised from ODBC layer | Task fails; `clean_s3_prefix()` called; orchestrator retries |
| S3 server-side encryption mismatch | S3 `upload_file` raises `ClientError` | Task fails; verify `server_side_encryption` config matches bucket policy |

## Sequence Diagram

```
zrTaskOrchestrator -> zrOperatorAdapters: execute(SnowflakeTask, context)
zrOperatorAdapters -> cloudPlatform: EMR step: aws s3 rm --recursive s3://<prefix> (clean)
cloudPlatform --> zrOperatorAdapters: step COMPLETED
alt local source
  zrOperatorAdapters -> cloudPlatform: boto3.upload_file(local_files -> s3://<prefix>/)
  cloudPlatform --> zrOperatorAdapters: upload complete
else HDFS source
  zrOperatorAdapters -> cloudPlatform: EMR step: hadoop-streaming (hdfs -> s3a://<prefix>)
  cloudPlatform -> hdfsStorage: hadoop fs -text <source_path>
  hdfsStorage --> cloudPlatform: data stream
  cloudPlatform --> zrOperatorAdapters: step COMPLETED
end
zrOperatorAdapters -> zrOperatorAdapters: render snowflake-load.tpl (SQL statements)
zrOperatorAdapters -> snowflake: COPY INTO <schema>.<table> FROM @<ext_stage>/<prefix>
snowflake --> zrOperatorAdapters: rows loaded
zrOperatorAdapters --> zrTaskOrchestrator: output_context
```

## Related

- Architecture dynamic view: `dynamic-zombie-runner-workflow-execution`
- Related flows: [Workflow Execution](workflow-execution.md), [Hive ETL Task](hive-etl-task.md)
