---
service: "aws-external"
title: "AWS Incident Response"
generated: "2026-03-03"
type: flow
flow_name: "aws-incident-response"
flow_type: event-driven
trigger: "Production incident detected in AWS-hosted infrastructure"
participants:
  - "continuumAwsExternal"
  - "continuumRunbookReferenceIndex"
  - "continuumCloudSreOperations"
architecture_ref: "dynamic-awsAlertRoutingFlow"
---

# AWS Incident Response

## Summary

When a production incident is detected that is suspected to be caused by an AWS platform issue, the Cloud SRE team uses the runbook references stored in `aws-external` to guide triage, escalation to AWS support, and resolution. The flow covers initial IMOC notification, AWS support case creation, TAM engagement, and capacity remediation (quota increases). This flow is informed by the `continuumRunbookReferenceIndex` component, which stores links to onboarding, FAQ, and troubleshooting guidance.

## Trigger

- **Type**: event
- **Source**: Alert routed to Cloud SRE via the [AWS Alert Routing flow](aws-alert-routing.md), or direct detection by a team member
- **Frequency**: On-demand, whenever a production incident involving AWS infrastructure occurs

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| aws-external (Runbook Reference Index) | Provides troubleshooting links, onboarding guidance, and FAQ used during incident response | `continuumRunbookReferenceIndex` |
| Cloud SRE Operations | Owns and drives incident response; executes runbook steps | `continuumCloudSreOperations` |
| IMOC (Incident Manager On-Call) | Coordinates incident response; contacted immediately for production incidents | External (Slack: #production) |
| AWS Support | External escalation for confirmed AWS platform problems | External |
| AWS Technical Account Managers (TAMs) | External escalation with incident context; engaged for platform-level issues | External (Slack: #grpn-and-aws-guests) |
| NETOPS | Escalation point for network-level throttling or AZ/regional traffic issues | External (internal team) |

## Steps

1. **Detects production incident**: Cloud SRE or on-call engineer detects a suspected AWS platform issue through monitoring, alerts, or user reports.
   - From: Monitoring system or alert router
   - To: `continuumCloudSreOperations`
   - Protocol: Alert notification

2. **Notifies IMOC**: Cloud SRE immediately contacts IMOC in the #production Slack room, indicating the severity of the incident.
   - From: `continuumCloudSreOperations`
   - To: IMOC
   - Protocol: Slack (#production)

3. **Consults runbook references**: Cloud SRE consults the Runbook Reference Index for relevant troubleshooting guidance, onboarding links, and FAQs.
   - From: `continuumCloudSreOperations`
   - To: `continuumRunbookReferenceIndex`
   - Protocol: Internal reference (documentation)

4. **Raises AWS support incident**: If the incident is suspected to be an AWS platform issue, Cloud SRE raises an [AWS support case](https://docs.aws.amazon.com/awssupport/latest/user/case-management.html).
   - From: `continuumCloudSreOperations`
   - To: AWS Support
   - Protocol: AWS Support API / Console

5. **Engages AWS TAMs**: Cloud SRE contacts AWS TAMs in the #grpn-and-aws-guests Slack channel, providing the AWS incident number.
   - From: `continuumCloudSreOperations`
   - To: AWS Technical Account Managers
   - Protocol: Slack (#grpn-and-aws-guests)

6. **Investigates via CloudTrail**: For throttling or quota issues, Cloud SRE identifies the affected resource using CloudTrail. Time window is narrowed to the incident period; events may be exported as JSON and searched locally for non-canonical identifiers (e.g., IP addresses).
   - From: `continuumCloudSreOperations`
   - To: AWS CloudTrail
   - Protocol: AWS Console / API

7. **Increases service quota**: Cloud SRE logs into the appropriate AWS account and requests a quota increase via the Service Quotas console — typically 50–100% above the current limit.
   - From: `continuumCloudSreOperations`
   - To: AWS Service Quotas
   - Protocol: AWS Console

8. **Escalates network issues to NETOPS**: If the incident involves network-level throttling (many services in an AZ or region capping inbound/outbound traffic), Cloud SRE contacts NETOPS.
   - From: `continuumCloudSreOperations`
   - To: NETOPS
   - Protocol: Internal escalation

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AWS support response is slow | Escalate to TAMs in #grpn-and-aws-guests immediately with incident number; do not wait for support ticket response | Parallel escalation path accelerates AWS investigation |
| CloudTrail query returns too many results | Narrow the time window; export events as JSON and search locally if only a few hundred candidate events remain | Faster root-cause identification |
| Quota increase request denied or delayed by AWS | Contact TAMs directly; be prepared to justify the increase percentage | TAMs can expedite quota increases |
| EC2 node failure (bad network interface) | Terminate the affected node from EC2 console — no AWS support case needed | Node replaced by auto-scaling; no AWS engagement required |

## Sequence Diagram

```
MonitoringSystem -> continuumCloudSreOperations: Detects production incident
continuumCloudSreOperations -> IMOC: Notifies via #production Slack (severity indicated)
continuumCloudSreOperations -> continuumRunbookReferenceIndex: Consults troubleshooting guidance
continuumCloudSreOperations -> AWSSupport: Raises AWS support incident case
continuumCloudSreOperations -> AWSTAMs: Shares incident number via #grpn-and-aws-guests Slack
continuumCloudSreOperations -> AWSCloudTrail: Investigates throttled resource
continuumCloudSreOperations -> AWSServiceQuotas: Requests quota increase (50-100%)
AWSSupport --> continuumCloudSreOperations: Acknowledges and begins investigation
AWSTAMs --> continuumCloudSreOperations: Engages on incident
```

## Related

- Architecture dynamic view: `dynamic-awsAlertRoutingFlow` (disabled in federation — stub-only elements)
- Related flows: [AWS Alert Routing to Cloud SRE](aws-alert-routing.md)
- Operational details: [Runbook](../runbook.md)
- Deployment context: [Deployment](../deployment.md)
