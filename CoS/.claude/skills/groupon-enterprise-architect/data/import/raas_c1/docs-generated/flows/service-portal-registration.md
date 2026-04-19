---
service: "raas_c1"
title: "Service Portal Registration and Routing"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "service-portal-registration"
flow_type: synchronous
trigger: "OCT tooling or BASTIC ticket system resolves the raas_c1 service identity"
participants:
  - "continuumRaasC1Service"
  - "raas_dns"
architecture_ref: "dynamic-continuumRaasC1Service"
---

# Service Portal Registration and Routing

## Summary

This flow describes how Groupon's internal OCT tooling and BASTIC ticketing system use the `raas_c1` Service Portal entry to identify, route, and manage operational requests targeting C1 colocation Redis nodes. The entry was created specifically to work around OCT's inability to associate two BASTIC tickets with a single service (DATA-5855), splitting the broader RaaS platform into `raas_c1` and `raas_c2` entries. It carries no deployable process but anchors routing to the snc1, sac1, and dub1 colos.

## Trigger

- **Type**: system-lookup
- **Source**: OCT tooling or BASTIC ticket system performing a service registry lookup for `raas_c1`
- **Frequency**: On demand — whenever internal tooling resolves C1 Redis service identity for ticket creation, routing, or status queries

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| RAAS C1 Service Portal | Service identity anchor; provides colo base URLs and contact metadata | `continuumRaasC1Service` |
| raas_dns | DNS resolution for C1 Redis node endpoints | `raas_dns` (dependency) |
| OCT / BASTIC tooling | Initiates lookup; consumes service registration metadata | Internal tooling (not in raas_c1 DSL) |

## Steps

1. **Resolves service identity**: OCT tooling or BASTIC ticket system queries the Service Portal for the `raas_c1` service entry.
   - From: OCT / BASTIC internal tooling
   - To: `continuumRaasC1Service` (Service Portal registry)
   - Protocol: Internal Service Portal API

2. **Returns colo metadata**: The Service Portal entry returns registered metadata — colo identifiers (snc1, sac1, dub1), internal base URLs, team contacts, and subservice declarations.
   - From: `continuumRaasC1Service`
   - To: OCT / BASTIC tooling
   - Protocol: Internal Service Portal API

3. **Resolves C1 endpoint via DNS**: For requests targeting a specific C1 Redis node, internal routing resolves the endpoint through `raas_dns`.
   - From: Routing layer
   - To: `raas_dns`
   - Protocol: DNS

4. **Routes request to colo base URL**: Resolved traffic is directed to the appropriate internal base URL for the target colo.
   - From: Internal router
   - To: `https://us.raas-bast-cs-prod.grpn:8443` (snc1/sac1) or `https://dub1.raas-bast-cs-prod.grpn:8443` (dub1)
   - Protocol: HTTPS (internal)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Service Portal entry not found | OCT tooling cannot create or route BASTIC ticket | Operator must verify `raas_c1` registration; contact raas-team@groupon.com |
| `raas_dns` resolution failure | DNS lookup for C1 endpoint fails | Routing to C1 Redis nodes fails; escalate to DNS infrastructure team |
| Base URL unreachable | Internal HTTPS to `raas-bast-cs-prod.grpn` fails | C1 colo is inaccessible; engage raas-pager@groupon.com |

## Sequence Diagram

```
OCT/BASTIC -> ServicePortal: Lookup raas_c1 service identity
ServicePortal -> OCT/BASTIC: Return colo metadata (snc1, sac1, dub1 base URLs)
OCT/BASTIC -> raas_dns: Resolve C1 Redis endpoint
raas_dns --> OCT/BASTIC: DNS response with endpoint address
OCT/BASTIC -> C1BasteURL: Route operational request (HTTPS internal)
```

## Related

- Architecture dynamic view: `dynamic-continuumRaasC1Service`
- Related flows: [Operational Request Submission](operational-request-submission.md)
- RaaS platform flows: [RaaS flows index](../../raas/docs-generated/flows/index.md)
