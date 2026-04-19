---
service: "aws-dns"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["dns"]
auth_mechanisms: ["aws-security-groups", "network-acl"]
---

# API Surface

## Overview

AWS DNS does not expose an application-level HTTP/REST/gRPC API. Its interface is the DNS protocol (UDP/TCP port 53) via Route53 Resolver ENI IP addresses. On-premises DNS servers connect to the Inbound Endpoint ENI IPs to resolve AWS-hosted domains. AWS workloads interact with the standard VPC resolver IP (the .2 Resolver) which internally routes through the Outbound Endpoint ENIs to reach on-premises DNS.

## Endpoints

### Inbound Endpoint (On-premises to AWS)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| DNS query (UDP/TCP 53) | `<InboundEndpointENI-AZ1-IP>:53` | Accepts inbound DNS queries from on-prem DNS for AWS-hosted domains | AWS Security Group (network-level) |
| DNS query (UDP/TCP 53) | `<InboundEndpointENI-AZ2-IP>:53` | AZ2 inbound ENI endpoint | AWS Security Group (network-level) |
| DNS query (UDP/TCP 53) | `<InboundEndpointENI-AZ3-IP>:53` | AZ3 inbound ENI endpoint | AWS Security Group (network-level) |

### Outbound Endpoint (AWS VPC to On-premises)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| DNS query (UDP/TCP 53) | `<OutboundEndpointENI-AZ1-IP>:53` | Egress ENI through which VPC outbound DNS traffic exits to on-prem | AWS Security Group (network-level) |
| DNS query (UDP/TCP 53) | `<OutboundEndpointENI-AZ2-IP>:53` | AZ2 outbound ENI endpoint | AWS Security Group (network-level) |
| DNS query (UDP/TCP 53) | `<OutboundEndpointENI-AZ3-IP>:53` | AZ3 outbound ENI endpoint | AWS Security Group (network-level) |

### AmazonProvidedDNS (.2 Resolver)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| DNS query (UDP/TCP 53) | `<VPC CIDR base + .2>:53` | VPC-internal resolver entry point for all AWS workload DNS lookups | VPC network boundary |

## Request/Response Patterns

### Common headers

> Not applicable. DNS protocol does not use HTTP headers. DNS queries use standard RFC 1035 wire format over UDP (default) or TCP (for large responses or zone transfers).

### Error format

DNS SERVFAIL (response code 2) is returned when a query cannot be resolved. DNS NXDOMAIN (response code 3) is returned when the queried name does not exist. Query timeouts occur when connectivity to the endpoint ENIs is disrupted (e.g., Direct Connect or Internet Gateway failures).

### Pagination

> Not applicable. DNS protocol does not use pagination.

## Rate Limits

| Tier | Limit | Window |
|------|-------|--------|
| Per Inbound ENI IP | 10,000 queries per second | Per second |
| Per Outbound ENI IP | 10,000 queries per second | Per second |
| Example: 3-AZ VPC Inbound | 30,000 queries per second | Per second (3 ENIs x 10,000) |
| Example: 3-AZ VPC Outbound | 30,000 queries per second | Per second (3 ENIs x 10,000) |

> Rate limits are defined by AWS Route53 Resolver service limits. See [AWS Route53 Resolver documentation](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html#limits-api-entities-resolver).

## Versioning

> Not applicable. DNS protocol versioning is managed by AWS as a fully managed service. No application-level versioning strategy applies.

## OpenAPI / Schema References

> No evidence found in codebase. AWS DNS uses DNS wire protocol (RFC 1035). No OpenAPI spec, proto files, or GraphQL schema exist — the service interface is DNS over UDP/TCP port 53.
