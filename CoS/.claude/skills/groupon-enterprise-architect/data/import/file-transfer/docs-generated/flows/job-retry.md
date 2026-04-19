---
service: "file-transfer"
title: "Job Retry"
generated: "2026-03-03"
type: flow
flow_name: "job-retry"
flow_type: event-driven
trigger: "Any Throwable thrown during job execution"
participants:
  - "fileTransfer_jobRunner"
architecture_ref: "dynamic-sync-files"
---

# Job Retry

## Summary

When any job execution throws a `Throwable`, the Job Runner applies a built-in retry policy before giving up. The job is re-scheduled up to 3 times, with a delay that increases linearly by 5 seconds per attempt (5 s, 10 s, 15 s). After 3 failed attempts the runner logs `job/out-of-retries` with `investigate-cause? true` and terminates. This flow applies to both `sync-files` and `check-jobs` job functions.

## Trigger

- **Type**: event-driven (error condition)
- **Source**: Any `Throwable` caught in `execute-job`
- **Frequency**: On demand, triggered by failure of `sync-files` or `check-jobs`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Job Runner | Catches the error, schedules the retry, tracks retry count, logs all state transitions | `fileTransfer_jobRunner` |

## Steps

1. **Catches exception in `execute-job`**: A `Throwable` is caught in the `catch` block of `execute-job`. The error is passed to `retry-job` before logging `job/error`.
   - From: `fileTransfer_jobRunner`
   - To: `retry-job` fn
   - Protocol: direct (in-process)

2. **Checks retry count**: `retry-job` reads `:retries` from the job map (defaults to 0). If `retries < 3`, schedules a retry.
   - From: `retry-job`
   - Protocol: direct (in-process)

3. **Logs retry warning**: Emits `{:type :job/retry :retry-count <n>}` as a structured warning log before re-invoking the job.
   - From: `retry-job`
   - To: Log output
   - Protocol: stdout (structured JSON)

4. **Re-invokes `execute-job`**: Calls `execute-job` with the same job function and name, but increments `:retries` and adds a `:schedule {:in <delay-ms>}` key. Delay: `5000 ms × (retries + 1)`.
   - From: `retry-job`
   - To: `execute-job`
   - Protocol: direct (in-process, recursive)

5. **Gives up after 3 retries**: If `retries >= 3`, logs `{:type :job/out-of-retries :investigate-cause? true :job-name <name>}` and returns without re-scheduling.
   - From: `retry-job`
   - To: Log output / Splunk
   - Protocol: stdout (structured JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `retries < 3` | Re-invoke `execute-job` after delay | Job attempt incremented; up to 3 total retries |
| `retries >= 3` | Log `job/out-of-retries` | Job permanently fails for this CronJob run; file remains unprocessed; `check-jobs` will detect it next day |
| Retry itself throws | Handled by the same `catch` block in the new `execute-job` call | Retry count continues to increment |

## Sequence Diagram

```
execute-job    : try job-fn(job-name, job)
execute-job    : catch Throwable -> retry-job(job-fn, job-name, job)
retry-job      : retries < 3?
retry-job      -> Log          : log/warn {:type :job/retry :retry-count N}
retry-job      -> execute-job  : execute-job(job-fn, job-name, job + {:retries N+1, :schedule {:in 5000*(N+1)}})
(on final failure)
retry-job      -> Log          : log/error {:type :job/out-of-retries :investigate-cause? true}
```

## Related

- Architecture dynamic view: `dynamic-sync-files`
- Related flows: [Sync Files](sync-files.md), [Check Unprocessed Files](check-unprocessed-files.md)
