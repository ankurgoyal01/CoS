---
service: "aws-dns"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumPrivateHostedZones"
    type: "Route53 Private Hosted Zone"
    purpose: "Authoritative DNS records for AWS-internal and vanity domain names"
---

# Data Stores

## Overview

AWS DNS does not own any traditional databases or caches. The primary authoritative data store is AWS Route53 Private Hosted Zones (`continuumPrivateHostedZones`), which hold the internal DNS records that the AmazonProvidedDNS resolver consults during inbound query resolution. Route53 Private Hosted Zones are an AWS-managed service; Groupon manages the zone records within them but does not manage the underlying storage infrastructure.

## Stores

### Route53 Private Hosted Zones (`continuumPrivateHostedZones`)

| Property | Value |
|----------|-------|
| Type | AWS Route53 Private Hosted Zone |
| Architecture ref | `continuumPrivateHostedZones` |
| Purpose | Authoritative DNS records for internal AWS-hosted domain names and vanity names (e.g., `*.stable.us-west-2.aws.groupondev.com`) |
| Ownership | owned (records managed by Groupon; storage managed by AWS) |
| Migrations path | Managed via AWSLandingZone Terraform modules |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| VPC vanity zone records | Resolve VPC-internal vanity names (e.g., `*.stable.us-west-2.aws.groupondev.com`) | hostname, record type (A/CNAME), TTL, value |
| VPC internal records | Resolve EC2 instance internal DNS names (e.g., `ip-x-x-x-x.us-west-2.compute.internal`) | hostname, record type (A), TTL, value |

#### Access Patterns

- **Read**: AmazonProvidedDNS (.2 Resolver) queries Route53 Private Hosted Zones for every inbound DNS lookup that matches a zone hosted in Route53. Queries are read-only at resolution time.
- **Write**: Records are created and modified via Terraform (AWSLandingZone repository) during infrastructure provisioning or changes. No runtime write path exists.
- **Indexes**: Not applicable — DNS zone lookup by domain name is managed internally by the Route53 service.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| DNS response cache (implicit) | AWS-managed in-memory | Route53 Resolver and AmazonProvidedDNS cache resolved DNS responses | Controlled by DNS record TTL values set in Route53 Private Hosted Zones |

## Data Flows

DNS record data flows in one direction: Terraform writes records to Route53 Private Hosted Zones during infrastructure provisioning. At query time, AmazonProvidedDNS reads records from Route53 Private Hosted Zones and returns responses to the Inbound Query Forwarder, which returns responses back to the on-premises DNS caller. No ETL, CDC, or replication to other stores is involved.
