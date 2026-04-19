---
service: "aws-dns"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for AWS DNS.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Inbound DNS Query Flow](inbound-dns-query.md) | synchronous | On-premises host performs DNS lookup of an AWS-hosted hostname | On-prem DNS forwards query through Inbound Endpoint to AmazonProvidedDNS and Route53 Private Hosted Zones |
| [Outbound DNS Query Flow](outbound-dns-query.md) | synchronous | AWS EC2 workload performs DNS lookup of an on-premises hostname | AmazonProvidedDNS matches outbound rule and routes query through Outbound Endpoint to on-premises DNS |
| [Hybrid DNS Query — On-Prem Resolves AWS Vanity Name](hybrid-onprem-resolves-vanity.md) | synchronous | On-premises host performs DNS lookup of an AWS vanity name (e.g., `*.stable.us-west-2.aws.groupondev.com`) | Follows inbound path; Route53 Private Hosted Zone returns vanity CNAME/A record |
| [Hybrid DNS Query — AWS Resolves On-Prem Name](hybrid-aws-resolves-onprem.md) | synchronous | AWS EC2 workload performs DNS lookup of an on-premises name (e.g., `config.snc1`) | Follows outbound path; Outbound Endpoint forwards to geographically closest on-prem DNS VIP |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All four flows are cross-service by nature — they span the hybrid boundary between on-premises infrastructure and AWS VPCs. The Inbound and Outbound DNS flows are documented in the central architecture model as dynamic views but are currently disabled in the federation workspace due to stub-only external element references. See `architecture/views/dynamics/hybrid-dns-flows.dsl` for the commented-out dynamic view definitions.

- Architecture dynamic view (Inbound): `dynamic-inboundDnsQueryFlow` (commented out in federation)
- Architecture dynamic view (Outbound): `dynamic-outboundDnsQueryFlow` (commented out in federation)
