---
service: "cloud-jenkins-main"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /metrics/<METRICS_KEY>/ping` | HTTP | On deployment (smoke test); ad-hoc | — |
| `GET /metrics/<METRICS_KEY>/healthcheck` | HTTP | On deployment (smoke test); ad-hoc | — |
| Smoke test suite (`smoke-tests/test_jenkins.py`) | exec | Post-deployment | 150 retries x 3s = 450s max wait |
| `server.wait_for_normal_op(25)` | exec | Polled during smoke tests | 25s per attempt; 50 attempts |

### Healthcheck response fields validated by smoke tests

- `plugins.healthy == true`
- `disk-space.healthy == true`
- `temporary-space.healthy == true`
- `thread-deadlock.healthy == true`

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `cicd.*` (Wavefront namespace) | Various | Controller and pipeline metrics published via Telegraf to Wavefront on port 8186 | See Wavefront dashboard |
| `cloud_jenkins_main_start` | Wavefront event | Marks controller startup; annotated with service, region, env, atom | — |
| EFS total size | gauge | Monitored via AWS console; used to validate EFS backup restore completeness | Must match pre-restore `size_in_bytes` |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Jenkins Resources | Wavefront | `https://groupon.wavefront.com/dashboards/jenkins-resources` |
| Metrics (cicd. namespace) | Wavefront | `https://groupon.wavefront.com/metrics#_v01(q:cicd.)` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| PagerDuty incident | Controller unreachable or critical pipeline failure | P1/P2 | Page on-call via PagerDuty service `PCDVZJN` |
| Slack `#cj-dev` notification | Master-branch pipeline failure (`Jenkinsfile` post block) | P2 | Investigate build URL linked in message |

## Common Operations

### Restart Service / Redeploy Jenkins Instance

1. Ensure you have `aws-okta` configured with access to `internal-prod/admin`.
2. Run:
   ```shell
   cd terraform/environments/
   git checkout master && git pull
   aws-okta exec internal-prod/admin -- make apply-all
   ```
3. Monitor smoke tests automatically triggered by the deployment pipeline.
4. Verify healthcheck endpoint returns `pong` and all healthcheck fields are `true`.

### Scale Up / Down

- Agent pool scaling is controlled automatically by the Amazon EC2 plugin based on build queue depth.
- To change minimum spare agents or instance cap, update `NUM_AVAILABLE_DEFAULT_AGENTS` or `NUM_OCQ_AGENTS` in the Terraform variables and run `make apply-all`.
- macOS and Android static nodes are managed via `S06AndroidNodes.groovy` and `S07MacOSNodes.groovy`; changes require a controller restart.

### Database Operations

- Jenkins does not use a relational database.
- Jenkins home data is stored on EFS. To restore EFS from a backup, follow the procedure in `doc/efs_restore.md` (summarised below):

**EFS Restore (abbreviated)**
1. Retrieve current EFS file-system ID and creation-token from Terraform state.
2. Retrieve backup vault name from Terraform state.
3. Log into AWS console and find the desired recovery point ARN.
4. Shut down Jenkins to quiesce EFS writes.
5. Delete the current EFS file system.
6. Run `aws backup start-restore-job` with the recovery point ARN and original creation-token.
7. Wait for restore job status to reach `completed` and verify EFS total size.
8. Import the new EFS to Terraform state, then run `make apply-all` to re-attach it.

### Unlock git-crypt (for local operations)

```shell
gpg --import $GPG_KEY
gpg --import-ownertrust $GPG_OWNER_TRUST
echo 'allow-preset-passphrase' >> ~/.gnupg/gpg-agent.conf
gpgconf --kill gpg-agent
/usr/lib/gnupg2/gpg-preset-passphrase --preset --passphrase $GPG_PASS $GPG_KEYGRIP
git crypt unlock
```

### Terraform State Lock — Manual Release

If a Terraform operation is interrupted and the DynamoDB lock is not released:
1. Copy the `Path` from the lock error message (e.g. `rapt-cloud-jenkins-787676117833/main/grpn-internal-prod/us-west-2/cloud-jenkins/main/jenkins/terraform.tfstate`).
2. Navigate to [DynamoDB lock tables](https://us-west-2.console.aws.amazon.com/dynamodbv2/home?region=us-west-2#tables).
3. Query by `Path` and delete the lock item.
4. Re-run the Terraform operation.

## Troubleshooting

### Builds queuing indefinitely / no agents available

- **Symptoms**: Build queue grows; agents are not provisioning; agent pool shows 0 available
- **Cause**: AWS EC2 API quota exceeded; AMI not available; security group or subnet misconfiguration; credential expiry for agent launch
- **Resolution**: Check Amazon EC2 plugin cloud logs in Jenkins UI; verify IAM credentials in JCasC; check `AGENT_INSTANCE_PROFILE_ARN` and `AGENT_SG_NAME` values in Terraform; run `make apply-all` to refresh configuration

### Controller not starting (boot failure hook fires)

- **Symptoms**: `boot-failure.groovy.d/S01WavefrontEventClose.groovy` fires; controller does not reach `NORMAL_OP` state
- **Cause**: JCasC validation failure; missing secret in AWS Secrets Manager; EFS mount failure
- **Resolution**: Check controller logs via the logging stack (`filebeat-cicd_cloud_jenkins_main--*` index); verify all secret paths exist in AWS Secrets Manager; verify EFS mount target is healthy in AWS console

### Dangling EC2 agents not being cleaned up

- **Symptoms**: Orphaned EC2 instances visible in AWS console tagged `cj-agent-production-main-*`; not appearing in Jenkins controller node list
- **Cause**: Agent Cleanup Lambda not running; Lambda execution error; controller API unreachable from Lambda
- **Resolution**: Check Lambda execution logs in the logging stack; verify EventBridge schedule is active; check Lambda IAM role permissions; verify controller HTTPS endpoint is reachable from the Lambda VPC

### GitHub webhook not triggering jobs (`/ghe-seed/` endpoint)

- **Symptoms**: Pushes to GHE repositories do not trigger Jenkins pipelines; 403 response from `/ghe-seed/`
- **Cause**: CSRF exclusion not functioning; `X-Hub-Signature` mismatch; `githubapp-secret` credential mismatch with webhook configuration
- **Resolution**: Run smoke test `test_build_plugin_endpoint_for_csrf`; verify `githubapp-secret` in JCasC credentials matches the webhook secret configured in GitHub Enterprise; check controller logs for signature validation errors

### EFS data loss / corruption

- **Symptoms**: Jenkins job configurations missing; build history lost; plugin configs reset
- **Cause**: Accidental EFS deletion; file system corruption
- **Resolution**: Follow the full EFS restore procedure in `doc/efs_restore.md`; requires planned downtime

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Controller completely down — no builds can execute | Immediate | CICD team via PagerDuty service PCDVZJN; Slack `#cicd` |
| P2 | Degraded — some agent types unavailable or slow | 30 min | CICD team via Slack `#cicd`; PagerDuty if unresolved |
| P3 | Minor — individual job failures; metrics gaps | Next business day | CICD team via email cicd@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| GitHub Enterprise | `000-jenkins-tests/git-client` canary job checks `git ls-remote` | Jobs queue; cannot checkout code |
| AWS EC2 (agent provisioning) | `000-jenkins-tests/ec2-label` canary job checks agent provisioning | Builds queue indefinitely |
| AWS EFS | AWS console EFS health; controller startup success | Controller fails to start; restore from AWS Backup |
| Wavefront | Wavefront dashboard availability | Metrics and lifecycle events not recorded; no build impact |
| Slack | Slack API status | Failure notifications silently dropped; no build impact |
| SonarQube | `sonarqube` installation configured in tool.yaml | Analysis steps fail or skip; build impact depends on job config |
