---
service: "aws-dns"
title: "Inbound DNS Query Flow"
generated: "2026-03-03"
type: flow
flow_name: "inbound-dns-query"
flow_type: synchronous
trigger: "On-premises host performs a DNS lookup for an AWS-hosted domain name"
participants:
  - "continuumOnPremWorkloads"
  - "continuumOnPremDns"
  - "continuumDirectConnect"
  - "continuumInternetGateway"
  - "continuumRoute53InboundEndpoint"
  - "continuumVpcResolver"
  - "continuumPrivateHostedZones"
architecture_ref: "dynamic-inboundDnsQueryFlow"
---

# Inbound DNS Query Flow

## Summary

The Inbound DNS Query Flow describes how an on-premises host resolves an AWS-hosted domain name. The on-premises host's DNS request is forwarded by the on-premises DNS server to the Route53 Resolver Inbound Endpoint via Direct Connect and VPC Internet Gateway. The Inbound Endpoint forwards the query to AmazonProvidedDNS (.2 Resolver), which resolves the record from a Route53 Private Hosted Zone and returns the answer along the same path. This flow enables all Groupon on-premises workloads to reach AWS-hosted services by DNS name.

## Trigger

- **Type**: api-call (DNS query)
- **Source**: On-premises host (any server in snc1, sac1, or dub1 colos)
- **Frequency**: On-demand, per DNS lookup request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| On-premises workload | Initiates DNS lookup of an AWS hostname | `continuumOnPremWorkloads` (stub) |
| On-premises DNS server | Receives the DNS query; applies conditional forwarding rules to route AWS-domain queries to Inbound Endpoint IPs | `continuumOnPremDns` (stub) |
| AWS Direct Connect | Private hybrid network path carrying DNS traffic from on-prem to VPC boundary | `continuumDirectConnect` (stub) |
| VPC Internet Gateway | VPC entry point for inbound DNS traffic from Direct Connect | `continuumInternetGateway` (stub) |
| Route53 Resolver Inbound Endpoint | Receives DNS query from on-prem DNS; distributes across healthy AZ ENIs | `continuumRoute53InboundEndpoint` |
| AmazonProvidedDNS (.2 Resolver) | VPC-local resolver that looks up the answer from Route53 Private Hosted Zones | `continuumVpcResolver` |
| Route53 Private Hosted Zones | Authoritative DNS store for AWS-hosted domain records | `continuumPrivateHostedZones` |

## Steps

1. **On-premises host initiates lookup**: On-premises workload sends a DNS query for an AWS hostname (e.g., `my-service.stable.us-west-2.aws.groupondev.com`) to the local on-premises DNS server.
   - From: `continuumOnPremWorkloads`
   - To: `continuumOnPremDns`
   - Protocol: DNS (UDP/TCP port 53)

2. **On-premises DNS applies conditional forwarding**: On-premises DNS server matches the query against the conditional forwarding configuration. Queries for AWS domains are forwarded to the configured Inbound Endpoint ENI IPs for the target VPC.
   - From: `continuumOnPremDns`
   - To: `continuumRoute53InboundEndpoint` (via Direct Connect and VPC Internet Gateway)
   - Protocol: DNS (UDP/TCP port 53) over Direct Connect private virtual interface

3. **Inbound Endpoint receives and forwards query**: The AZ Health Selection component (`continuumInboundAzHealthSelection`) selects a healthy Inbound ENI endpoint. The Inbound Query Forwarder (`continuumInboundQueryForwarder`) forwards the DNS query to the AmazonProvidedDNS (.2 Resolver) within the VPC.
   - From: `continuumRoute53InboundEndpoint`
   - To: `continuumVpcResolver`
   - Protocol: DNS (VPC-internal)

4. **AmazonProvidedDNS resolves the record**: The .2 Resolver receives the query, identifies the matching Route53 Private Hosted Zone, and looks up the authoritative DNS record.
   - From: `continuumVpcResolver`
   - To: `continuumPrivateHostedZones`
   - Protocol: DNS (AWS-internal)

5. **Answer returned to caller**: The resolved DNS record is returned through the reverse path: AmazonProvidedDNS returns the answer to the Inbound Endpoint, which returns it to the on-premises DNS server, which returns it to the originating host.
   - From: `continuumPrivateHostedZones` -> `continuumVpcResolver` -> `continuumRoute53InboundEndpoint` -> `continuumOnPremDns` -> `continuumOnPremWorkloads`
   - Protocol: DNS (UDP/TCP port 53)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| One AZ's Inbound ENI is unavailable | AZ Health Selection routes traffic to remaining healthy AZ ENIs. On-prem DNS stops forwarding to that AZ's IP. | Flow continues with reduced capacity; no impact if at least one AZ is healthy |
| Direct Connect path down | No automated failover at DNS layer | DNS queries time out; Nagios alert fires from affected colo |
| VPC Internet Gateway issue | No automated failover | DNS queries time out; all colos affected |
| Route53 Private Hosted Zone lookup fails | DNS SERVFAIL returned to caller | Query resolution fails; application receives SERVFAIL |
| All AZs down | No automated failover | All inbound DNS resolution fails; DNS queries time out |

## Sequence Diagram

```
On-Prem Host        On-Prem DNS         Inbound Endpoint        .2 Resolver         Route53 PHZ
     |                   |                      |                     |                   |
     |--DNS query------->|                      |                     |                   |
     |  (AWS hostname)   |                      |                     |                   |
     |                   |--forward to ENI IP-->|                     |                   |
     |                   |  (conditional fwd)   |                     |                   |
     |                   |                      |--forward query----->|                   |
     |                   |                      |  (to .2 resolver)   |                   |
     |                   |                      |                     |--lookup record--->|
     |                   |                      |                     |<--DNS record------|
     |                   |                      |<--DNS answer--------|                   |
     |                   |<--DNS answer---------|                     |                   |
     |<--DNS answer------|                      |                     |                   |
```

## Related

- Architecture dynamic view: `dynamic-inboundDnsQueryFlow` (commented out in federation DSL)
- Related flows: [Outbound DNS Query Flow](outbound-dns-query.md), [Hybrid On-Prem Resolves Vanity Name](hybrid-onprem-resolves-vanity.md)
