---
service: "routing_config_production"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `POST localhost:9001/config/routes/reload` | http | On deploy | — |
| `./gradlew validate` (CI) | exec | Every CI run | CI job timeout |
| `bin/check-routes <URL>` | exec (manual) | On-demand (pre-merge) | — |

> Continuous health monitoring for the routing service runtime is managed by the routing service itself, not by this config repo. Operational procedures for the routing service runtime should be defined by the service owner.

## Monitoring

### Metrics

> No evidence found in codebase.

Metrics for traffic routing correctness (routing errors, backend timeouts, 5xx rates) are owned by the routing service runtime, not this config repo.

### Dashboards

> No evidence found in codebase.

### Alerts

> No evidence found in codebase.

## Common Operations

### Add or modify a routing rule

1. Create a feature branch from `master`.
2. Edit the relevant `.flexi` file under `src/applications/` (or create a new one and include it in `src/applications/index.flexi`).
3. Run `./bin/check-routes <test-URLs>` on both your branch and `master` to confirm the routing behavior change.
4. Open a pull request. Include `check-routes` output from both branches in the PR description (text only, no screenshots).
5. Request review in the Routing team chat room.
6. After merge, the Jenkins pipeline automatically validates, builds, publishes, and deploys.

### Validate config locally

```bash
docker-compose -f .ci/docker-compose.yml run -T test
```

This runs `./gradlew validate` inside the CI container.

### Check route resolution for a URL

```bash
./bin/check-routes https://www.groupon.com/checkout/cart
./bin/check-routes https://www.groupon.com/deals/some-deal-permalink
```

Output shows which destination and route group matches each URL.

### Emergency deploy (bypasses safety checks)

```bash
./gradlew emergency_deploy
```

This places a `lock` file on all app nodes to prevent normal deploys. After the emergency is resolved, run:

```bash
./gradlew unlock
```

Ensure all emergency changes are pushed to `master` before unlocking.

### Restart / hot-reload routing config on on-prem nodes

The routing service automatically receives a hot-reload trigger after a standard deploy:

```bash
curl --silent -X POST localhost:9001/config/routes/reload
```

This is executed on each app node during the Gradle deploy task.

### Scale Up / Down

> Scaling is managed externally by the routing service infrastructure team. This config repo does not control node counts.

### Database Operations

> Not applicable — this service is stateless and has no database.

## Troubleshooting

### CI validation fails after a Flexi change

- **Symptoms**: `./gradlew validate` exits non-zero in the Jenkins pipeline; PR check fails
- **Cause**: Flexi DSL syntax error, invalid route pattern, or unresolvable destination reference in a `.flexi` file
- **Resolution**: Run `docker-compose -f .ci/docker-compose.yml run -T test` locally to see the specific error. Fix the offending `.flexi` file. Run `./bin/check-routes` to verify the fix before pushing.

### Route resolves to wrong destination in production

- **Symptoms**: Traffic for a specific URL path is hitting an unexpected backend service; reported via monitoring or user complaints
- **Cause**: Route group ordering or pattern specificity issue in the Flexi config; a more general pattern matches before the intended specific one
- **Resolution**: Use `./bin/check-routes <affected-URL>` on `master` to reproduce. Identify the conflicting route group in `src/applications/`. Adjust pattern specificity (use `=` exact match instead of `^` prefix match) or reorder includes in `index.flexi`. Open a PR with `check-routes` output evidence.

### Emergency lock prevents normal deployment

- **Symptoms**: Normal `./gradlew deploy` fails with "Emergency lock file exists"
- **Cause**: A previous `emergency_deploy` left a `lock` file on the app nodes
- **Resolution**: Confirm that all emergency changes are committed to `master`, then run `./gradlew unlock` to remove lock files from all nodes.

### Docker image push fails during Publish stage

- **Symptoms**: Jenkins `Publish` stage fails; image not available in `docker-conveyor.groupondev.com`
- **Cause**: Docker registry unavailability or authentication issue
- **Resolution**: Retry the Jenkins build. If persistent, check `docker-conveyor.groupondev.com` registry health with the platform/infrastructure team.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Routing config deployed incorrectly — widespread traffic misrouting affecting production | Immediate | Routing Service Devs (routing-service-devs@groupon.com) + SRE |
| P2 | Subset of routes misrouting; specific feature or country affected | 30 min | Routing Service Devs |
| P3 | CI validation failure blocking a non-urgent config change | Next business day | Routing Service Devs |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `nexus-dev.snc1` (Maven repo) | Gradle build succeeds | No automated fallback; fix Nexus or use local Maven cache |
| `github.groupondev.com` (GitHub Enterprise) | CI pipeline can clone and push | No automated fallback; manual intervention required |
| `docker-conveyor.groupondev.com` (Docker registry) | `docker push` succeeds in Jenkins | No automated fallback; retry or use alternative publish path |
| On-prem app nodes (`routing-app[1-10].*`) | SSH connectivity in Gradle deploy task | Routing service continues serving the previously deployed config until reload succeeds |
