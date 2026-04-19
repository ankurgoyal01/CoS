---
service: "deploybot"
title: "Deployment Validation Pipeline"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deployment-validation-pipeline"
flow_type: synchronous
trigger: "Deployment request received (webhook or API); orchestrator invokes validator before execution"
participants:
  - "deploybotOrchestrator"
  - "deploybotValidator"
  - "GitHub"
  - "Conveyor CI"
  - "ProdCAT"
  - "externalDeploybotDatabase_43aa"
architecture_ref: "dynamic-deploybot-validation"
---

# Deployment Validation Pipeline

## Summary

Before any deployment executes, deploybot runs a structured validation pipeline against the deployment request. The pipeline evaluates multiple gate types — some sequentially, some concurrently — to ensure CI builds have passed, no conflicting deployments are running, dependent environments are ready, GPROD and ProdCAT readiness gates are satisfied, manual approvals are obtained when required, and image pull validation succeeds. A deployment cannot proceed to execution until all configured gates pass.

## Trigger

- **Type**: api-call (internal)
- **Source**: `deploybotOrchestrator` invokes `deploybotValidator` after a deployment request is queued
- **Frequency**: Per deployment request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `deploybotOrchestrator` | Invokes validator; receives pass/fail result; manages state | `deploybotOrchestrator` |
| `deploybotValidator` | Evaluates each gate type and aggregates results | `deploybotValidator` |
| GitHub REST API | Provides commit CI status for build validation | external |
| Conveyor CI | Provides maintenance window status | external |
| ProdCAT | Provides production readiness check result | external |
| MySQL | Persists validation state per gate; queried for concurrent deployment detection | `externalDeploybotDatabase_43aa` |

## Steps

1. **Receives validation request**: `deploybotOrchestrator` passes deployment request details to `deploybotValidator` with the full `.deploy_bot.yml` configuration.
   - From: `deploybotOrchestrator`
   - To: `deploybotValidator`
   - Protocol: direct

2. **Runs build validation**: `deploybotValidator` queries GitHub REST API for commit status checks on the deployment commit SHA; waits until all required CI checks are passing.
   - From: `deploybotValidator`
   - To: GitHub REST API
   - Protocol: REST (HTTPS)

3. **Runs concurrent deployment check**: `deploybotValidator` queries MySQL to detect whether another deployment for the same project/environment is currently running or queued.
   - From: `deploybotValidator`
   - To: `externalDeploybotDatabase_43aa`
   - Protocol: MySQL / GORM

4. **Runs dependent environment check**: `deploybotValidator` verifies that prerequisite environments (as configured in `.deploy_bot.yml`) have been successfully deployed before proceeding.
   - From: `deploybotValidator`
   - To: `externalDeploybotDatabase_43aa`
   - Protocol: MySQL / GORM

5. **Runs GPROD validation**: `deploybotValidator` checks GPROD (general production) readiness gate; gate specifics determined by `.deploy_bot.yml` configuration.
   - From: `deploybotValidator`
   - To: `deploybotValidator` (internal or external GPROD check)
   - Protocol: REST (HTTPS) or internal

6. **Runs ProdCAT validation**: `deploybotValidator` calls ProdCAT API to verify the service's production readiness status.
   - From: `deploybotValidator`
   - To: ProdCAT
   - Protocol: REST (HTTPS)

7. **Runs manual approval gate**: If `.deploy_bot.yml` requires manual authorization for the target environment, `deploybotValidator` holds the deployment in `awaiting_authorization` state until an authorized user POSTs to `POST /deployments/{key}/authorize`.
   - From: `deploybotValidator`
   - To: `externalDeploybotDatabase_43aa` (state poll); HTTP action from authorized user
   - Protocol: MySQL poll; REST (HTTPS)

8. **Runs pull validation**: `deploybotValidator` confirms the deployment image can be pulled from Artifactory before allowing execution to begin.
   - From: `deploybotValidator`
   - To: Artifactory
   - Protocol: REST (HTTPS)

9. **Checks maintenance window**: `deploybotValidator` queries Conveyor Cloud API to verify no active maintenance window would block the deployment.
   - From: `deploybotValidator`
   - To: Conveyor CI
   - Protocol: REST (HTTPS)

10. **Records validation results**: `deploybotValidator` writes the pass/fail result for each gate to MySQL `validation_states`.
    - From: `deploybotValidator`
    - To: `externalDeploybotDatabase_43aa`
    - Protocol: MySQL / GORM

11. **Returns validation outcome**: `deploybotValidator` returns overall pass or fail to `deploybotOrchestrator`; orchestrator proceeds to execution on pass or holds/fails deployment on failure.
    - From: `deploybotValidator`
    - To: `deploybotOrchestrator`
    - Protocol: direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| CI build checks not passing | Validator polls GitHub; deployment blocked until checks pass or timeout | Deployment stays in validating state; times out if checks never pass |
| Concurrent deployment detected | Deployment queued behind running deployment or rejected | Deployment holds until preceding deployment completes |
| Dependent environment not yet deployed | Deployment blocked until dependency is resolved | Deployment stays in validating state |
| ProdCAT gate failing | Deployment blocked; operator must resolve ProdCAT issue or override | Deployment cannot proceed without ProdCAT pass |
| Manual approval not received | Deployment waits in `awaiting_authorization` state indefinitely | Requires human action via `POST /deployments/{key}/authorize` or kill |
| Image pull validation failure | Deployment fails immediately; Artifactory must have the image | Deployment marked failed; operator must fix image availability |
| Conveyor maintenance window active | Deployment blocked for duration of maintenance window | Deployment resumes after window closes |

## Sequence Diagram

```
deploybotOrchestrator -> deploybotValidator:   Start validation for deployment key
deploybotValidator    -> GitHub:               GET commit status checks (CI)
deploybotValidator    -> MySQL:                SELECT active deployments (concurrent check)
deploybotValidator    -> MySQL:                SELECT prior environment deploys (dependency check)
deploybotValidator    -> ProdCAT:              GET production readiness status
deploybotValidator    -> Conveyor CI:          GET maintenance window status
deploybotValidator    -> Artifactory:          GET image existence (pull validation)
GitHub                --> deploybotValidator:  Commit status results
ProdCAT               --> deploybotValidator:  Readiness gate result
Conveyor CI           --> deploybotValidator:  Maintenance window result
Artifactory           --> deploybotValidator:  Image validation result
deploybotValidator    -> MySQL:                INSERT/UPDATE validation_states
deploybotValidator    --> deploybotOrchestrator: Validation passed / failed
```

## Related

- Architecture dynamic view: `dynamic-deploybot-validation`
- Related flows: [Webhook-Triggered Deployment](webhook-triggered-deployment.md), [Manual API Deploy](manual-api-deploy.md), [Headless Automated Deployment](headless-automated-deployment.md)
