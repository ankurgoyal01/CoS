---
service: "aws-dns"
title: "Hybrid DNS — AWS Workload Resolves On-Premises Name"
generated: "2026-03-03"
type: flow
flow_name: "hybrid-aws-resolves-onprem"
flow_type: synchronous
trigger: "AWS EC2 workload performs a DNS lookup for an on-premises hostname (e.g., config.snc1)"
participants:
  - "continuumAwsEc2Workloads"
  - "continuumVpcResolver"
  - "continuumRoute53OutboundEndpoint"
  - "continuumOnPremDns"
architecture_ref: "dynamic-outboundDnsQueryFlow"
---

# Hybrid DNS — AWS Workload Resolves On-Premises Name

## Summary

This flow documents how AWS EC2 workloads resolve on-premises hostnames such as `config.snc1`. These names are authoritative on the Groupon on-premises DNS servers and cannot be resolved by Route53 directly. The AmazonProvidedDNS (.2 Resolver) uses a catch-all outbound forwarding rule to route these queries to the Route53 Resolver Outbound Endpoint, which forwards them to the geographically closest on-premises DNS VIPs. This flow is a specialisation of the general Outbound DNS Query Flow, focusing on the common use case of AWS services reaching internal Groupon infrastructure by hostname.

## Trigger

- **Type**: api-call (DNS query)
- **Source**: AWS EC2 workload within a Groupon LandingZone VPC
- **Frequency**: On-demand, per DNS lookup request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| AWS EC2 workload | Initiates DNS lookup for on-premises hostname (e.g., `config.snc1`) | `continuumAwsEc2Workloads` (stub) |
| AmazonProvidedDNS (.2 Resolver) | VPC-local resolver; applies catch-all outbound forwarding rule | `continuumVpcResolver` |
| Route53 Resolver Outbound Endpoint | Forwards DNS query to on-prem DNS VIPs; selects AZ-local egress ENI | `continuumRoute53OutboundEndpoint` |
| On-premises DNS server | Receives query; resolves on-prem hostname authoritatively; returns answer | `continuumOnPremDns` (stub) |

## Steps

1. **AWS workload queries on-prem hostname**: An AWS EC2 instance sends a DNS query for an on-premises hostname such as `config.snc1` to the VPC .2 resolver IP.
   - From: `continuumAwsEc2Workloads`
   - To: `continuumVpcResolver`
   - Protocol: DNS (UDP/TCP port 53) to VPC .2 address

2. **AmazonProvidedDNS evaluates outbound forwarding rules**: The .2 Resolver checks whether the queried name matches any Route53 Resolver rule. The name `config.snc1` does not match any VPC vanity name or VPC internal name patterns, so it matches the catch-all outbound forwarding rule. The .2 Resolver selects the Outbound Endpoint ENI in the same AZ as the requesting EC2 instance.
   - From: `continuumVpcResolver`
   - To: `continuumRoute53OutboundEndpoint` (via `continuumOutboundRuleMatcher`)
   - Protocol: DNS (VPC-internal)

3. **Outbound Endpoint sends query to on-premises DNS**: The Outbound Query Forwarder (`continuumOutboundForwarder`) forwards the DNS query to the configured list of on-premises DNS VIPs. The VIPs are selected to be geographically closest to the AWS region (e.g., us-west-2 → snc1/sac1 VIPs; eu-west-1 → dub1 VIPs).
   - From: `continuumRoute53OutboundEndpoint`
   - To: `continuumOnPremDns`
   - Protocol: DNS (UDP/TCP port 53) over Direct Connect private virtual interface

4. **On-premises DNS resolves the on-prem hostname**: The on-premises DNS server receives the forwarded query and resolves `config.snc1` using its authoritative zone data or internal DNS hierarchy.
   - From: `continuumOnPremDns` (internal resolution)
   - Protocol: DNS (on-premises internal)

5. **Answer returned to AWS workload**: The resolved A record is returned from on-premises DNS to the Outbound Endpoint, then to the .2 Resolver, then to the originating EC2 workload.
   - From: `continuumOnPremDns` -> `continuumRoute53OutboundEndpoint` -> `continuumVpcResolver` -> `continuumAwsEc2Workloads`
   - Protocol: DNS (UDP/TCP port 53)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| On-premises hostname not found | On-prem DNS returns NXDOMAIN | DNS NXDOMAIN propagated back to AWS workload |
| Outbound Endpoint AZ's ENI unavailable | .2 Resolver is AZ-aware; other AZs continue independently | Only workloads in the affected AZ experience DNS failure |
| Direct Connect unavailable | No automated failover | All outbound DNS resolution (on-prem names from VPC) fails |
| On-prem DNS VIP unreachable | Query times out | DNS timeout returned to AWS workload; application may retry |
| All Outbound ENIs unavailable | No automated failover | All AWS workloads in the VPC unable to resolve on-prem names |

## Sequence Diagram

```
AWS EC2 Workload    .2 Resolver          Outbound Endpoint       On-Prem DNS
       |                 |                      |                     |
       |--DNS query------>|                      |                     |
       |  (config.snc1)   |                      |                     |
       |                  |--match catch-all---->|                     |
       |                  |  rule (no VPC match) |                     |
       |                  |                      |--forward to-------->|
       |                  |                      |  on-prem VIP        |
       |                  |                      |  (geographically    |
       |                  |                      |   nearest)          |
       |                  |                      |<--A record----------|
       |                  |<--DNS answer---------|                     |
       |<--DNS answer-----|                      |                     |
```

## Related

- Architecture dynamic view: `dynamic-outboundDnsQueryFlow` (commented out in federation DSL)
- Related flows: [Outbound DNS Query Flow](outbound-dns-query.md), [Inbound DNS Query Flow](inbound-dns-query.md)
