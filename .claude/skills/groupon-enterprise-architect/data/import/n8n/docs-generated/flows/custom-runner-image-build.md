---
service: "n8n"
title: "Custom Runner Image Build and Release"
generated: "2026-03-03"
type: flow
flow_name: "custom-runner-image-build"
flow_type: event-driven
trigger: "Push or pull request to main branch modifying Dockerfile.runners"
participants:
  - "GitHub Actions"
  - "Conveyor Cloud Docker Registry"
architecture_ref: "dynamic-workflow-execution-flow"
---

# Custom Runner Image Build and Release

## Summary

Groupon maintains a custom n8n task runner Docker image that extends the upstream `n8nio/runners` base with additional Python packages (`psycopg[binary,pool]`) and a task runner allowlist configuration (`n8n-task-runners.json`). When `Dockerfile.runners` changes are pushed to or PRed against `main`, a GitHub Actions pipeline builds, validates, and promotes the image through pre-release to release in the Conveyor Cloud Docker registry. The released image is used as the `n8n-runners` sidecar on all queue-worker pods.

## Trigger

- **Type**: event-driven (GitHub push / pull_request)
- **Source**: A change to `Dockerfile.runners` in the n8n repository, merged or submitted as a PR to the `main` branch
- **Frequency**: On-demand, triggered by `Dockerfile.runners` changes

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GitHub Actions (groupon-runner-sets-s) | Executes the build and publish pipeline | `.github/workflows/build-n8n-runner.yaml` |
| `Dockerfile.runners` | Defines the multi-stage build for the custom runner image | `Dockerfile.runners` |
| Conveyor Cloud Pre-release Registry | Stores the intermediate pre-release image | `docker-conveyor.groupondev.com/conveyor-cloud/pre-release/n8n-runner` |
| Conveyor Cloud Release Registry | Stores the production-ready release image | `docker-conveyor.groupondev.com/conveyor-cloud/n8n-runner` |
| n8n Queue-Worker Pods | Consume the released image as the `n8n-runners` sidecar | `continuumN8nTaskRunners` |

## Steps

1. **Trigger Detection**: GitHub Actions detects a push to `main` or a pull request targeting `main` that includes changes to `Dockerfile.runners`.
   - From: GitHub repository event
   - To: `build-n8n-runner-pre-release` job
   - Protocol: GitHub Actions event

2. **Extract Version**: The pipeline reads the `FROM n8nio/runners:<version>` line in `Dockerfile.runners` to extract the base image version string (e.g., `2.6.4`).
   - From: GitHub Actions runner
   - To: `Dockerfile.runners`
   - Protocol: shell / grep

3. **Generate Timestamped Tag**: A build timestamp (`YYYYMMDD-HHMMSS`) is generated and combined with the version to produce a unique image tag (e.g., `2.6.4-build20260303-120000`).
   - From: GitHub Actions runner
   - To: Step output (`image_tag`)
   - Protocol: shell

4. **Build Multi-stage Docker Image**: The runner builds the Docker image from `Dockerfile.runners` for the `linux/amd64` platform. The build:
   - Stage 1 (`libpq`): Uses Alpine 3.23 to install `postgresql-libs` and extract `libpq.so.5`.
   - Stage 2 (final): Extends `n8nio/runners:2.6.4`; copies `libpq` shared libs; installs `psycopg[binary,pool]` via `uv pip install`; copies `n8n-task-runners.json` to `/etc/n8n-task-runners.json`.
   - From: GitHub Actions runner
   - To: Docker daemon
   - Protocol: `docker build`

5. **Push Pre-release Image**: The built image is pushed to the Conveyor Cloud pre-release registry with both the timestamped and base version tags.
   - From: GitHub Actions runner
   - To: `docker-conveyor.groupondev.com/conveyor-cloud/pre-release/n8n-runner`
   - Protocol: `docker push`

6. **Promote to Release (push to main only)**: On push to `main` (not on PRs), the `build-n8n-runner-release` job pulls the pre-release image and re-tags it as a release image in the main Conveyor Cloud registry.
   - From: GitHub Actions runner
   - To: `docker-conveyor.groupondev.com/conveyor-cloud/n8n-runner`
   - Protocol: `docker tag` + `docker push`

7. **Deployment Update**: Deployment files reference the release image by version tag (e.g., `image: docker-conveyor.groupondev.com/conveyor-cloud/n8n-runner:1.122.3` in `production-us-central1.yml`). Pod restarts on deployment upgrade consume the new image.
   - From: Conveyor Cloud deploy pipeline
   - To: n8n queue-worker pods (`n8n-runners` sidecar container)
   - Protocol: Kubernetes rolling update

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Version not found in Dockerfile.runners | `extract_version` step exits with error | Pipeline fails; image not built; PR blocked |
| Docker build failure | GitHub Actions step fails | Pre-release image not pushed; release job skipped |
| Pre-release push fails | Pipeline fails; release job has no image to promote | Release image not updated; existing image unchanged |
| Release push fails | `build-n8n-runner-release` job fails | Pre-release exists but is not promoted; deployment files still reference previous release |

## Sequence Diagram

```
GitHubEvent -> GitHubActions: push/PR on Dockerfile.runners
GitHubActions -> Dockerfile.runners: grep FROM n8nio/runners:<version>
GitHubActions -> GitHubActions: Compute image_tag = <version>-build<timestamp>
GitHubActions -> DockerDaemon: docker build --platform linux/amd64 -f Dockerfile.runners
DockerDaemon --> GitHubActions: Image built
GitHubActions -> PreReleaseRegistry: docker push pre-release/n8n-runner:<image_tag>
GitHubActions -> PreReleaseRegistry: docker push pre-release/n8n-runner:<version>
[On push to main only]
GitHubActions -> PreReleaseRegistry: docker pull pre-release/n8n-runner:<image_tag>
GitHubActions -> ReleaseRegistry: docker push n8n-runner:<image_tag>
GitHubActions -> ReleaseRegistry: docker push n8n-runner:<version>
```

## Related

- Architecture dynamic view: `dynamic-workflow-execution-flow`
- Related flows: [Code Node Task Execution](code-node-task-execution.md)
- Build config: `.github/workflows/build-n8n-runner.yaml`
- Runner config: `n8n-task-runners.json`, `extras.txt`, `Dockerfile.runners`
