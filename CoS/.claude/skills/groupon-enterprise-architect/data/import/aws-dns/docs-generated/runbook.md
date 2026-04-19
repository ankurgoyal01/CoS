---
service: "aws-dns"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Nagios/Monitord check: `ns_aws_prod_uswest2_route53_resolver_az1` | DNS query from dns-sla-monitor hosts | Monitord schedule | Threshold-based |
| Nagios/Monitord check: `ns_aws_prod_uswest2_route53_resolver_az2` | DNS query from dns-sla-monitor hosts | Monitord schedule | Threshold-based |
| Nagios/Monitord check: `ns_aws_prod_uswest2_route53_resolver_az3` | DNS query from dns-sla-monitor hosts | Monitord schedule | Threshold-based |
| Nagios/Monitord check: `ns_aws_prod_uswest1_route53_resolver_az1` | DNS query from dns-sla-monitor hosts | Monitord schedule | Threshold-based |
| Nagios/Monitord check: `ns_aws_prod_uswest1_route53_resolver_az2` | DNS query from dns-sla-monitor hosts | Monitord schedule | Threshold-based |
| Nagios/Monitord check: `ns_aws_internal_prod_uswest2_route53_resolver_az1` | DNS query from dns-sla-monitor hosts | Monitord schedule | Threshold-based |
| Nagios/Monitord check: `ns_aws_internal_prod_uswest2_route53_resolver_az2` | DNS query from dns-sla-monitor hosts | Monitord schedule | Threshold-based |
| Nagios/Monitord check: `ns_aws_internal_prod_uswest2_route53_resolver_az3` | DNS query from dns-sla-monitor hosts | Monitord schedule | Threshold-based |
| Nagios/Monitord check: `ns_aws_prod_euwest1_route53_resolver_az1` | DNS query from dns-sla-monitor hosts | Monitord schedule | Threshold-based |
| Nagios/Monitord check: `ns_aws_prod_euwest1_route53_resolver_az2` | DNS query from dns-sla-monitor hosts | Monitord schedule | Threshold-based |
| Nagios/Monitord check: `ns_aws_prod_euwest1_route53_resolver_az3` | DNS query from dns-sla-monitor hosts | Monitord schedule | Threshold-based |
| Manual DNS probe | DNS (dig) from EC2 instance | Ad hoc | N/A |

> Monitor hosts: `dns-sla-monitor{1,2,3}.{sac1,snc1,dub1}`. Checks query Route53 endpoints with DNS records CNAMEd to on-prem hostnames, covering both Inbound and Outbound flows end-to-end.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| DNS resolution latency (inbound) | gauge | Time for on-prem to receive answer from AWS Inbound Endpoint | HIGH latency alert fires per AZ |
| DNS resolution latency (outbound) | gauge | Time for AWS workload DNS query to resolve via Outbound Endpoint | HIGH latency alert fires per AZ |
| DNS endpoint availability | gauge | Whether each Route53 Resolver endpoint AZ is responding | Monitord check failure |

> Expected latency for both Inbound and Outbound DNS flows is approximately 30ms (when DNS response is not cached).

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| AWS DNS | Wavefront | https://groupon.wavefront.com/dashboard/aws_dns |
| AWS DNS alerts (tag: aws_dns) | Wavefront | https://groupon.wavefront.com/u/tnn150MBFK?t=groupon |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| HIGH DNS Latency between SNC & AWS Prod uswest2 AZ1 | Latency threshold exceeded from snc1 | HIGH | Contact CloudSRE via #cloud-sre-support |
| HIGH DNS Latency between SAC & AWS Prod uswest2 AZ1 | Latency threshold exceeded from sac1 | HIGH | Contact CloudSRE via #cloud-sre-support |
| HIGH DNS Latency between SNC & AWS Prod uswest2 AZ2 | Latency threshold exceeded from snc1 | HIGH | Contact CloudSRE via #cloud-sre-support |
| HIGH DNS Latency between SAC & AWS Prod uswest2 AZ2 | Latency threshold exceeded from sac1 | HIGH | Contact CloudSRE via #cloud-sre-support |
| HIGH DNS Latency between SNC & AWS Prod uswest2 AZ3 | Latency threshold exceeded from snc1 | HIGH | Contact CloudSRE via #cloud-sre-support |
| HIGH DNS Latency between SAC & AWS Prod uswest2 AZ3 | Latency threshold exceeded from sac1 | HIGH | Contact CloudSRE via #cloud-sre-support |
| HIGH DNS Latency between SNC & AWS Prod uswest1 AZ1 | Latency threshold exceeded from snc1 | HIGH | Contact CloudSRE via #cloud-sre-support |
| HIGH DNS Latency between SAC & AWS Prod uswest1 AZ1 | Latency threshold exceeded from sac1 | HIGH | Contact CloudSRE via #cloud-sre-support |
| HIGH DNS Latency between SNC & AWS Prod uswest1 AZ2 | Latency threshold exceeded from snc1 | HIGH | Contact CloudSRE via #cloud-sre-support |
| HIGH DNS Latency between SAC & AWS Prod uswest1 AZ2 | Latency threshold exceeded from sac1 | HIGH | Contact CloudSRE via #cloud-sre-support |
| HIGH DNS Latency between DUB & AWS Prod euwest1 AZ1 | Latency threshold exceeded from dub1 | HIGH | Contact CloudSRE via #cloud-sre-support |
| HIGH DNS Latency between DUB & AWS Prod euwest1 AZ2 | Latency threshold exceeded from dub1 | HIGH | Contact CloudSRE via #cloud-sre-support |
| HIGH DNS Latency between DUB & AWS Prod euwest1 AZ3 | Latency threshold exceeded from dub1 | HIGH | Contact CloudSRE via #cloud-sre-support |

**Escalation path**: All alerts escalate to CloudSRE via Slack channel `#cloud-sre-support`. PagerDuty service: https://groupon.pagerduty.com/services/PPF3JXH. Notification email: `dns@groupon.pagerduty.com`.

## Common Operations

### Restart Service (Legacy Bind/named)

If using the legacy Bind DNS service on an EC2 instance:

```bash
# Check status
sudo /etc/init.d/named status

# Start
sudo /etc/init.d/named start

# Stop
sudo /etc/init.d/named stop

# Restart
sudo /etc/init.d/named restart
```

> Note: Route53 Resolver managed endpoints do not require restart operations. The above commands apply only to legacy EC2-based Bind instances.

### Scale Up / Down

**Route53 Inbound Endpoint:**
1. Increment the `count` in the Terraform module for `route53_resolver` corresponding to the Inbound Endpoint resource block.
2. Re-deploy via Terraform apply.
3. Add the new Inbound ENI IPs to the on-premises DNS conditional forwarding config (`ns_config` repo).
4. Roll on-premises internal DNS servers.

**Route53 Outbound Endpoint:**
1. Increment the `count` in the Terraform module for `route53_resolver` corresponding to the Outbound Endpoint resource block.
2. Re-deploy via Terraform apply.

**Legacy EC2 scaling (blue-green):**
1. Identify active (blue) and inactive (green) server pools.
2. Update `instance_type` in `AWSLandingZone/terraform/modules/dns_infrastructure/servers/instances.tf` to a higher instance type.
3. Deploy changes to the inactive (green) servers.
4. Test: `dig @<new-instance-ip> config.snc1`
5. Switch ENI to activate the green servers.
6. Repeat steps 2-5 for the formerly active (blue) servers.

### Database Operations

> Not applicable. AWS DNS does not use traditional databases or require migration operations.

## Troubleshooting

### Alert fires from a single colo (e.g., only snc1 or only sac1)

- **Symptoms**: Nagios alert fires from one colo but not others; DNS latency is high from that colo
- **Cause**: Connectivity issue between the specific colo and the AWS DNS endpoint (Direct Connect or network path issue affecting that colo)
- **Resolution**: Investigate Direct Connect connectivity between the affected colo and AWS. Check AWS Direct Connect console for BGP session status. Contact CloudSRE via `#cloud-sre-support`.

### Alert fires from all colos simultaneously

- **Symptoms**: Nagios alert fires from sac1, snc1, and/or dub1 simultaneously; DNS resolution fails or is very slow from all colos
- **Cause**: Issue with the AWS DNS service itself (Route53 Resolver endpoint problem, VPC connectivity issue, or AWS service degradation)
- **Resolution**:
  1. SSH to the affected EC2 instance (for legacy Bind instances) and check `named` logs.
  2. Check Route53 Resolver endpoint status in the AWS Console.
  3. Check AWS Service Health Dashboard for Route53 or VPC service degradation.
  4. Restart `named` if applicable (legacy Bind): `sudo /etc/init.d/named restart`
  5. Escalate to CloudSRE via `#cloud-sre-support`.

### DNS queries timing out

- **Symptoms**: `dig` commands return no response or SERVFAIL; applications cannot resolve hostnames
- **Cause**: Direct Connect failure, VPC Internet Gateway issue, app subnet routing/ACL issues, or Security Group misconfiguration
- **Resolution**:
  1. Test DNS resolution from within a VPC: `dig @127.0.0.1 config.snc1` or `dig @<endpoint-ip> config.snc1`
  2. Check Direct Connect BGP session status.
  3. Verify VPC Internet Gateway status in AWS Console.
  4. Review Network ACL rules for the application subnets hosting the endpoints.
  5. Review Security Group rules for the Inbound/Outbound endpoints.
  6. Escalate to CloudSRE via `#cloud-sre-support`.

### Service overloaded (too many DNS queries)

- **Symptoms**: High latency, dropped DNS queries, throughput at or above 10,000 queries/second per ENI
- **Cause**: DNS query volume exceeds current ENI capacity (10,000 QPS per ENI IP)
- **Resolution**: Add capacity by incrementing ENI count in Terraform. See "Scale Up / Down" section above.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | DNS resolution completely down (all colos affected) | Immediate | CloudSRE via `#cloud-sre-support`; PagerDuty `dns@groupon.pagerduty.com` |
| P2 | Degraded DNS resolution (single colo affected, elevated latency) | 30 min | CloudSRE via `#cloud-sre-support` |
| P3 | Single AZ latency spike, minimal user impact | Next business day | Infrastructure Engineering via `infrastructure-engineering@groupon.com` |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| AWS Direct Connect | Check BGP session status in AWS Console; test connectivity from on-prem | Route53 Resolver works with single AZ if only one Direct Connect path is affected |
| VPC Internet Gateway | Check IGW attachment and route table in AWS Console | No automated fallback; remediation required |
| AmazonProvidedDNS (.2 Resolver) | Test `dig @<VPC .2 IP> <hostname>` from within VPC | No fallback; AWS-managed |
| Route53 Private Hosted Zones | Check AWS Service Health Dashboard | No fallback; AWS-managed |
| Application Subnets | Check subnet routing tables and Network ACL rules in AWS Console | No automated fallback; remediation required |
