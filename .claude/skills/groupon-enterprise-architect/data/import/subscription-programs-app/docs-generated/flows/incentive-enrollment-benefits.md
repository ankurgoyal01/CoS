---
service: "subscription-programs-app"
title: "Incentive Enrollment and Benefits"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "incentive-enrollment-benefits"
flow_type: synchronous
trigger: "Internal — triggered on membership activation (create or reactivate)"
participants:
  - "membershipService"
  - "subscriptionRepository"
  - "continuumSubscriptionProgramsDb"
  - "incentiveService"
architecture_ref: "dynamic-incentive-enrollment-benefits"
---

# Incentive Enrollment and Benefits

## Summary

This flow covers how newly activated or reactivated Select members are enrolled in loyalty incentive benefits. The Membership Service calls the Incentive Service after a membership transitions to ACTIVE, persists the enrollment record to `mm_programs`, and optionally integrates with TPIS for third-party incentive data when the TPIS integration is enabled. This flow is a sub-step of both [Create Subscription](create-subscription.md) and [Reactivate v2 Membership](reactivate-v2-membership.md).

## Trigger

- **Type**: internal (sub-flow)
- **Source**: Called internally by Membership Service immediately after a membership transitions to ACTIVE
- **Frequency**: On-demand, per membership activation or reactivation event

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Membership Service | Initiates incentive enrollment after membership activation | `membershipService` |
| Subscription Repository | Persists incentive enrollment records | `subscriptionRepository` |
| Subscription Programs DB | Stores `incentive_enrollment` records for the member | `continuumSubscriptionProgramsDb` |
| Incentive Service | Authoritative source for available Select benefits; processes enrollment requests | internal |

## Steps

1. **Retrieve applicable incentives**: Membership Service queries Incentive Service for the list of benefits available for the consumer's Select plan.
   - From: `membershipService` (via `jtier-retrofit`)
   - To: Incentive Service
   - Protocol: REST

2. **Submit enrollment request**: Membership Service sends an enrollment request to Incentive Service for the consumer and the applicable benefit set.
   - From: `membershipService` (via `jtier-retrofit`)
   - To: Incentive Service
   - Protocol: REST

3. **Persist enrollment record**: Subscription Repository writes the incentive enrollment confirmation to the `incentive_enrollment` table in `mm_programs`.
   - From: `subscriptionRepository`
   - To: `continuumSubscriptionProgramsDb`
   - Protocol: JDBC / MySQL

4. **(Optional) Call TPIS for third-party benefits**: If `TPIS_ENABLED=true`, Membership Service calls TPIS to extend enrollment to third-party incentive programs.
   - From: `membershipService` (via `jtier-retrofit`)
   - To: TPIS
   - Protocol: REST

5. **Return enrollment result to caller**: Membership Service returns the enrollment outcome to the calling flow (create or reactivate).
   - From: `membershipService`
   - To: calling flow
   - Protocol: Direct (in-process)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Incentive Service unavailable | `guava-retrying` retries; if exhausted, logged as warning | Membership remains ACTIVE; enrollment gap flagged for background reconciliation |
| TPIS unavailable (optional) | Gracefully skipped when `TPIS_ENABLED=false` or on timeout | Third-party benefits not enrolled; base Select benefits unaffected |
| Enrollment persistence failure | Logged; incentive enrollment may be inconsistent | Background incentive reconciliation job will detect and retry the gap |

## Sequence Diagram

```
membershipService -> IncentiveService : getAvailableIncentives(planId)
IncentiveService --> membershipService: [incentiveList]
membershipService -> IncentiveService : enrollMember(consumerId, [incentiveList])
IncentiveService --> membershipService: enrollmentConfirmation
membershipService -> subscriptionRepository : saveIncentiveEnrollment(consumerId, incentiveIds, enrolledAt)
subscriptionRepository -> continuumSubscriptionProgramsDb : INSERT INTO incentive_enrollment
opt TPIS_ENABLED=true
  membershipService -> TPIS : enrollThirdPartyBenefits(consumerId, planId)
  TPIS --> membershipService: tpisEnrollmentResult
end
membershipService --> callingFlow : incentiveEnrollmentResult
```

## Related

- Architecture dynamic view: `dynamic-incentive-enrollment-benefits`
- Related flows: [Create Subscription](create-subscription.md), [Reactivate v2 Membership](reactivate-v2-membership.md), [Background Membership Jobs](background-membership-jobs.md)
