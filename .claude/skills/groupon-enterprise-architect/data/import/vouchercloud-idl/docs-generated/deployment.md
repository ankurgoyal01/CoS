---
service: "vouchercloud-idl"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "ecs"
environments: [feature, staging, release, us-release]
---

# Deployment

## Overview

Vouchercloud IDL is deployed on AWS Elastic Beanstalk (Windows Server / IIS) — not containerised with Docker. The Restful API and Web applications each run in their own Elastic Beanstalk environment with an Application Load Balancer (ALB). Credentials are loaded at instance boot via PowerShell scripts in `.ebextensions`. Deployment is managed via the `.aws/` option files and `.ebextensions/` configuration scripts committed to the repository. Multiple environments exist: Feature (dev/sprint), Staging, Release (EU production), and US-West-1 Release (US production).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Compute | AWS Elastic Beanstalk (Windows) | IIS / .NET Framework 4.7.2 App Pool |
| Load balancer | AWS ALB (Application Load Balancer) | HTTPS port 443, TLS 1.2 policy (`ELBSecurityPolicy-TLS-1-2-2017-01`) |
| CDN | > No evidence found in codebase | — |
| Orchestration | AWS Elastic Beanstalk | Environment option files in `.aws/Release/`, `.aws/Staging/`, `.aws/Feature/` |
| Secrets | AWS Secrets Manager | Fetched at boot via PowerShell in `.ebextensions/` |
| Monitoring | AWS CloudWatch + Elastic APM | Enhanced health reporting enabled; APM tracing to `stable-apm.us-central1.logging.stable.gcp.groupondev.com` |
| Logging | NLog + Papertrail + Elastic Common Schema | Log files at `C:\LogFiles\VoucherCloudApi\`; forwarded to Papertrail (`logs2.papertrailapp.com:26646`) and ECS format |
| Access logs | AWS S3 (`idl-api-elb-logs`) | ALB access logs stored in S3 |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Feature | Development / sprint testing | eu-west-1 | Per-feature base URLs (e.g., `https://api.gb.v3.idldev.net`) |
| Staging | Integration testing | eu-west-1 | `https://staging-restfulapi.vouchercloud.com` |
| Release | EU production | eu-west-1 | `https://restfulapi.vouchercloud.com` |
| US Release | US production | us-west-1 | `https://restfulapi.vouchercloud.com` (US-West-1 hosted) |

## CI/CD Pipeline

- **Tool**: > No evidence found in codebase of a GitHub Actions or CI pipeline configuration file in this repository. Build and deployment are managed externally.
- **Config**: `Build.proj` (MSBuild project file); `.aws/*.opt` files for EB environment configuration
- **Trigger**: Manual deployment via AWS Elastic Beanstalk CLI or internal deployment tooling

### Pipeline Stages

1. **Build**: MSBuild compiles all projects; NuGet packages restored
2. **Unit Tests**: `IDL.Api.Restful.UnitTests`, `IDL.Api.Vc.UnitTests`, `IDL.Web.Vc.UnitTests`, `IDL.Web.WhiteLabel.UnitTests`, `IDL.Api.Client.MessageBus.UnitTests` executed
3. **Automated Tests**: `IDL.Api.Restful.AutomatedTests` run against staging (`https://staging-restfulapi.vouchercloud.com`)
4. **Package**: Web deploy package created from `IDL.Api.Restful` project
5. **Deploy**: AWS EB deployment with environment-specific `.opt` file and `.ebextensions/` scripts applied
6. **Boot Init**: PowerShell init script fetches credentials from AWS Secrets Manager and sets machine environment variables
7. **Health Check**: ALB verifies `/restful-api-heartbeat.html` responds HTTP 200

## Scaling

### Restful API (`continuumRestfulApi`)

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Fixed (Release) / Auto-scaled (Feature/Staging) | Release: min=4, max=4 (`t3.large`); Staging: time-based scale-down to 0 at 20:00 UTC weekdays, scale-up to 1 at 06:00 UTC |
| Trigger metric | Latency-based (Release) | Upper threshold: 1 s; lower: 0.5 s; cooldown 360 s |

### Web (`continuumVcWebSite`)

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Fixed | Release: min=3, max=3 (`r5.large`) |
| Trigger metric | CPUUtilization | Upper: 50%, lower: 20%; period 5 min |

## Resource Requirements

### Restful API (Release)

| Resource | Request | Limit |
|----------|---------|-------|
| Instance type | t3.large | t3.large |
| Root volume | 40 GB gp3 | 40 GB gp3 |
| CPU / Memory | EC2 instance defaults | EC2 instance defaults |

### Web (Release)

| Resource | Request | Limit |
|----------|---------|-------|
| Instance type | r5.large | r5.large |
| Root volume | 40 GB gp3 | 40 GB gp3 |
