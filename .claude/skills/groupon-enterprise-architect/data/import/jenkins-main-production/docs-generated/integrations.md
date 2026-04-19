---
service: "cloud-jenkins-main"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 6
internal_count: 1
---

# Integrations

## Overview

Cloud Jenkins Main has six external system dependencies: GitHub Enterprise (source), Artifactory (artifacts), AWS (compute/infrastructure), Wavefront (metrics), Slack (alerts), and SonarQube (code quality). One internal dependency exists — the `continuumJenkinsAgentCleanupLambda` container queries the controller via HTTPS to reconcile agent state. Credentials for all external systems are loaded from AWS Secrets Manager at controller startup via JCasC secret interpolation.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GitHub Enterprise | HTTPS / Git | Clones source repositories; reads PR metadata; receives push webhooks | yes | `githubEnterprise` |
| Artifactory | HTTPS | Pulls build dependencies; pushes build artifacts and Docker images | yes | `artifactory` |
| AWS (EC2, Lambda, EFS, S3, DynamoDB, EventBridge, Backup) | AWS SDK / CLI | Provisions compute agents, persists Jenkins home via EFS, manages infrastructure via Terraform | yes | `cloudPlatform` |
| Wavefront | HTTPS (REST API) | Publishes controller lifecycle events and pipeline metrics | no | `metricsStack` |
| Slack | HTTPS (Slack API) | Sends pipeline failure and deployment alerts to `#cj-dev` | no | `slack` |
| SonarQube | HTTPS | Runs static code analysis as a pipeline build step | no | — |

### GitHub Enterprise Detail

- **Protocol**: HTTPS (REST API `https://github.groupondev.com/api/v3`), Git over HTTPS, SAML webhook
- **Base URL / SDK**: `https://github.groupondev.com/api/v3` (configured in `casc/unclassified.yaml` under `githubpluginconfig`)
- **Auth**: API token (`svc_dcos_token`), SSH key (`svcdcos-ssh`), GitHub App PEM key (`githubapp-pem`) and webhook secret (`githubapp-secret`)
- **Purpose**: Source for all pipeline definitions (Jenkinsfiles); webhook source for the `/ghe-seed/` endpoint that seeds pipeline jobs on push
- **Failure mode**: Pipeline job triggers stall; no new builds can be started until connectivity is restored; existing running builds are unaffected
- **Circuit breaker**: No

### Artifactory Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: `docker.groupondev.com` (Docker registry); Artifactory NPM/Maven proxy endpoints used by pipeline build steps
- **Auth**: NLM credentials (`NLM_NPM_USERNAME`, `NLM_NPM_PASSWORD_BASE64`) for NPM; SSH/token for other artifact types
- **Purpose**: Provides build-time dependency resolution and stores compiled artifacts and Docker images produced by pipelines
- **Failure mode**: Build steps that pull dependencies or push artifacts fail; pipelines report FAILURE
- **Circuit breaker**: No

### AWS Detail

- **Protocol**: AWS SDK / CLI (via `aws-okta`, instance profiles, and multiple IAM user access keys)
- **Base URL / SDK**: AWS SDK for Java (embedded in Jenkins Amazon EC2 plugin); `aws-okta` for human operators
- **Auth**: EC2 instance profile for controller; per-account IAM access keys stored as JCasC credentials for multi-account agent provisioning (internal-prod, internal-stable, gensandbox1, gensandbox2, edwprod, edwstable, edwsandbox, conveyorsandbox, conveyorstable, dse-dev, mta-dev, logging-dev, recreate-dev, security-dev, netops-dev, devcloudcore)
- **Purpose**: EC2 agent provisioning; EFS for persistent home; S3+DynamoDB for Terraform state; AWS Backup for EFS recovery; AWS Device Farm for mobile testing; EventBridge for Lambda scheduling
- **Failure mode**: Agent provisioning fails; builds queue indefinitely; infrastructure changes cannot be applied
- **Circuit breaker**: No

### Wavefront Detail

- **Protocol**: HTTPS (REST API `https://groupon.wavefront.com/api/v2/event`)
- **Base URL / SDK**: `https://groupon.wavefront.com` (direct HTTP call from Groovy init hooks); Telegraf agent on port 8186 for pipeline metrics
- **Auth**: Bearer token (hardcoded in `S01AddWavefrontEvent.groovy`) for event API; Telegraf agent is co-located
- **Purpose**: Records controller startup/shutdown lifecycle events; provides metrics dashboard at `https://groupon.wavefront.com/dashboards/jenkins-resources`
- **Failure mode**: Metrics and lifecycle events are not recorded; no operational impact on pipeline execution
- **Circuit breaker**: No

### Slack Detail

- **Protocol**: HTTPS (Slack Notifier plugin)
- **Base URL / SDK**: Slack API (`teamDomain: groupon`); configured in `casc/unclassified.yaml`
- **Auth**: Bot token (`slack-token` credential)
- **Purpose**: Sends build failure notifications to `#cj-dev` when a master-branch pipeline fails
- **Failure mode**: Failure alerts are silently dropped; no operational impact on pipeline execution
- **Circuit breaker**: No

### SonarQube Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: URL from secret `${/jenkins/sonarqube/url}`
- **Auth**: SonarQube server integration configured via JCasC `sonarGlobalConfiguration`
- **Purpose**: Static analysis executed as an optional build wrapper step in applicable pipelines
- **Failure mode**: Analysis step fails or is skipped; pipeline result depends on job configuration
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Jenkins Agent Cleanup Lambda | HTTPS (Jenkins REST API) | Reads controller agent/computer state before terminating dangling EC2 agents | `continuumJenkinsAgentCleanupLambda` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. All engineering teams at Groupon submit builds to this controller via GitHub Enterprise webhooks and direct web access at `https://cloud-jenkins.groupondev.com`.

## Dependency Health

- Controller startup sequence validates connectivity to GitHub Enterprise and AWS before accepting jobs.
- Smoke tests (`smoke-tests/test_jenkins.py`) verify `/metrics/<key>/ping`, `/metrics/<key>/healthcheck`, static node existence, canary job execution, and GitHub connectivity after each deployment.
- No circuit breaker or retry configuration is defined at the controller level; dependency failures propagate as pipeline failures or agent provisioning timeouts.
