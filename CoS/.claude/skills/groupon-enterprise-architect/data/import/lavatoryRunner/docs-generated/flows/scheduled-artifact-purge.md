---
service: "lavatoryRunner"
title: "Scheduled Artifact Purge"
generated: "2026-03-03"
type: flow
flow_name: "scheduled-artifact-purge"
flow_type: scheduled
trigger: "Host cron job on artifactory-utility machine"
participants:
  - "cronScheduler"
  - "continuumLavatoryRunnerService"
  - "policyLoader"
  - "retentionEvaluator"
  - "artifactoryClient"
  - "artifactory"
  - "loggingStack"
architecture_ref: "dynamic-continuumLavatoryRunnerService"
---

# Scheduled Artifact Purge

## Summary

This is the primary end-to-end operational flow for Lavatory Runner. A host-level cron job launches the runner container with a target repository name as a CLI argument. The runner loads the matching policy module, queries Artifactory for artifact metadata, evaluates retention rules, and deletes all artifacts that meet the purge criteria. Results are logged to a per-repository log file and forwarded to Splunk.

## Trigger

- **Type**: schedule
- **Source**: Root crontab on `artifactory-utility` primary host, configured by Ansible playbook
- **Frequency**: Per cron expression per repository (e.g., `docker-conveyor-snapshots` runs on `0 10-15 * * 1-5` UTC, weekdays only)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cron scheduler (host) | Triggers container launch with repo name argument | N/A (host-level) |
| Lavatory Runner Service | Orchestrates policy loading, evaluation, and purge | `continuumLavatoryRunnerService` |
| Policy Loader | Imports the correct Python policy module for the target repo | `policyLoader` |
| Retention Evaluator | Computes purge candidates by applying policy rules | `retentionEvaluator` |
| Artifactory Client | Issues AQL queries and DELETE requests to Artifactory | `artifactoryClient` |
| Artifactory | Stores Docker image metadata and layers; responds to REST API calls | `artifactory` |
| Logging Stack (Splunk) | Ingests log files written to `/var/log/lavatory/` | `loggingStack` |

## Steps

1. **Cron triggers container launch**: Host cron executes `/opt/lavatory/lavatory_cron_job.sh` with a repository name (e.g., `docker-conveyor-snapshots`).
   - From: `cronScheduler` (host)
   - To: `continuumLavatoryRunnerService` (Docker container)
   - Protocol: Docker run (CLI invocation: `lavatory purge --policies-path=/opt/lavatory/policies --repo <repo-name> --no-default`)

2. **Policy Loader imports the matching policy module**: The runner resolves the policy file corresponding to the `--repo` argument from `/opt/lavatory/policies/`. The module's `load()` function instantiates the policy class.
   - From: `continuumLavatoryRunnerService`
   - To: `policyLoader`
   - Protocol: In-process Python (`importlib`)

3. **Retention Evaluator calls `purgelist()`**: The policy's `purgelist()` method is invoked, which instructs the `Policy` base class helper methods to query Artifactory.
   - From: `policyLoader`
   - To: `retentionEvaluator`
   - Protocol: In-process Python

4. **Artifactory Client executes AQL queries**: AQL queries are posted to `POST /artifactory/api/search/aql` to retrieve artifact metadata (path, name, updated timestamp, download stats) filtered by `@docker.repoName` and date thresholds.
   - From: `retentionEvaluator` (via `artifactoryClient`)
   - To: `artifactory`
   - Protocol: HTTPS/REST

5. **Artifactory returns metadata**: Artifactory responds with JSON result sets of `manifest.json` file items matching the AQL filter terms.
   - From: `artifactory`
   - To: `artifactoryClient`
   - Protocol: HTTPS/REST (JSON response)

6. **Retention Evaluator computes purge candidates**: The policy applies its age threshold, tag count limit, and whitelist rules to the metadata. For `docker-conveyor`, it additionally queries `TARGET_COLOS` Artifactory instances for download-date statistics to exclude recently accessed artifacts.
   - From: `retentionEvaluator`
   - To: (in-process Python set operations)
   - Protocol: In-process Python

7. **Artifactory Client issues DELETE requests**: For each artifact in the purge candidate list, the runner issues a DELETE request to the Artifactory REST API to remove the tag directory.
   - From: `artifactoryClient`
   - To: `artifactory`
   - Protocol: HTTPS/REST (DELETE)

8. **Performance metrics logged**: After purge completion, the runner logs an `INFO performance` line with `repo`, `size_in_bytes`, `removed_bytes_count`, `removed_bytes_percent`, `removed_files_count`, and `removed_files_percent` to the log file at `/var/log/lavatory/<repo-name>.log`.
   - From: `continuumLavatoryRunnerService`
   - To: `loggingStack` (via host file → Splunk forwarder)
   - Protocol: File write / Splunk ingestion

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Artifactory unreachable | Container exits with non-zero status code | Cron logs failure; next scheduled run retries |
| Authentication failure (HTTP 401) | Container exits with error log | Operator must update credentials and re-run |
| Policy module not found for repo | Lavatory exits with error | No deletions; log error; operator must add policy file |
| AQL query returns empty result | No purge candidates; skips deletion | Log shows `removed_files_count=0`; normal outcome |
| DELETE request fails for individual artifact | Logged as error; continues with remaining candidates | Partial purge; undeleted artifacts remain until next run |

## Sequence Diagram

```
CronScheduler  -> LavatoryRunner: docker run lavatory purge --repo <repo-name>
LavatoryRunner -> PolicyLoader: load policy module for <repo-name>
PolicyLoader   -> RetentionEvaluator: instantiate and call purgelist()
RetentionEvaluator -> Artifactory: POST /artifactory/api/search/aql (metadata query)
Artifactory    --> RetentionEvaluator: JSON artifact list
RetentionEvaluator -> Artifactory: POST /artifactory/api/search/aql (download-date check, per colo)
Artifactory    --> RetentionEvaluator: JSON downloaded-artifact list
RetentionEvaluator --> LavatoryRunner: purge candidate list
LavatoryRunner -> Artifactory: DELETE /artifactory/<repo>/<image>/<tag> (per candidate)
Artifactory    --> LavatoryRunner: 200 OK / error
LavatoryRunner -> Splunk: write INFO performance log line to /var/log/lavatory/<repo>.log
```

## Related

- Architecture dynamic view: `dynamic-continuumLavatoryRunnerService`
- Related flows: [Docker Conveyor Retention Policy](docker-conveyor-retention.md), [Docker Conveyor Snapshots Retention Policy](docker-conveyor-snapshots-retention.md)
