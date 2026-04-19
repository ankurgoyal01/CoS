---
service: "lavatoryRunner"
title: "Docker Conveyor Snapshots Retention Policy"
generated: "2026-03-03"
type: flow
flow_name: "docker-conveyor-snapshots-retention"
flow_type: batch
trigger: "Cron job on weekdays 10:00-15:00 UTC (0 10-15 * * 1-5)"
participants:
  - "continuumLavatoryRunnerService"
  - "retentionEvaluator"
  - "artifactoryClient"
  - "artifactory"
architecture_ref: "dynamic-continuumLavatoryRunnerService"
---

# Docker Conveyor Snapshots Retention Policy

## Summary

This flow documents the retention policy applied to the `docker-conveyor-snapshots` repository (and its regional variants: `docker-conveyor-snapshots-sac1`, `docker-conveyor-snapshots-snc1`, `docker-conveyor-snapshots-us-west-2`). Because snapshot images are transient build artifacts, this policy is more aggressive than the standard conveyor policy: it removes all images older than 7 days and caps each image's retained tags at 10. There is no whitelist and no cross-colo download-recency check for snapshots. The policy files for regional variants are symlinks pointing to `docker_conveyor_snapshots.py`.

## Trigger

- **Type**: schedule
- **Source**: Host cron job on `artifactory-utility` primary host, configured by Ansible
- **Frequency**: Cron expression `0 10-15 * * 1-5` (UTC) — hourly from 10:00 to 15:00, Monday through Friday

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Lavatory Runner Service | Loads and executes the DockerConveyorSnapshots policy | `continuumLavatoryRunnerService` |
| Retention Evaluator | Applies age threshold and tag count limit rules | `retentionEvaluator` |
| Artifactory Client | Issues AQL queries and DELETE requests | `artifactoryClient` |
| Artifactory | Source of snapshot image metadata; target of DELETE operations | `artifactory` |

## Steps

1. **Retrieves tags older than 7 days**: Queries Artifactory via AQL with `{"updated": {"$lt": "<today - 7 days>"}}` to identify all snapshot tags last updated before the 7-day threshold.
   - From: `retentionEvaluator`
   - To: `artifactory`
   - Protocol: HTTPS/REST (AQL POST)

2. **Retrieves tags within the last 7 days (for count limiting)**: Queries Artifactory via AQL with `{"updated": {"$gte": "<today - 7 days>"}}` to retrieve recent tags that may exceed the top-10 per-image limit.
   - From: `retentionEvaluator`
   - To: `artifactory`
   - Protocol: HTTPS/REST (AQL POST)

3. **Computes tags exceeding the top-10 limit per image**: Groups recent tags by image path, sorts by `updated` descending. Tags ranked beyond position 10 per image are added to the purge list.
   - From: `retentionEvaluator`
   - To: (in-process Python)
   - Protocol: In-process Python

4. **Combines purge candidates**: Merges `older_than_7_days_tags` with `tags_over_top_10_limit` into the final purge list. No whitelist or download-date filtering is applied for snapshots.
   - From: `retentionEvaluator`
   - To: (in-process Python)
   - Protocol: In-process Python

5. **Deletes purge candidates**: Issues DELETE requests to Artifactory for each artifact in the final purge list.
   - From: `artifactoryClient`
   - To: `artifactory`
   - Protocol: HTTPS/REST (DELETE)

6. **Logs results**: Writes cleanup statistics to `/var/log/lavatory/<repo-name>.log`, including count of tags older than 7 days and count of tags outside the top-10 limit.
   - From: `continuumLavatoryRunnerService`
   - To: `loggingStack` (Splunk via file forwarder)
   - Protocol: File write

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AQL query returns no results | `older_then_7_days_tags` and `tags_over_top_10_limit` are both empty lists; `return []` | No deletions; normal outcome if repository is fresh |
| Artifactory unreachable | Container exits non-zero | Cron logs failure; retry on next cron run |
| DELETE fails for individual tag | Logged; runner continues with remaining candidates | Partial purge; undeleted items retried on next scheduled run |

## Sequence Diagram

```
RetentionEvaluator -> Artifactory: AQL - tags updated < today-7d (get_updated_before)
Artifactory        --> RetentionEvaluator: old snapshot tag list
RetentionEvaluator -> Artifactory: AQL - tags updated >= today-7d (get_updated_after)
Artifactory        --> RetentionEvaluator: recent snapshot tag list
RetentionEvaluator -> RetentionEvaluator: find_tags_over_limit (top 10 per image)
RetentionEvaluator -> RetentionEvaluator: combine purge list (old + over limit)
LavatoryRunner     -> Artifactory: DELETE per purge candidate
Artifactory        --> LavatoryRunner: 200 OK
LavatoryRunner     -> Splunk: write log line (old count, over-limit count)
```

## Related

- Architecture dynamic view: `dynamic-continuumLavatoryRunnerService`
- Related flows: [Scheduled Artifact Purge](scheduled-artifact-purge.md), [Docker Conveyor Retention Policy](docker-conveyor-retention.md)
