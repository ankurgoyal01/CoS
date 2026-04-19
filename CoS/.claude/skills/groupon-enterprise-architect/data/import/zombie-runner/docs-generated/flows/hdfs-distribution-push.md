---
service: "zombie-runner"
title: "HDFS Distribution Push"
generated: "2026-03-03"
type: flow
flow_name: "hdfs-distribution-push"
flow_type: batch
trigger: "Task node scheduled by zrTaskOrchestrator as part of a cross-cluster data distribution workflow"
participants:
  - "zrTaskOrchestrator"
  - "zrOperatorAdapters"
  - "hdfsStorage"
  - "continuumZombieRunnerExternalTargets"
architecture_ref: "dynamic-zombie-runner-workflow-execution"
---

# HDFS Distribution Push

## Summary

The HDFS Distribution Push flow describes how Zombie Runner copies files between HDFS clusters using a WebHDFS REST-based approach. The `DistPushTask` operator (via `dist_push.py`) implements a Hadoop streaming reducer that reads tab-delimited records of (filepath, target_host, filebytes) from stdin, streams each source file from the local HDFS cluster using `hadoop fs -cat` into a FIFO named pipe, and concurrently uploads the FIFO contents to the destination HDFS cluster via the WebHDFS `PUT /webhdfs/v1/<path>?op=CREATE` REST API. File sizes are validated post-copy.

## Trigger

- **Type**: schedule (within workflow DAG)
- **Source**: `zrTaskOrchestrator` schedules the distribution push task after all source files are ready in HDFS
- **Frequency**: On-demand as part of cross-cluster data replication pipelines

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Task Orchestrator | Schedules and dispatches the distribution push task | `zrTaskOrchestrator` |
| Operator Adapters (DistPushTask / dist_push.py reducer) | Reads distribution manifest from stdin; manages FIFO pipe; orchestrates CatFifoWorker and RestFileCreate threads | `zrOperatorAdapters` |
| HDFS Storage (source) | Source HDFS cluster providing files via `hadoop fs -cat` | `hdfsStorage` |
| External REST API Targets (WebHDFS destination) | Destination HDFS cluster accepting files via WebHDFS REST API | `continuumZombieRunnerExternalTargets` |

## Steps

1. **Read distribution manifest**: The reducer receives a line from stdin with tab-separated fields: `<filepath>\t<target_host>\t<filebytes>`. Skips records with invalid characters (`:`) in the decoded filepath. Skips records with an empty target.
   - From: Hadoop streaming input (stdin)
   - To: `zrOperatorAdapters` (`dist_push.reducer`)
   - Protocol: stdin (tab-delimited text)

2. **Create FIFO named pipe**: Creates a temporary directory under `/var/groupon/fifo/` and creates a named pipe (FIFO) for the file transfer. The FIFO is used to connect the HDFS reader thread and the WebHDFS writer thread without buffering the full file in memory.
   - From: `zrOperatorAdapters` (`FifoFile.__enter__`)
   - To: filesystem
   - Protocol: OS `mkfifo`

3. **Start HDFS cat reader thread** (`CatFifoWorker`): Launches a daemon thread that runs `hadoop fs -cat <filepath>` and writes stdout to the FIFO path.
   - From: `zrOperatorAdapters` (`CatFifoWorker.invoke`)
   - To: `hdfsStorage`
   - Protocol: `hadoop fs -cat` subprocess

4. **Start WebHDFS writer thread** (`RestFileCreate`): Launches a daemon thread that reads from the FIFO path and streams its contents to the destination cluster via WebHDFS REST. First calls `PUT /webhdfs/v1<filepath>?op=CREATE&overwrite=<force>` to get the redirect location (HTTP 307), then PUTs the data to the redirect URL.
   - From: `zrOperatorAdapters` (`RestFileCreate.invoke`)
   - To: `continuumZombieRunnerExternalTargets` (WebHDFS endpoint)
   - Protocol: HTTP REST (WebHDFS)

5. **Coordinate reader/writer via fifo_util**: `serial_fifo_load` polls both threads every second. If either thread exits, checks for exceptions. Joins the surviving thread with a timeout of 3600 seconds.
   - From: `zrOperatorAdapters` (`fifo_util.serial_fifo_load`)
   - To: Thread coordination (in-process)
   - Protocol: direct (threading)

6. **Validate file size**: After the copy completes, compares `r.filesize` (from the WebHDFS `GETFILESTATUS` response) with the `filebytes` value from the manifest. Raises `ValueError` if they differ.
   - From: `zrOperatorAdapters`
   - To: `continuumZombieRunnerExternalTargets` (WebHDFS `?op=GETFILESTATUS`)
   - Protocol: HTTP REST (WebHDFS)

7. **Emit stream counters**: Reports Hadoop streaming counters for input files, input bytes, copied files, copied bytes, skipped files, and errors via `stream_counter`.
   - From: `zrOperatorAdapters`
   - To: Hadoop streaming framework (stderr counter reporter)
   - Protocol: stderr text (`reporter:counter:...`)

8. **Cleanup FIFO temp directory**: FIFO and temp directory are cleaned up via `FifoFile.__exit__` / `shutil.rmtree`.
   - From: `zrOperatorAdapters`
   - To: filesystem
   - Protocol: OS `shutil.rmtree`

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| File path contains invalid chars (`:`) | Skipped with `stream_counter('Invalid paths', 1)` warning | File not copied; counter incremented |
| `hadoop fs -cat` fails | `CatFifoWorker` exception set; `serial_fifo_load` raises it | Task fails; orchestrator retries |
| WebHDFS returns non-307 on initial PUT | `requests.RequestException` with `RemoteException.message` | Task fails |
| WebHDFS file already exists (`--force` not set) | `stream_counter('Skip copy-file exists', 1)` | File skipped; copy continues to next record |
| File size mismatch after copy | `ValueError` raised: "Filesize (N) not equal to destination (M)" | Task fails; integrity check caught |
| Reader or writer thread timeout (3600s) | Exception: "timed out waiting for [reader/writer] thread" | Task fails; investigate HDFS and network connectivity |

## Sequence Diagram

```
Hadoop streaming stdin -> zrOperatorAdapters: filepath\ttarget_host\tfilebytes
zrOperatorAdapters -> zrOperatorAdapters: validate_filepath (skip if invalid chars)
zrOperatorAdapters -> filesystem: mkfifo /var/groupon/fifo/<task_name>
zrOperatorAdapters -> hdfsStorage: hadoop fs -cat <filepath> > FIFO (CatFifoWorker thread)
zrOperatorAdapters -> continuumZombieRunnerExternalTargets: PUT /webhdfs/v1<filepath>?op=CREATE (RestFileCreate thread)
continuumZombieRunnerExternalTargets --> zrOperatorAdapters: HTTP 307 Location: <datanode_url>
zrOperatorAdapters -> continuumZombieRunnerExternalTargets: PUT <datanode_url> data=FIFO_contents
hdfsStorage --> filesystem: file data stream (via CatFifoWorker)
filesystem --> continuumZombieRunnerExternalTargets: FIFO stream consumed by RestFileCreate
continuumZombieRunnerExternalTargets --> zrOperatorAdapters: HTTP 201 Created
zrOperatorAdapters -> continuumZombieRunnerExternalTargets: GET /webhdfs/v1<filepath>?op=GETFILESTATUS
continuumZombieRunnerExternalTargets --> zrOperatorAdapters: FileStatus.length
zrOperatorAdapters -> zrOperatorAdapters: assert filesize == filebytes
zrOperatorAdapters -> filesystem: shutil.rmtree /var/groupon/fifo/<tmpdir>
zrOperatorAdapters --> Hadoop streaming stdout: filepath\ttarget_host\tfilesize_on_dest
```

## Related

- Architecture dynamic view: `dynamic-zombie-runner-workflow-execution`
- Related flows: [Workflow Execution](workflow-execution.md)
