---
service: "aws-external"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

> No evidence found in codebase. There is no running service to health-check. AWS service health is monitored via the AWS Service Health Dashboard and CloudWatch.

## Monitoring

### Metrics

> No evidence found in codebase. Metrics for AWS-hosted services are published by AWS (CloudWatch) and by individual Groupon services running on AWS.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| AWS CloudTrail Events | AWS Console | https://docs.aws.amazon.com/awscloudtrail/latest/userguide/view-cloudtrail-events.html |
| AWS Service Quotas | AWS Console | https://console.aws.amazon.com/servicequotas/home |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| AWS API throttling / rate limiting | Failures to call an AWS API due to quota exhaustion | critical | Identify throttled resource via CloudTrail; increase quota by 50–100% via Service Quotas console |
| EC2 node failure (bad network interface) | Node starts but contains only system pods (calico, termination handler, kube-proxy) in constant crash loop | critical | Terminate the affected EC2 node from the EC2 console |
| AZ network traffic down (multi-account) | Network traffic loss in a single AZ affecting both staging and production simultaneously | critical | Contact NETOPS; raise AWS support incident; contact TAMs in #grpn-and-aws-guests |
| AWS service regional degradation | Multiple services in a region capping inbound/outbound traffic | critical | Contact NETOPS; raise AWS support incident |

## Common Operations

### Restart Service

Not applicable. `aws-external` has no running service process to restart.

### Scale Up / Down

Log into the appropriate AWS account and navigate to the [Service Quotas console](https://console.aws.amazon.com/servicequotas/home).

1. Identify the quota that needs adjustment.
2. Request an increase — when responding to an active incident, increase by 50% or 100%.
3. Monitor AWS support response; be prepared to justify the increase.
4. For network throttling affecting multiple services across an AZ or region, contact NETOPS instead.

### Database Operations

Not applicable. This service owns no data stores.

## Troubleshooting

### AWS API Throttling / Rate Limiting
- **Symptoms**: Failures to create AWS instances; API call failures with rate-limit error messages; network traffic throttling.
- **Cause**: AWS service quotas exhausted. Almost every AWS service has an associated service quota that can be hit under load.
- **Resolution**: Check CloudTrail for the resource name or event name. Narrow the time window to when the event occurred (CloudTrail is slow with large result sets). If you have a non-canonical identifier (e.g., an IP address rather than an EC2 instance ID), export events as JSON and search locally. Once the throttled resource is identified, increase the quota via the Service Quotas console.

### EC2 Node Bad Network Interface
- **Symptoms**: A Conveyor cloud node starts up but contains only system pods (calico, termination handler, kube-proxy, etc.) in a constant crash loop.
- **Cause**: Bad network interface on the EC2 node.
- **Resolution**: Terminate the affected EC2 node from the EC2 console. No AWS support incident required.

### AZ or Regional Network Outage
- **Symptoms**: Network traffic is down in a single AZ affecting both staging and production simultaneously. Traffic loss does not equally affect the whole region but does affect multiple accounts.
- **Cause**: AWS infrastructure problem (network links are not tied to a single AZ and code is deployed within a single account, so cross-account, single-AZ loss is a clear AWS signal).
- **Resolution**: Contact AWS immediately by raising an [AWS support incident](https://docs.aws.amazon.com/awssupport/latest/user/case-management.html) and notifying TAMs in the #grpn-and-aws-guests Slack channel with the incident number. Contact NETOPS for network-level traffic throttling.

### Accessing CloudTrail Efficiently
- **Symptoms**: Investigating an incident and CloudTrail is returning hundreds of pages of results.
- **Cause**: CloudTrail generates very high event volume; unfiltered queries are slow.
- **Resolution**: Narrow the time window to when the event occurred. If working with a non-canonical identifier (e.g., an IP address), export the candidate events as JSON and search that output locally rather than paginating through the console.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | AWS service or regional outage affecting production | Immediate | Contact IMOC in #production Slack; raise AWS support incident; notify TAMs in #grpn-and-aws-guests |
| P2 | Partial degradation — throttling, quota exhaustion | 30 min | Cloud SRE; increase quota via Service Quotas console |
| P3 | Minor impact — isolated node failure | Next business day | Cloud SRE; remediate per troubleshooting steps above |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| AWS Control Plane | AWS Service Health Dashboard; CloudTrail audit logs | Contact AWS TAMs via #grpn-and-aws-guests Slack channel; raise formal AWS support case |
| AWS Network (per AZ) | Monitor cross-account, single-AZ traffic patterns | Contact NETOPS for network-level throttling |
