---
service: "routing_config_production"
title: "Emergency Deploy"
generated: "2026-03-03"
type: flow
flow_name: "emergency-deploy"
flow_type: synchronous
trigger: "Manual invocation of ./gradlew emergency_deploy"
participants:
  - "On-call Engineer"
  - "Gradle SSH plugin"
  - "On-prem routing app nodes"
architecture_ref: "dynamic-routingConfigProduction"
---

# Emergency Deploy

## Summary

The emergency deploy flow allows a routing config change to bypass the normal deployment safety checks (branch verification, clean working directory requirement) and push directly to on-prem routing app nodes. This is intended for urgent production fixes where the standard pipeline cannot be reached or waited on. It places a `lock` file on all app nodes to prevent concurrent normal deploys, deploys the config bundle, and triggers a hot-reload. The lock must be manually removed after the situation is resolved.

## Trigger

- **Type**: manual
- **Source**: On-call engineer invoking `./gradlew emergency_deploy` from a local machine with SSH agent access
- **Frequency**: Exceptional only — for production emergencies

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| On-call Engineer | Executes emergency deploy; accepts warning prompt; manually unlocks after resolution | — |
| Gradle SSH plugin (`org.hidetake:gradle-ssh-plugin:1.1.2`) | Orchestrates SSH sessions to all on-prem routing app nodes | `routingConfigProduction` |
| On-prem routing app nodes (`routing-app[1-10].snc1`, `routing-app[1-10].sac1`, `routing-app[1-10].dub1`) | Receive the config tarball, unpack it into a versioned release directory, update the `current` symlink, and hot-reload | — |
| `routing-deployment` repo (optional) | In emergency scenarios the cloud Kubernetes path may be updated separately | — |

## Steps

1. **Engineer confirms emergency**: The `confirm_emergency_deploy` Gradle task prints a warning explaining that emergency deploys bypass safety checks, place a lock file, and should only be used when the standard mechanism cannot be reached. The engineer must type `proceed` at the prompt to continue.
   - From: `On-call Engineer`
   - To: Gradle console prompt
   - Protocol: direct (interactive)

2. **Bundle config**: The Gradle `bundle` task (a `Tar` task) compresses the `src/` directory into `build/routing-config.tgz`.
   - From: `Gradle`
   - To: local filesystem (`build/routing-config.tgz`)
   - Protocol: direct (local)

3. **Place lock files on all app nodes**: Gradle SSH plugin connects to all app nodes (all roles tagged `app` in `build.gradle`) and executes `touch /var/groupon/routing-config-2/lock` on each.
   - From: `Gradle SSH plugin`
   - To: `routing-app[1-10].snc1`, `routing-app[1-10].sac1`, `routing-app[1-10].dub1`
   - Protocol: SSH

4. **Copy config bundle to app nodes**: Gradle SSH plugin creates a timestamped release directory (`/var/groupon/routing-config-2/releases/<YYYYMMDDHHMMSS>/`), copies `build/routing-config.tgz` to each node, extracts it, removes the archive, and links the previous release as `PREVIOUS`.
   - From: `Gradle SSH plugin`
   - To: All on-prem app nodes
   - Protocol: SSH / SFTP

5. **Atomically update `current` symlink**: Gradle SSH plugin runs `ln -nsf <releaseDir> /var/groupon/routing-config-2/current` on each node to make the new release active.
   - From: `Gradle SSH plugin`
   - To: All on-prem app nodes
   - Protocol: SSH

6. **Hot-reload routing config**: Gradle SSH plugin executes `curl --silent -X POST localhost:9001/config/routes/reload` on each app node (`ignoreError: true` — failures are non-blocking).
   - From: `Gradle SSH plugin` (via SSH exec)
   - To: Routing service runtime on each node (`localhost:9001`)
   - Protocol: HTTP (localhost)

7. **Post-deploy PR comment** (if commit was a merge): `update_pull_request_thread()` posts a comment to the associated GitHub pull request.
   - From: `Gradle` (Groovy script)
   - To: `GitHub Enterprise` API
   - Protocol: HTTPS REST

8. **Engineer pushes changes to master**: After the emergency is resolved, the engineer ensures all emergency changes are committed and pushed to the `master` branch so the standard pipeline can sync the cloud Kubernetes deployments.
   - From: `On-call Engineer`
   - To: `GitHub Enterprise`
   - Protocol: Git push

9. **Engineer unlocks app nodes**: The engineer runs `./gradlew unlock` (which also requires a confirmation prompt) to remove the lock files from all app nodes, restoring normal deploy capability.
   - From: `Gradle SSH plugin`
   - To: All on-prem app nodes
   - Protocol: SSH (`rm -f /var/groupon/routing-config-2/lock`)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Engineer does not type `proceed` | `GradleException("Warning not accepted")` thrown | Deploy aborted; no changes made |
| SSH connection fails to one or more nodes | Gradle SSH task throws exception for that node | Partial deploy; other nodes may have received updated config; lock files may be present on some but not all nodes |
| Hot-reload HTTP call fails | `ignoreError: true` — non-blocking | Routing service may continue serving old config until next reload or restart |
| Lock file already exists (from prior emergency) | Normal `deploy` task throws `GradleException("Emergency lock file exists")` | Normal deploys blocked; must resolve with `./gradlew unlock` |
| Cloud Kubernetes overlays not updated | Not handled by this flow | Cloud regions continue serving old config; engineer must push to `master` and wait for standard pipeline |

## Sequence Diagram

```
On-call Engineer -> Gradle: ./gradlew emergency_deploy
Gradle -> On-call Engineer: WARNING prompt (type "proceed" to continue)
On-call Engineer --> Gradle: "proceed"
Gradle -> local filesystem: bundle src/ into build/routing-config.tgz
Gradle SSH plugin -> routing-app nodes (all DCs): SSH: touch /var/groupon/routing-config-2/lock
Gradle SSH plugin -> routing-app nodes (all DCs): SSH: mkdir releases/<timestamp>
Gradle SSH plugin -> routing-app nodes (all DCs): SFTP: put routing-config.tgz
Gradle SSH plugin -> routing-app nodes (all DCs): SSH: tar -xzf + rm archive
Gradle SSH plugin -> routing-app nodes (all DCs): SSH: ln -nsf <releaseDir> current
Gradle SSH plugin -> routing-app nodes (all DCs): SSH: curl -X POST localhost:9001/config/routes/reload
On-call Engineer -> GitHub Enterprise: git push master (commit emergency changes)
On-call Engineer -> Gradle: ./gradlew unlock
Gradle -> On-call Engineer: WARNING prompt (type "proceed" to continue)
On-call Engineer --> Gradle: "proceed"
Gradle SSH plugin -> routing-app nodes (all DCs): SSH: rm -f /var/groupon/routing-config-2/lock
```

## Related

- Architecture dynamic view: `dynamic-routingConfigProduction`
- Related flows: [Config Change and Deployment](config-change-deployment.md), [Route Validation (Pre-Merge)](route-validation-pre-merge.md)
- Source: `build.gradle` (`emergency_deploy`, `unlock`, `do_deploy` tasks)
