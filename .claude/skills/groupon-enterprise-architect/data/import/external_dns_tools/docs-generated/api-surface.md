---
service: "external_dns_tools"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["dns-zone-transfer"]
auth_mechanisms: ["network-acl"]
---

# API Surface

## Overview

External DNS does not expose an HTTP/REST/gRPC API. The only external protocol surface is DNS zone transfer (AXFR/IXFR over TCP port 53), through which Akamai EdgeDNS Zone Transfer Agents periodically synchronize zone data from the BIND master servers. Access is controlled by network firewall rules restricting which source IPs may initiate zone transfers (Akamai ZTA IP ranges must be explicitly permitted).

The `dns_deploy.py` tool is an operator-facing interactive CLI; it has no network-accessible API.

## Endpoints

### DNS Zone Transfer Interface (BIND masters)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| AXFR (zone transfer) | TCP 53 on `externalDnsMasters` | Full zone transfer to Akamai ZTAs for initial or forced sync | Network ACL (Akamai ZTA IP allowlist in firewall) |
| IXFR (incremental zone transfer) | TCP 53 on `externalDnsMasters` | Incremental zone transfer triggered by SOA serial increment | Network ACL (Akamai ZTA IP allowlist in firewall) |
| DNS query (internal QA) | UDP/TCP 53 on `@127.0.0.1` | Local `dig` queries run during deploy QA validation steps | Loopback only |

## Request/Response Patterns

### Common headers

> Not applicable — this service uses the DNS wire protocol, not HTTP.

### Error format

Zone transfer failures result in Akamai alert notifications rather than structured error responses. Akamai alerts are delivered via email to:
- Full alert body: `service-engineering-alerts@groupon.com`
- PagerDuty pager: `sre-alert-allhours@groupon.com` / `dns@groupon.pagerduty.com`

### Pagination

> Not applicable — DNS zone transfers deliver complete zone data in a single AXFR transaction or incremental changes via IXFR.

## Rate Limits

> No rate limiting configured. Akamai is the only zone transfer consumer, and zone transfers are infrequent (triggered by SOA serial changes).

## Versioning

Zone file versioning is managed via the SOA serial number in each zone file. The serial must be incremented monotonically (typically in `YYYYMMDDNN` format) for each change. Akamai ZTAs compare the SOA serial to determine whether a zone transfer is needed.

## OpenAPI / Schema References

> No evidence found in codebase. This service uses DNS wire protocol only; no OpenAPI, proto, or GraphQL schema exists.
