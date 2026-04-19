---
service: "aws-dns"
title: "Hybrid DNS — On-Premises Resolves AWS Vanity Name"
generated: "2026-03-03"
type: flow
flow_name: "hybrid-onprem-resolves-vanity"
flow_type: synchronous
trigger: "On-premises host performs a DNS lookup for an AWS vanity domain name (e.g., something.stable.us-west-2.aws.groupondev.com)"
participants:
  - "continuumOnPremWorkloads"
  - "continuumOnPremDns"
  - "continuumRoute53InboundEndpoint"
  - "continuumVpcResolver"
  - "continuumPrivateHostedZones"
architecture_ref: "dynamic-inboundDnsQueryFlow"
---

# Hybrid DNS — On-Premises Resolves AWS Vanity Name

## Summary

This flow documents how on-premises hosts resolve AWS vanity domain names such as `<service>.stable.us-west-2.aws.groupondev.com`. These names are published in Route53 Private Hosted Zones and are accessible from on-premises only via the Inbound Endpoint. This is a specialisation of the general Inbound DNS Query Flow, highlighting the specific use case of vanity names that are CNAMEd or A-recorded in Route53 Private Hosted Zones to AWS internal endpoints. The flow is identical to the inbound flow structurally; this document focuses on the vanity name resolution use case.

## Trigger

- **Type**: api-call (DNS query)
- **Source**: On-premises workload in snc1, sac1, or dub1 colo
- **Frequency**: On-demand, per DNS lookup request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| On-premises workload | Initiates DNS lookup for vanity hostname | `continuumOnPremWorkloads` (stub) |
| On-premises DNS server | Matches AWS vanity domain against conditional forwarding rules; forwards to Inbound Endpoint | `continuumOnPremDns` (stub) |
| Route53 Resolver Inbound Endpoint | Receives forwarded query; routes to AmazonProvidedDNS | `continuumRoute53InboundEndpoint` |
| AmazonProvidedDNS (.2 Resolver) | Resolves vanity name from the associated Route53 Private Hosted Zone | `continuumVpcResolver` |
| Route53 Private Hosted Zones | Holds vanity DNS records (e.g., CNAME or A records for `*.stable.us-west-2.aws.groupondev.com`) | `continuumPrivateHostedZones` |

## Steps

1. **On-premises workload queries vanity name**: The on-premises host requests resolution of an AWS vanity hostname such as `my-service.stable.us-west-2.aws.groupondev.com`.
   - From: `continuumOnPremWorkloads`
   - To: `continuumOnPremDns`
   - Protocol: DNS (UDP/TCP port 53)

2. **On-premises DNS matches conditional forwarding rule**: The on-premises DNS conditional forwarding config matches the AWS domain suffix (e.g., `*.aws.groupondev.com` or `us-west-2.aws.groupondev.com`). The query is forwarded to all Inbound Endpoint ENI IPs for the target VPC.
   - From: `continuumOnPremDns`
   - To: `continuumRoute53InboundEndpoint`
   - Protocol: DNS (UDP/TCP port 53) over Direct Connect

3. **Inbound Endpoint routes to .2 Resolver**: The Inbound Query Forwarder delivers the DNS query to AmazonProvidedDNS within the VPC.
   - From: `continuumRoute53InboundEndpoint`
   - To: `continuumVpcResolver`
   - Protocol: DNS (VPC-internal)

4. **AmazonProvidedDNS resolves vanity record from Private Hosted Zone**: The .2 Resolver looks up the vanity name record in the associated Route53 Private Hosted Zone. If the record is a CNAME, the .2 Resolver performs recursive resolution until an A record is found.
   - From: `continuumVpcResolver`
   - To: `continuumPrivateHostedZones`
   - Protocol: DNS (AWS-internal)

5. **Resolved answer returned to on-premises host**: The IP address (A record) or canonical name (CNAME chain resolution) is returned through the path: Route53 PHZ -> .2 Resolver -> Inbound Endpoint -> On-prem DNS -> On-prem workload.
   - From: `continuumPrivateHostedZones` -> `continuumVpcResolver` -> `continuumRoute53InboundEndpoint` -> `continuumOnPremDns` -> `continuumOnPremWorkloads`
   - Protocol: DNS (UDP/TCP port 53)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Vanity record not found in Route53 PHZ | Route53 returns NXDOMAIN | DNS NXDOMAIN propagated back to on-prem host |
| Inbound Endpoint AZ unavailable | AZ Health Selection routes to remaining healthy AZ ENIs | Flow continues with reduced throughput capacity |
| Inbound Endpoint fully unavailable | No automated failover | DNS resolution fails for all AWS vanity names from on-prem |
| Direct Connect unavailable | No automated failover | DNS queries for AWS vanity names time out from affected colo |

## Sequence Diagram

```
On-Prem Host        On-Prem DNS         Inbound Endpoint        .2 Resolver         Route53 PHZ
     |                   |                      |                     |                   |
     |--DNS query------->|                      |                     |                   |
     |  (vanity name)    |                      |                     |                   |
     |                   |--fwd to ENI IP------->|                     |                   |
     |                   |  (conditional fwd     |                     |                   |
     |                   |   for *.aws.groupon)  |                     |                   |
     |                   |                      |--fwd to .2 IP------>|                   |
     |                   |                      |                     |--lookup vanity--->|
     |                   |                      |                     |  record           |
     |                   |                      |                     |<--A/CNAME record--|
     |                   |                      |<--DNS answer--------|                   |
     |                   |<--DNS answer---------|                     |                   |
     |<--DNS answer------|                      |                     |                   |
```

## Related

- Architecture dynamic view: `dynamic-inboundDnsQueryFlow` (commented out in federation DSL)
- Related flows: [Inbound DNS Query Flow](inbound-dns-query.md), [Outbound DNS Query Flow](outbound-dns-query.md)
