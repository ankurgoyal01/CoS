---
service: "routing_config_production"
title: "Route Validation (Pre-Merge)"
generated: "2026-03-03"
type: flow
flow_name: "route-validation-pre-merge"
flow_type: synchronous
trigger: "Developer runs bin/check-routes or CI runs ./gradlew validate"
participants:
  - "Developer"
  - "api-proxy-cli Docker image"
  - "grout Gradle plugin"
  - "routing-config-ci Docker container"
architecture_ref: "dynamic-routingConfigProduction"
---

# Route Validation (Pre-Merge)

## Summary

Before a routing config change is merged to `master`, two complementary validation mechanisms confirm correctness: manual URL evaluation via `bin/check-routes` (developer-run) and automated DSL compilation via `./gradlew validate` (CI-run). Together these catch both syntactic errors and semantic routing mismatches before any change reaches production. PR policy requires that `check-routes` output from both the feature branch and `master` be included in the pull request description.

## Trigger

- **Type**: manual (developer-initiated) and api-call (CI webhook)
- **Source**: Developer executing `./bin/check-routes` locally; or Jenkins CI running `./gradlew validate` on PR push
- **Frequency**: On-demand per change; automated on every push to any branch

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Developer | Runs `bin/check-routes` against test URLs on both branches; reviews output before submitting PR | — |
| `api-proxy-cli` Docker image (`docker.groupondev.com/groupon-api/api-proxy-cli:latest`) | Evaluates URL routing decisions against the compiled Flexi config directory | `routingConfigProduction` |
| `grout` Gradle plugin (`com.groupon.grout:grout-tools-gradle:1.4.2`) | Compiles and validates the full Flexi DSL config; fails on syntax errors | `routingConfigProduction` |
| `routing-config-ci:0.4.0` Docker container | Provides the Java 1.8 + Gradle environment for CI validation | — |

## Steps

1. **Developer authors route change**: Modifies one or more `.flexi` files in `src/applications/`. Optionally runs `python render_templates.py` first if Jinja2 templates are involved.
   - From: `Developer`
   - To: Flexi source files
   - Protocol: direct (local file edit)

2. **Manual URL evaluation on feature branch**: Developer runs `./bin/check-routes <URL1> [<URL2> ...]`. The script invokes the `api-proxy-cli` Docker container, mounting `src/` as `/data`, and prints the routing decision (matched route group, destination) for each URL.
   - From: `Developer`
   - To: `api-proxy-cli` (Docker)
   - Protocol: Docker run / exec

3. **Manual URL evaluation on master**: Developer checks out `master` and repeats step 2 on the same URLs to produce a comparison baseline for the PR description.
   - From: `Developer`
   - To: `api-proxy-cli` (Docker)
   - Protocol: Docker run / exec

4. **Submit pull request**: Developer opens a PR with `check-routes` text output from both branches in the description and requests review from the Routing team.
   - From: `Developer`
   - To: GitHub Enterprise
   - Protocol: HTTPS (GitHub API)

5. **CI validates on PR push**: Jenkins CI triggers, runs `docker-compose run test` (which executes `./gradlew validate` inside `routing-config-ci:0.4.0`). The `grout` plugin compiles all included Flexi files starting from `src/main.flexi`.
   - From: `Jenkins CI`
   - To: `grout` Gradle plugin (inside `routing-config-ci` container)
   - Protocol: Docker Compose exec

6. **Validation passes or fails**: If valid, the CI check is green and the PR can be merged. If invalid (DSL syntax error, unresolvable destination, invalid pattern), `./gradlew validate` exits non-zero and the PR check fails.
   - From: `grout` Gradle plugin
   - To: `Jenkins CI` / GitHub Enterprise PR status
   - Protocol: exit code / GitHub Checks API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Flexi syntax error | `./gradlew validate` exits non-zero | CI check fails; PR cannot be merged until fixed |
| `api-proxy-cli` image not available locally | Docker pull from `docker.groupondev.com` | Script fails with Docker pull error; developer must fix Docker access |
| URL resolves to wrong destination | Visible in `check-routes` output | Developer must adjust route patterns and re-run; PR description must reflect corrected output |
| Missing include in `index.flexi` | `grout` compile step fails with unresolved reference | CI fails; developer adds the missing `include` directive |

## Sequence Diagram

```
Developer -> Flexi source files: edit routing rules
Developer -> api-proxy-cli (feature branch): ./bin/check-routes <URLs>
api-proxy-cli --> Developer: routing decision output (feature branch)
Developer -> api-proxy-cli (master): ./bin/check-routes <URLs>
api-proxy-cli --> Developer: routing decision output (master)
Developer -> GitHub Enterprise: open pull request with check-routes output
GitHub Enterprise -> Jenkins CI: webhook (PR push)
Jenkins CI -> routing-config-ci container: docker-compose run ./gradlew validate
routing-config-ci container -> grout plugin: compile all Flexi files
grout plugin --> routing-config-ci container: pass / fail
routing-config-ci container --> Jenkins CI: exit code
Jenkins CI --> GitHub Enterprise: PR check status (pass / fail)
```

## Related

- Architecture dynamic view: `dynamic-routingConfigProduction`
- Related flows: [Config Change and Deployment](config-change-deployment.md)
