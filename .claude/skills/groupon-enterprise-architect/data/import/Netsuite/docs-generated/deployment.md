---
service: "Netsuite"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "oracle-netsuite-saas"
environments: [sandbox, production]
---

# Deployment

## Overview

The NetSuite customizations are deployed directly to Oracle NetSuite's SaaS platform — there are no containers, Kubernetes manifests, Dockerfiles, or traditional infrastructure to manage. SuiteScript files (`.js`) are uploaded to the NetSuite File Cabinet under `SuiteScripts/` and registered as Script records within NetSuite. Each script has one or more Deployment records that attach it to specific forms, record types, or schedules. Hosting is explicitly not managed via ops-config host YAMLs (`hosting_configured_via_ops_config: false` in `.service.yml`).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | NetSuite is a multi-tenant SaaS platform; no Dockerfile exists |
| Orchestration | Oracle NetSuite SaaS | Scripts are deployed as NetSuite Script and Script Deployment records |
| Load balancer | Oracle NetSuite (managed) | NetSuite handles all load balancing internally |
| CDN | Oracle NetSuite (managed) | NetSuite handles CDN and edge internally |
| File storage | NetSuite File Cabinet | Scripts stored under `/SuiteScripts/` path within each instance's File Cabinet |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Production (GOODS/NS2) | Live Goods marketplace ERP instance | Oracle cloud (multi-region) | `https://system.netsuite.com` |
| Production (NAM/NS3) | Live North America ERP instance | Oracle cloud (multi-region) | `https://system.netsuite.com` |
| Production (INTL/NS1) | Live International ERP instance | Oracle cloud (multi-region) | `https://system.netsuite.com` |
| Sandbox (GOODS) | Non-production testing environment for GOODS customizations | Oracle cloud | NetSuite sandbox account |
| Sandbox (NAM) | Non-production testing environment for NAM customizations | Oracle cloud | NetSuite sandbox account |
| Sandbox (INTL) | Non-production testing environment for INTL customizations | Oracle cloud | NetSuite sandbox account |

## CI/CD Pipeline

- **Tool**: Manual / SuiteCloud CLI
- **Config**: `GOODS/package.json` (SuiteCloud unit testing only)
- **Trigger**: Manual upload via SuiteCloud CLI or NetSuite UI; no automated deployment pipeline detected in this repository

### Pipeline Stages

1. **Unit Test**: Run `npm test` locally using jest + `@oracle/suitecloud-unit-testing` harness against `GOODS/__tests__/`
2. **Script Review**: Script Approval Creator / Approver / Promoter Suitelets (`Script Approval Creator.js`, `Script Approval Approver.js`, `Script Approval Promoter.js`) provide an in-NetSuite approval workflow for script changes
3. **Deploy to Sandbox**: Upload JS files to sandbox File Cabinet via SuiteCloud CLI or NetSuite UI; update Script Deployment records
4. **Deploy to Production**: Upload JS files to production File Cabinet; update Script Deployment records; activate deployment

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Oracle NetSuite manages server scaling; not configurable | N/A |
| Governance (CPU equivalent) | Scripts monitor remaining governance units and reschedule via `reschedScript(MAX_USAGE)` | `MAX_USAGE = 500` units threshold |
| Scheduled script runtime | Scripts self-terminate and reschedule after 45 minutes to avoid the NetSuite 60-minute hard limit | `maxTime = 45` minutes |

## Resource Requirements

> Not applicable. Oracle NetSuite manages all resource allocation. Script governance limits (1,000 units for most script types) are the effective resource constraint per execution, not memory or CPU limits.
