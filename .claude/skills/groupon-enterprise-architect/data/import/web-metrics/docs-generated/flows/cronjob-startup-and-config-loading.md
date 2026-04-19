---
service: "web-metrics"
title: "CronJob Startup and Config Loading"
generated: "2026-03-03"
type: flow
flow_name: "cronjob-startup-and-config-loading"
flow_type: scheduled
trigger: "Kubernetes CronJob schedule fires at minutes 10 and 40 each hour"
participants:
  - "continuumWebMetricsCli"
  - "wmCliEntryCommand"
  - "wmCliConfigResolution"
  - "wmCliJobDispatcher"
architecture_ref: "dynamic-web-metrics"
---

# CronJob Startup and Config Loading

## Summary

When the Kubernetes CronJob fires, the container starts `npm start`, which invokes `lib/cli.js` via `nilo`. The CLI resolves the run configuration — from an inline object, a local JSON file, or a remote URL — applies retries if fetching from HTTP, and hands the parsed options off to the main `webMetrics()` orchestration function. When running interactively (TTY), the parent process attaches steno/pretty-steno log formatting before spawning a child process to perform the actual work.

## Trigger

- **Type**: schedule
- **Source**: Kubernetes CronJob scheduler (`jobSchedule: '10,40 * * * *'`)
- **Frequency**: Twice per hour (at 10 and 40 minutes past each hour)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kubernetes CronJob scheduler | Fires the pod at the scheduled time | external |
| Web Metrics CLI | Entrypoint container process | `continuumWebMetricsCli` |
| CLI Command Adapter | Parses arguments and orchestrates startup | `wmCliEntryCommand` |
| Configuration Resolver | Loads and validates run configuration | `wmCliConfigResolution` |
| Worker Dispatcher | Passes resolved config to `webMetrics()` | `wmCliJobDispatcher` |

## Steps

1. **Pod starts**: Kubernetes schedules and starts the CronJob pod. The container entrypoint runs `npm start` → `node scripts/run-all.js`.
   - From: Kubernetes CronJob
   - To: `continuumWebMetricsCli`
   - Protocol: process spawn

2. **CLI command initialised**: `nilo` registers the `start` command with flags `-c`, `-a`, `-o`, `-d`. The `start` action is invoked.
   - From: `wmCliEntryCommand`
   - To: nilo app registry
   - Protocol: direct (in-process)

3. **TTY check**: If the process is attached to a TTY (local development), the parent process attaches `groupon-steno` parser and `@grpn/pretty-steno` formatter, then re-spawns itself as a child with `WM_CHILD=true`. In Kubernetes (non-TTY), this step is skipped.
   - From: `wmCliEntryCommand`
   - To: child process
   - Protocol: Node.js `child_process.spawn`

4. **Config resolution**: `wmCliConfigResolution` evaluates the `-c` argument:
   - If the value is already an object — use it directly
   - If it starts with `http` — fetch from the URL using `gofer` with up to 5 retries and a 5000 ms max timeout
   - Otherwise — `require()` the local file path (absolute or relative to repo root)
   - From: `wmCliConfigResolution`
   - To: local filesystem or remote HTTP URL
   - Protocol: `require()` or HTTPS

5. **Telemetry initialised**: `itier-instrumentation` is enabled; `initInflux()` sets up the Telegraf/Influx client connection parameters from `TELEGRAF_URL` env var (or defaults to `metrics-gateway-vip.snc1:80`).
   - From: `wmCliJobDispatcher`
   - To: `influx` client (in-process)
   - Protocol: direct (in-process)

6. **Dispatch to webMetrics()**: The resolved `runOptions` object (containing `cruxRuns` and/or `perfRuns` arrays) is passed to the `webMetrics()` function, which orchestrates downstream data collection flows.
   - From: `wmCliJobDispatcher`
   - To: `continuumWebMetricsWorker`
   - Protocol: Piscina worker thread messages

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Config file not found | `require()` throws; caught by top-level catch in `webMetrics()` | Error logged via `itier-tracing` as `failed-app-run`; pod exits with non-zero code |
| Remote config HTTP error (all retries exhausted) | `promise-retry` exhausts 5 retries; error thrown | Error caught and logged; `runOptions` remains `undefined`; job exits early |
| Missing `runOptions` after resolution | Guard check `if (!runOptions)` | Debug log emitted; function returns without running any audits |
| Process spawn error (TTY mode) | `cli.on('error', reject)` | Parent process rejects and exits |

## Sequence Diagram

```
Kubernetes  -> CLI Process    : spawn npm start
CLI Process -> nilo App       : register + invoke "start" command
nilo App    -> Config Resolver: resolve -c argument (file/url/object)
Config Resolver -> Remote URL : GET config JSON (if http, with retries)
Config Resolver -> CLI Process: return runOptions
CLI Process -> Influx Client  : initInflux() - configure Telegraf endpoint
CLI Process -> webMetrics()   : dispatch(runOptions, cliOptions)
```

## Related

- Related flows: [CrUX Data Collection](crux-data-collection.md), [Metric Transformation and Publishing](metric-publishing.md), [Lighthouse Lab Audit](lighthouse-lab-audit.md)
