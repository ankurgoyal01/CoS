---
service: "aws-dns"
title: "Outbound DNS Query Flow"
generated: "2026-03-03"
type: flow
flow_name: "outbound-dns-query"
flow_type: synchronous
trigger: "AWS EC2 workload performs a DNS lookup for an on-premises domain name"
participants:
  - "continuumAwsEc2Workloads"
  - "continuumVpcResolver"
  - "continuumRoute53OutboundEndpoint"
  - "continuumInternetGateway"
  - "continuumDirectConnect"
  - "continuumOnPremDns"
architecture_ref: "dynamic-outboundDnsQueryFlow"
---

# Outbound DNS Query Flow

## Summary

The Outbound DNS Query Flow describes how an AWS EC2 workload resolves an on-premises domain name. The workload sends a DNS query to AmazonProvidedDNS (.2 Resolver), which matches the query against the outbound forwarding rule (catch-all for non-AWS names). The .2 Resolver forwards the query to the Route53 Resolver Outbound Endpoint, which sends it to the geographically closest on-premises DNS VIPs via VPC Internet Gateway and Direct Connect. The on-premises DNS server resolves the name and returns the answer. This flow enables all AWS-hosted services to reach on-premises infrastructure by DNS name.

## Trigger

- **Type**: api-call (DNS query)
- **Source**: AWS EC2 instance within a VPC (any workload in any AWS VPC managed by Groupon's LandingZone)
- **Frequency**: On-demand, per DNS lookup request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| AWS EC2 workload | Initiates DNS lookup for an on-premises hostname | `continuumAwsEc2Workloads` (stub) |
| AmazonProvidedDNS (.2 Resolver) | VPC-local resolver; applies outbound forwarding rule to route query to Outbound Endpoint | `continuumVpcResolver` |
| Route53 Resolver Outbound Endpoint | Receives forwarded query from .2 Resolver; sends query to on-prem DNS via egress ENIs | `continuumRoute53OutboundEndpoint` |
| VPC Internet Gateway | VPC egress point for outbound DNS traffic toward Direct Connect | `continuumInternetGateway` (stub) |
| AWS Direct Connect | Private hybrid network path carrying DNS traffic from VPC to on-premises DNS | `continuumDirectConnect` (stub) |
| On-premises DNS server | Receives the outbound DNS query; resolves the on-premises domain name authoritatively | `continuumOnPremDns` (stub) |

## Steps

1. **AWS workload initiates lookup**: AWS EC2 workload sends a DNS query for an on-premises hostname (e.g., `config.snc1`) to the VPC's AmazonProvidedDNS resolver at the .2 IP.
   - From: `continuumAwsEc2Workloads`
   - To: `continuumVpcResolver`
   - Protocol: DNS (UDP/TCP port 53) to VPC .2 address

2. **AmazonProvidedDNS matches outbound forwarding rule**: The .2 Resolver evaluates the query against all configured Route53 Resolver rules. The catch-all outbound forwarding rule matches any query that is not a VPC vanity name or VPC internal name. The .2 Resolver is AZ-aware and selects the Outbound Endpoint ENI in the same AZ as the requesting instance.
   - From: `continuumVpcResolver` -> `continuumOutboundRuleMatcher`
   - To: `continuumRoute53OutboundEndpoint`
   - Protocol: DNS (VPC-internal)

3. **Outbound Endpoint forwards query to on-premises DNS**: The Outbound Rule Matcher selects the appropriate Outbound ENI endpoint for the matching AZ. The Outbound Query Forwarder sends the DNS query to the configured on-premises DNS VIP targets (geographically closest to the AWS region).
   - From: `continuumRoute53OutboundEndpoint`
   - To: `continuumOnPremDns` (via `continuumInternetGateway` and `continuumDirectConnect`)
   - Protocol: DNS (UDP/TCP port 53) over Direct Connect private virtual interface

4. **On-premises DNS resolves the name**: The on-premises DNS server receives the forwarded query, looks up the authoritative record for the on-premises domain, and returns the DNS answer.
   - From: `continuumOnPremDns`
   - To: `continuumRoute53OutboundEndpoint`
   - Protocol: DNS (UDP/TCP port 53)

5. **Answer returned to AWS workload**: The DNS answer travels from the Outbound Endpoint back through the .2 Resolver to the originating AWS workload.
   - From: `continuumRoute53OutboundEndpoint` -> `continuumVpcResolver` -> `continuumAwsEc2Workloads`
   - Protocol: DNS (UDP/TCP port 53)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| One AZ's Outbound ENI is unavailable | AZ-aware .2 Resolver uses ENIs in other available AZs; each AZ operates independently | Flow continues for workloads in healthy AZs; affected AZ's workloads experience DNS failure |
| Direct Connect path down | No automated failover at DNS layer | DNS queries for on-premises names time out from all VPC workloads |
| VPC Internet Gateway issue | No automated failover | DNS queries for on-premises names time out |
| On-premises DNS server unavailable | Query times out; no retry by Route53 Resolver | DNS SERVFAIL or timeout returned to AWS workload |
| All AZs down | No automated failover | All outbound DNS resolution fails |

## Sequence Diagram

```
AWS EC2 Workload     .2 Resolver         Outbound Endpoint       On-Prem DNS
       |                  |                      |                     |
       |--DNS query------->|                      |                     |
       |  (on-prem name)   |                      |                     |
       |                   |--match catch-all---->|                     |
       |                   |  rule, forward        |                     |
       |                   |                      |--forward query----->|
       |                   |                      |  (to on-prem VIP)   |
       |                   |                      |<--DNS answer--------|
       |                   |<--DNS answer---------|                     |
       |<--DNS answer------|                      |                     |
```

## Related

- Architecture dynamic view: `dynamic-outboundDnsQueryFlow` (commented out in federation DSL)
- Related flows: [Inbound DNS Query Flow](inbound-dns-query.md), [Hybrid AWS Resolves On-Prem Name](hybrid-aws-resolves-onprem.md)
