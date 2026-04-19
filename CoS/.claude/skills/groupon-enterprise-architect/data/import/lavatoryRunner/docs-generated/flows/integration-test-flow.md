---
service: "lavatoryRunner"
title: "Integration Test Flow"
generated: "2026-03-03"
type: flow
flow_name: "integration-test-flow"
flow_type: batch
trigger: "Jenkins CI pipeline Test stage (on every push)"
participants:
  - "jenkinsAgent"
  - "continuumLavatoryRunnerService"
  - "artifactoryTestContainer"
architecture_ref: "dynamic-continuumLavatoryRunnerService"
---

# Integration Test Flow

## Summary

The integration test flow validates that Lavatory Runner correctly enforces retention policies end-to-end. It runs inside Jenkins as a Docker-in-Docker build environment. A local Artifactory Pro container is started, seeded with Docker images at controlled ages via metadata manipulation, then the runner is executed against two test repositories. Final artifact counts are compared against expected values to determine pass/fail.

## Trigger

- **Type**: api-call (Jenkins pipeline)
- **Source**: Jenkins "Test" stage (`Jenkinsfile`) on every push to any branch
- **Frequency**: Per commit

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Jenkins agent (dind_4gb_2cpu) | Executes `make test` inside a Docker-in-Docker Mesos container | N/A |
| Lavatory Runner container | Applies retention policies against the test Artifactory instance | `continuumLavatoryRunnerService` |
| Artifactory Pro test container | Ephemeral local Artifactory instance seeded with test fixture images | N/A (test infrastructure) |

## Steps

1. **Jenkins checks out `artifactory/secret`**: The Jenkinsfile clones the `artifactory/secret` repo (using `svcdcos-ssh` credentials) into `test/secret/`. This provides the Artifactory Pro license file required for the test container.
   - From: Jenkins agent
   - To: GitHub (internal)
   - Protocol: SSH/Git

2. **Pre-test cleanup**: Removes any stale Docker images with the test pattern (`*/zz/test_image*`), resets the tmp volume directory, and adds test hostnames to `/etc/hosts` for `docker-conveyor-snc1.localhost` and `docker-conveyor-snapshots-snc1.localhost`.
   - From: Jenkins agent (test.sh)
   - To: Docker daemon (local)
   - Protocol: Docker CLI

3. **Builds and starts Artifactory test container**: Builds `artifactory/testartifactory:<TAG>` from `test/Dockerfile` (based on `docker.bintray.io/jfrog/artifactory-pro:5.8.3`) and starts it on the `testnet` Docker network. Polls `GET /artifactory/api/system/ping` up to 10 times (5-second intervals) to wait for readiness.
   - From: Jenkins agent (test.sh)
   - To: Artifactory test container
   - Protocol: Docker run / HTTP

4. **Creates repositories, users, and permissions**: Uses the Artifactory REST API to create two local Docker repositories (`docker-conveyor-snapshots-snc1`, `docker-conveyor-snc1`), a test user, and permission targets.
   - From: Jenkins agent (test.sh)
   - To: Artifactory test container REST API
   - Protocol: HTTP (internal Docker network)

5. **Pushes test Docker images**: Pulls `alpine` and pushes 12 copies to `docker-conveyor-snapshots-snc1` and 22 copies to `docker-conveyor-snc1`, tagging each with a sequential number. Sleeps 1 second between each push to ensure distinct `updated` timestamps. Sleeps 30 seconds after all pushes for metadata propagation.
   - From: Jenkins agent (test.sh)
   - To: Artifactory test container Docker registry
   - Protocol: Docker push

6. **Exports and munges repository metadata**: Exports the Artifactory repository data to a ZIP, unpacks it, and uses `sed` to overwrite `<created>`, `<lastModified>`, and `<lastUpdated>` timestamps in `artifactory-file.xml` and `artifactory-folder.xml` files. Specifically sets: 11 snapshot images to 5 days ago, 1 snapshot image to 8 days ago, 19 conveyor images to 29 days ago, 2 conveyor images to 31 days ago, and 1 conveyor image to 100 days ago.
   - From: Jenkins agent (test.sh)
   - To: Local filesystem (tmp/)
   - Protocol: Shell / sed

7. **Reimports munged data**: Calls the Artifactory import API (`POST /artifactory/api/import/system`) to reload the timestamp-modified metadata.
   - From: Jenkins agent (test.sh)
   - To: Artifactory test container REST API
   - Protocol: HTTP

8. **Downloads one image to set download timestamp**: Pulls `docker-conveyor-snc1.localhost:8081/zz/test_image:22` (the 100-day-old image) to set a recent `stat.downloaded` value. Sleeps 30 seconds for metadata update propagation.
   - From: Jenkins agent (test.sh)
   - To: Artifactory test container Docker registry
   - Protocol: Docker pull

9. **Records artifact counts before purge**: Calls `GET /artifactory/api/storageinfo` and parses the `itemsCount` for each test repository. Expects 50 items in `docker-conveyor-snapshots-snc1` and 90 items in `docker-conveyor-snc1`.
   - From: Jenkins agent (test.sh)
   - To: Artifactory test container REST API
   - Protocol: HTTP / jq

10. **Runs Lavatory Runner against each test repository**: Executes the `lavatoryrunner:<TAG>` container for each repository with `--nodryrun` to perform real deletions against the local Artifactory instance.
    - From: Jenkins agent (test.sh)
    - To: `continuumLavatoryRunnerService` (test container)
    - Protocol: Docker run

11. **Records artifact counts after purge**: Calls `GET /artifactory/api/storageinfo` again for each repository. Expects 42 items in `docker-conveyor-snapshots-snc1` and 86 items in `docker-conveyor-snc1`.
    - From: Jenkins agent (test.sh)
    - To: Artifactory test container REST API
    - Protocol: HTTP / jq

12. **Asserts test results**: Compares before/after counts against `EXPECTED_BEFORE` and `EXPECTED_AFTER` arrays. Exits 0 if all match; exits 1 on any mismatch.
    - From: Jenkins agent (test.sh `get_result()`)
    - To: (shell exit code)
    - Protocol: Shell

13. **Post-build cleanup**: Stops and removes the Artifactory test container and the `testnet` Docker network.
    - From: Jenkins agent (test.sh)
    - To: Docker daemon (local)
    - Protocol: Docker CLI

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Artifactory test container fails to start within 50s | Script exits with error `"Artifactory didn't start in 50 sec."` | Jenkins Test stage fails |
| `artifactory/secret` checkout fails | Git clone error propagates; `set -e` exits script | Jenkins Test stage fails |
| Actual artifact count does not match expected count | `get_result()` increments `fail_count`; exits with code 1 | Jenkins Test stage fails; pipeline does not push image |
| Individual repository purge fails | `set -e` causes test.sh to exit immediately | Jenkins Test stage fails |

## Sequence Diagram

```
Jenkins       -> GitHub: clone artifactory/secret (svcdcos-ssh)
Jenkins       -> Docker: build artifactory/testartifactory:<TAG>
Jenkins       -> Docker: run Artifactory Pro test container on testnet
Jenkins       -> ArtifactoryTest: POST /api/repositories (create docker-conveyor-*)
Jenkins       -> ArtifactoryTest: docker push alpine x34 (12 snapshots + 22 conveyor)
Jenkins       -> Filesystem: export, unzip, sed timestamps, reimport
Jenkins       -> ArtifactoryTest: docker pull test_image:22 (set download stat)
Jenkins       -> ArtifactoryTest: GET /api/storageinfo (record before counts)
Jenkins       -> LavatoryRunner: docker run purge --repo docker-conveyor-snapshots-snc1 --nodryrun
LavatoryRunner -> ArtifactoryTest: AQL queries + DELETE per candidate
Jenkins       -> LavatoryRunner: docker run purge --repo docker-conveyor-snc1 --nodryrun
LavatoryRunner -> ArtifactoryTest: AQL queries + DELETE per candidate
Jenkins       -> ArtifactoryTest: GET /api/storageinfo (record after counts)
Jenkins       -> Jenkins: assert counts match expected; exit 0 or 1
```

## Related

- Architecture dynamic view: `dynamic-continuumLavatoryRunnerService`
- Related flows: [Scheduled Artifact Purge](scheduled-artifact-purge.md), [Docker Conveyor Snapshots Retention Policy](docker-conveyor-snapshots-retention.md)
