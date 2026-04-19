---
service: "tripadvisor-api"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "vm"
environments: [staging, production]
---

# Deployment

## Overview

The Getaways Affiliate API is deployed as a Java WAR file running inside Apache Tomcat on bare-metal/VM hosts (hostclass `afl-ta-api`) across three Groupon colos: snc1 (US primary), sac1 (US secondary), and dub1 (EMEA). Deployment is orchestrated by Jenkins CI using the `javaPipeline` shared library and Capistrano (`cap`) for host-level deploy operations. Releases are promoted sequentially: staging -> production_snc1 -> production_sac1 -> production_dub1. Each production step requires manual approval. A Docker image (`docker.groupondev.com/jtier/dev-java8-maven:2020-09-22-887e4f1`) is used for CI build only, not for runtime.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Build image | Docker | `.ci/Dockerfile` — `docker.groupondev.com/jtier/dev-java8-maven:2020-09-22-887e4f1` |
| Packaging | Maven WAR | Built artifact uploaded to Nexus at `http://nexus-app1-dev.snc1/content/repositories/releases` |
| Runtime | Apache Tomcat | Managed by `gpn-mgmt.py` / `init.d/apache_tomcat_ta-api` |
| Load balancer | VIP (internal) | `afl-ta-app-vip.{snc1,sac1,dub1}` |
| External URL | Groupon API gateway | `http://api.groupon.com/getaways/v2/affiliates` (US), `http://api.groupon.de/getaways/v2/affiliates` (DE/EMEA) |
| Status port | 8080 | `status_endpoint.port` in `.service.yml` |
| Status path | `/resources/status.json` | SHA key: `status/runningGitSha` |

## Environments

| Environment | Purpose | Region | Internal URL | External URL |
|-------------|---------|--------|-------------|-------------|
| staging | Pre-production validation | US / snc1 | `http://ta-availability-staging-vip.snc1` | `https://ta-availability-staging.groupondev.com` |
| production_snc1 | US production (primary) | US / snc1 | `http://afl-ta-app-vip.snc1` | `http://api.groupon.com/getaways/v2/affiliates` |
| production_sac1 | US production (secondary) | US / sac1 | `http://afl-ta-app-vip.sac1` | `http://api.groupon.com/getaways/v2/affiliates` |
| production_dub1 | EMEA production | EMEA / dub1 | `http://afl-ta-app-vip.dub1` | `http://api.groupon.de/getaways/v2/affiliates` |

Host naming pattern:
- Staging: `afl-ta-appN-staging.snc1` (2 hosts)
- Production: `afl-ta-appN.snc1` (2 hosts)

## CI/CD Pipeline

- **Tool**: Jenkins (`javaPipeline` shared library `java-pipeline-dsl@latest-2`)
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `master` branch triggers a promotable release build
- **Fork sync**: After release, automatically rebases the `travel/tripadvisor-api` fork via SSH (`svcdcos-ssh` credentials)
- **Artifact**: Maven WAR published to Nexus
- **Slack notifications**: `CF9BSJ5GX` (getaways channel)

### Pipeline Stages

1. **Build**: Maven compile and package inside Docker build container (`.ci/docker-compose.yml`)
2. **Unit Tests**: Maven Surefire runs TestNG and JUnit/Spock tests
3. **Integration Tests**: Maven Failsafe starts Jetty 9.4, runs Cucumber stories
4. **Release**: Maven Release Plugin publishes WAR to Nexus (only on `master`; `deploy` goal)
5. **Deploy to staging**: Capistrano — `bundle exec cap snc1 staging deploy:app_servers` (automatic after release)
6. **Deploy to production_snc1**: Capistrano — `bundle exec cap snc1 production deploy:app_servers` (manual approval required)
7. **Deploy to production_sac1**: Capistrano — `bundle exec cap sac1 production deploy:app_servers` (manual approval required)
8. **Deploy to production_dub1**: Capistrano — `bundle exec cap dub1 production deploy:app_servers` (manual approval required)
9. **Fork sync**: Rebase `travel/tripadvisor-api:master` from `AFL/tripadvisor-api:master`

### Deployment Checklist (from OWNERS_MANUAL.md)

1. Create Prod-Ops Calendar entry
2. Create Logbook ticket
3. Notify Production Operations Hipchat
4. Suspend Nagios alerts through Thruk
5. Run Capistrano deploy: `cap snc1_prod deploy:app_servers USER=john.smith`
6. Smoke tests run automatically after each host deployment
7. Revive Nagios alerts through Thruk
8. Notify Production Operations Hipchat on completion
9. Close Logbook ticket

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Manual — add hosts via Groupon Central and Config Wizard | 2 hosts per colo (staging and production) |
| JVM Memory | Configured on Tomcat JVM | Heap dump on OOM enabled; GC logs at `/var/groupon/apache-tomcat/logs/gc/gc.log` |

## Resource Requirements

> Deployment configuration for CPU/memory limits managed externally via Config Wizard hostclass (`afl-ta-api`). Specific values not documented in-repo.
