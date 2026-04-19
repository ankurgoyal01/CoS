---
service: "akamai"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Akamai Security Center dashboards (manual) | Manual browser check | On demand | N/A |
| `status_endpoint` | N/A | N/A | N/A |

> The status endpoint is explicitly disabled (`status_endpoint.disabled: true` in `.service.yml`). Health of the Akamai platform is assessed by the Cyber Security team through the Akamai Security Center dashboards.

## Monitoring

### Metrics

> No Groupon-owned metrics are emitted by this service. The Akamai platform provides its own security analytics within the Akamai Security Center.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Akamai Security Analytics (WAF/Bot — View 1) | Akamai Security Center | `https://control.akamai.com/apps/securitycenter?accountId=AANA-67IW3O&contractTypeId=1-2RBL&configSelector=85902&view=ng-web-security-analytics&hash=7e35214a-934c-46e0-ade2-539e460dca05` |
| Akamai Security Analytics (WAF/Bot — View 2) | Akamai Security Center | `https://control.akamai.com/apps/securitycenter?accountId=AANA-67IW3O&contractTypeId=1-2RBL&configSelector=85902&view=ng-web-security-analytics&hash=eefa4d31-993a-4b9e-9062-c4b6cf236684` |
| Akamai Security Analytics (WAF/Bot — View 3) | Akamai Security Center | `https://control.akamai.com/apps/securitycenter?accountId=AANA-67IW3O&contractTypeId=1-2RBL&configSelector=85902&view=ng-web-security-analytics&hash=55780191-f766-4beb-b637-77c755b6fd35` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| WAF false-positive spike | Legitimate traffic blocked by WAF rules | P2 | Review Akamai Security Center alerts; adjust WAF rule sensitivity or add IP/path exceptions via Akamai control plane |
| Bot management blocking legitimate crawlers | SEO or partner bots flagged as malicious | P2 | Review bot classification in Akamai Security Center; whitelist known-good user-agent strings |
| Akamai control plane unavailable | Unable to access `https://control.akamai.com` | P2 | Contact Akamai support; existing edge policies remain active |

## Common Operations

### Restart Service

> Not applicable — this service has no deployable runtime component. Akamai edge nodes are managed by Akamai, Inc.

### Scale Up / Down

> Not applicable — capacity is managed by Akamai as a SaaS vendor.

### Database Operations

> Not applicable — this service owns no data stores.

### Update WAF Rules or Bot Management Policies

1. Log in to the Akamai Security Center at `https://control.akamai.com` using Cyber Security team credentials.
2. Navigate to the relevant security configuration (config selector `85902`, account `AANA-67IW3O`).
3. Review current WAF rule set and bot management policy settings.
4. Apply changes through the Security Center UI or Akamai API.
5. Verify changes are reflected in the security analytics dashboards.
6. Notify `akamai@groupon.com` of significant policy changes.

### Update Team Contacts or SRE Notification Channels

1. Edit `.service.yml` in the repository root.
2. Update the relevant fields: `team.owner`, `team.members`, `sre.notify`, `mailing_list`.
3. Commit and merge via pull request to the `master` branch.

## Troubleshooting

### Legitimate Traffic Being Blocked

- **Symptoms**: Users report access denied or CAPTCHA challenges on Groupon consumer or merchant pages; support tickets spike
- **Cause**: WAF rules or bot management policy is over-aggressive for certain traffic patterns or user-agent strings
- **Resolution**: Review blocked request logs in Akamai Security Center dashboards; identify the triggering rule; create an exception or tune the rule sensitivity; validate with the affected traffic segment before deploying broadly

### Akamai Security Center Dashboards Inaccessible

- **Symptoms**: Engineers cannot log into `https://control.akamai.com` or dashboards fail to load
- **Cause**: Akamai platform outage, credential expiry, or account access issue
- **Resolution**: Check Akamai status page; verify account credentials with team owner (`c_anemeth`); contact Akamai support if platform-wide issue; escalate via `infosec@groupon.com`

### WAF Policy Drift (Unexpected Rule Changes)

- **Symptoms**: WAF behavior changes without a corresponding change in Akamai Security Center
- **Cause**: Automatic rule updates from Akamai's managed threat intelligence feed
- **Resolution**: Review Akamai change log in Security Center; assess impact of auto-updated rules; override specific rules if needed via the Security Center UI

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Akamai blocking all Groupon traffic (site-wide outage) | Immediate | Cyber Security team (`infosec@groupon.com`); Akamai support line |
| P2 | Significant false-positive blocking or bot management misconfiguration | 30 min | Cyber Security team (`infosec@groupon.com`) |
| P3 | Minor WAF rule adjustment, dashboard access issue | Next business day | `akamai@groupon.com` |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Akamai control plane (`https://control.akamai.com`) | Manual browser access to Akamai Security Center dashboards | Existing edge policies remain enforced; no policy changes possible until control plane recovers |
| Akamai edge network | Monitor via Akamai Status page and security analytics dashboards | No Groupon-managed fallback; Akamai SLA applies |
