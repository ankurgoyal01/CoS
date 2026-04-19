---
service: "lavatoryRunner"
title: "Docker Conveyor Retention Policy"
generated: "2026-03-03"
type: flow
flow_name: "docker-conveyor-retention"
flow_type: batch
trigger: "Cron-triggered container invocation for docker-conveyor repository"
participants:
  - "continuumLavatoryRunnerService"
  - "retentionEvaluator"
  - "artifactoryClient"
  - "artifactory"
architecture_ref: "dynamic-continuumLavatoryRunnerService"
---

# Docker Conveyor Retention Policy

## Summary

This flow describes how the `docker-conveyor` retention policy determines which Docker image tags to delete from the `docker-conveyor` repository (and its regional variants: `docker-conveyor-dub1`, `docker-conveyor-sac1`, `docker-conveyor-snc1`, `docker-conveyor-us-west-2`, `docker-conveyor-us-west-2-production`). The policy applies four rules: age threshold, per-image tag count limit, cross-colo download recency protection, and a hard-coded path-based whitelist. The `docker-conveyor_*` policy files for regional repos are all symlinks pointing to `docker_conveyor.py`.

## Trigger

- **Type**: schedule
- **Source**: Host cron job on `artifactory-utility` primary host, one invocation per target repository name
- **Frequency**: Per Ansible-configured cron expression per regional repository

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Lavatory Runner Service | Loads and executes the DockerConveyor policy | `continuumLavatoryRunnerService` |
| Retention Evaluator | Applies policy logic: age, count limit, download recency, whitelist | `retentionEvaluator` |
| Artifactory Client | Issues AQL queries to retrieve tag metadata and download statistics | `artifactoryClient` |
| Artifactory | Source of artifact metadata; target of DELETE operations | `artifactory` |

## Steps

1. **Retrieves all tags**: Queries all `manifest.json` files in the repository using AQL filter `{"@docker.repoName": {"$eq": "*"}}` to build the complete tag list.
   - From: `retentionEvaluator`
   - To: `artifactory`
   - Protocol: HTTPS/REST (AQL POST)

2. **Identifies tags older than 30 days**: Runs AQL with `{"updated": {"$lt": "<today - 30 days>"}}` to find tags last updated before the age threshold.
   - From: `retentionEvaluator`
   - To: `artifactory`
   - Protocol: HTTPS/REST (AQL POST)

3. **Identifies tags within the last 30 days (for count limiting)**: Runs AQL with `{"updated": {"$gte": "<today - 30 days>"}}` to find recent tags that may exceed the per-image top-20 limit.
   - From: `retentionEvaluator`
   - To: `artifactory`
   - Protocol: HTTPS/REST (AQL POST)

4. **Computes tags over the top-20 limit per image**: Groups recent tags by image path and sorts by `updated` descending. Tags beyond the 20 newest are added to the purge candidate list.
   - From: `retentionEvaluator`
   - To: (in-process Python)
   - Protocol: In-process Python

5. **Combines initial purge list**: Merges `older_than_30_days_tags` and `tags_over_top_20_limit` as the initial candidate set. Removes any items that fall within the top 20 newest across all tags (using `find_tags_under_limit`).
   - From: `retentionEvaluator`
   - To: (in-process Python set subtraction)
   - Protocol: In-process Python

6. **Checks cross-colo download recency**: For each Artifactory endpoint in `TARGET_COLOS`, creates a separate `Artifactory` client instance and queries artifacts downloaded within the last 90 days (`{"stat.downloaded": {"$gt": "<today - 90 days>"}}`). Builds a hash set of recently downloaded artifact paths.
   - From: `retentionEvaluator`
   - To: `artifactory` (multiple colo instances)
   - Protocol: HTTPS/REST (AQL POST, per colo)

7. **Filters download-protected artifacts**: Removes from the purge candidate list any artifact whose `<path>/<name>` appears in the cross-colo recently-downloaded hash set.
   - From: `retentionEvaluator`
   - To: (in-process Python)
   - Protocol: In-process Python

8. **Applies path-based whitelist**: Removes any artifact whose full path matches the whitelist regex pattern:
   `conveyor/centos7.*/.*|conveyor-ci/ansible-deploy/.*|conveyor-ci/telegraf-agent/.*|conveyor-ci/maven-cache-warmer/.*`
   - From: `retentionEvaluator`
   - To: (in-process Python regex)
   - Protocol: In-process Python

9. **Deletes purge candidates**: Sends DELETE requests to Artifactory for each remaining artifact in the final purge list.
   - From: `artifactoryClient`
   - To: `artifactory`
   - Protocol: HTTPS/REST (DELETE)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AQL query returns error | Container exits with error | No deletions; operator investigates |
| Colo unreachable for download-date check | No evidence found in codebase for per-colo retry | Artifacts from that colo may be incorrectly eligible for deletion |
| Whitelist regex misconfigured | Protected artifacts may be deleted | Policy review required; restoration from Artifactory trash can if available |
| DELETE request fails | Logged; runner continues with next candidate | Artifact remains; next run retries |

## Sequence Diagram

```
RetentionEvaluator -> Artifactory: AQL - all tags (get_all_tags)
Artifactory        --> RetentionEvaluator: full tag list
RetentionEvaluator -> Artifactory: AQL - tags updated >= today-30d (get_updated_after)
Artifactory        --> RetentionEvaluator: recent tags
RetentionEvaluator -> Artifactory: AQL - tags updated < today-30d (get_updated_before)
Artifactory        --> RetentionEvaluator: old tags
RetentionEvaluator -> RetentionEvaluator: compute tags over top-20 limit per image
RetentionEvaluator -> RetentionEvaluator: merge initial purge list; remove top-20 protected
RetentionEvaluator -> Artifactory[colo1]: AQL - downloaded since today-90d
Artifactory[colo1] --> RetentionEvaluator: downloaded artifact paths
RetentionEvaluator -> Artifactory[coloN]: AQL - downloaded since today-90d (repeat per TARGET_COLOS)
Artifactory[coloN] --> RetentionEvaluator: downloaded artifact paths
RetentionEvaluator -> RetentionEvaluator: filter download-protected and whitelist-protected artifacts
LavatoryRunner     -> Artifactory: DELETE per purge candidate
Artifactory        --> LavatoryRunner: 200 OK
```

## Related

- Architecture dynamic view: `dynamic-continuumLavatoryRunnerService`
- Related flows: [Scheduled Artifact Purge](scheduled-artifact-purge.md), [Docker Conveyor Snapshots Retention Policy](docker-conveyor-snapshots-retention.md)
