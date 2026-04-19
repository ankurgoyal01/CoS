---
service: "raas_c1"
title: "Operational Request Submission"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "operational-request-submission"
flow_type: synchronous
trigger: "Engineer submits an operational request for C1 Redis infrastructure"
participants:
  - "continuumRaasC1Service"
architecture_ref: "dynamic-continuumRaasC1Service"
---

# Operational Request Submission

## Summary

This flow covers how engineers (operators, SREs, or service owners) submit and track operational requests for C1 Redis infrastructure through the channels registered in the `raas_c1` Service Portal entry. The Service Portal entry provides the authoritative contact metadata — team email, Slack channel, PagerDuty link, request portal URL, and documentation links — that operators use to initiate incident response or routine operational requests.

## Trigger

- **Type**: user-action
- **Source**: Engineer or on-call operator identifying a need to act on C1 Redis infrastructure (snc1, sac1, or dub1 colos)
- **Frequency**: On demand — incident-driven or routine operational need

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| RAAS C1 Service Portal | Provides contact metadata, request channels, and documentation links | `continuumRaasC1Service` |
| raas-team | Receives and acts on operational requests | raas-team@groupon.com |
| Operator / Engineer | Initiates the request | External actor |

## Steps

1. **Identifies C1 Redis issue or request**: An operator or SRE identifies an issue or operational need targeting the C1 colo Redis nodes (snc1, sac1, dub1).
   - From: Operator / Engineer
   - To: Monitoring alerts or direct observation
   - Protocol: Manual

2. **Consults Service Portal entry for contact channels**: The operator looks up `raas_c1` in the Service Portal or uses the registered metadata to determine the correct escalation path.
   - From: Operator
   - To: `continuumRaasC1Service` (Service Portal)
   - Protocol: Internal Service Portal

3. **Selects escalation path based on severity**:
   - For incidents (P1/P2): Pages raas-pager@groupon.com via PagerDuty at https://groupon.pagerduty.com/services/PTK0O0E
   - For operational requests (non-incident): Submits a ticket at https://dse-ops-request.groupondev.com
   - For coordination: Joins Slack channel `CFA7KUDGV` (redis-memcached)
   - Protocol: PagerDuty API / Web form / Slack

4. **raas-team receives and acknowledges**: The raas-team receives the alert or request, acknowledges via the appropriate channel, and begins triaging the C1 Redis issue.
   - From: PagerDuty / Request portal / Slack
   - To: raas-team (pablo, ksatyamurthy, kbandaru)
   - Protocol: PagerDuty / Email / Slack

5. **Engages C1 subservice resources**: If the issue relates to monitoring, the `raas_c1::mon` subservice (https://github.groupondev.com/data/raas) is engaged. If it relates to Redis node configuration, the `raas_c1::redis` subservice (https://github.groupondev.com/data/redislabs_config) is engaged.
   - From: raas-team
   - To: `raas_c1::mon` or `raas_c1::redis` subservice
   - Protocol: Internal tooling

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| PagerDuty alert not routed to on-call | Verify PagerDuty service page at https://groupon.pagerduty.com/services/PTK0O0E is configured with active on-call schedule | Operator falls back to emailing raas-pager@groupon.com directly |
| Request portal unavailable | Use Slack channel `CFA7KUDGV` or email raas-team@groupon.com directly | Request tracked manually |
| Subservice repo inaccessible | Contact raas-team via mailing list raas-announce@groupon.com | raas-team escalates internally |

## Sequence Diagram

```
Operator -> ServicePortal: Lookup raas_c1 contact channels
ServicePortal --> Operator: Return team contacts, PagerDuty link, request portal URL
Operator -> PagerDuty: Page raas-pager@groupon.com (P1/P2) OR
Operator -> RequestPortal: Submit ticket at dse-ops-request.groupondev.com (routine)
PagerDuty/RequestPortal -> raasTeam: Notify and assign
raasTeam -> C1Subservice: Engage raas_c1::mon or raas_c1::redis as needed
```

## Related

- Architecture dynamic view: `dynamic-continuumRaasC1Service`
- Related flows: [Service Portal Registration and Routing](service-portal-registration.md)
- External documentation: [RaaS FAQ](https://confluence.groupondev.com/display/RED/FAQ), [Redislabs Manual](https://confluence.groupondev.com/display/RED/redislabs+Manual)
