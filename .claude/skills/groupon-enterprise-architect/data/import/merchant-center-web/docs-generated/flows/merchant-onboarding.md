---
service: "merchant-center-web"
title: "Merchant Onboarding"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "merchant-onboarding"
flow_type: synchronous
trigger: "Newly authenticated merchant is directed to /onboarding/* wizard"
participants:
  - "merchantCenterWebSPA"
  - "continuumUmapi"
  - "continuumDoormanSSO"
architecture_ref: "dynamic-continuum-merchant-onboarding"
---

# Merchant Onboarding

## Summary

The merchant onboarding flow guides newly registered merchants through a multi-step setup wizard at the `/onboarding/*` routes. The wizard collects business profile information, configures account settings, and registers the merchant in UMAPI so they can begin creating deals. Each step submits form data to UMAPI via REST; the SPA tracks wizard progress in component state.

## Trigger

- **Type**: user-action
- **Source**: Merchant completes login for the first time or is directed to `/onboarding/*` by UMAPI profile flags indicating incomplete onboarding.
- **Frequency**: Once per new merchant account.

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Provides business profile data through wizard steps | N/A (human actor) |
| Merchant Center Web SPA | Renders wizard steps, validates form inputs, submits data | `merchantCenterWebSPA` |
| Doorman SSO | Provides authenticated session for all API calls | `continuumDoormanSSO` |
| UMAPI | Receives and persists merchant profile and account data per step | `continuumUmapi` |

## Steps

1. **Session Check**: SPA verifies the merchant has an active authenticated session before entering the onboarding wizard.
   - From: `merchantCenterWebSPA`
   - To: `continuumDoormanSSO`
   - Protocol: In-browser session validation

2. **Render Onboarding Step**: SPA renders the current onboarding step form (business info, contact details, banking info, deal preferences, etc.) using react-hook-form.
   - From: `merchantCenterWebSPA`
   - To: Merchant (browser)
   - Protocol: Client-side render

3. **Merchant Completes Step**: Merchant fills in form fields. zod schema validation runs on the client before submission.
   - From: Merchant (browser)
   - To: `merchantCenterWebSPA` (form engine)
   - Protocol: In-browser (direct)

4. **Submit Step Data to UMAPI**: SPA posts validated step data to UMAPI endpoint for the current onboarding step.
   - From: `merchantCenterWebSPA`
   - To: `continuumUmapi`
   - Protocol: REST / HTTPS (proxied, Bearer token)

5. **UMAPI Persists Data and Returns Next Step**: UMAPI saves the step data and returns success, optionally indicating the next required step.
   - From: `continuumUmapi`
   - To: `merchantCenterWebSPA`
   - Protocol: REST / HTTPS

6. **SPA Advances Wizard**: SPA navigates to the next step route within `/onboarding/*`, or to the dashboard if all steps are complete.
   - From: `merchantCenterWebSPA`
   - To: Merchant (browser)
   - Protocol: Client-side route transition (react-router-dom)

7. **Onboarding Complete**: UMAPI marks merchant onboarding as complete. SPA redirects merchant to `/` dashboard.
   - From: `merchantCenterWebSPA`
   - To: Merchant (browser)
   - Protocol: Client-side redirect

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Client-side validation failure | zod schema rejects input; react-hook-form displays inline errors | Merchant corrects input before resubmission |
| UMAPI step submission fails | react-query mutation error state; error toast displayed | Merchant can retry the current step |
| Session expires mid-wizard | Route guard detects expiry; redirects to Doorman login | Merchant must re-authenticate; wizard progress may be partially saved |
| Network failure during submission | react-query retries with backoff | Error toast if all retries exhausted |

## Sequence Diagram

```
Merchant -> merchantCenterWebSPA: Navigate to /onboarding/step-1
merchantCenterWebSPA -> continuumUmapi: GET /merchant/onboarding-status
continuumUmapi --> merchantCenterWebSPA: Current step, completion state
merchantCenterWebSPA -> Merchant: Render step form
Merchant -> merchantCenterWebSPA: Submit step data
merchantCenterWebSPA -> merchantCenterWebSPA: Validate with zod schema
merchantCenterWebSPA -> continuumUmapi: POST /merchant/onboarding/step-1
continuumUmapi --> merchantCenterWebSPA: Step saved, next step
merchantCenterWebSPA -> Merchant: Navigate to /onboarding/step-2
...repeat per step...
merchantCenterWebSPA -> Merchant: Redirect to / (onboarding complete)
```

## Related

- Architecture dynamic view: `dynamic-continuum-merchant-onboarding`
- Related flows: [Merchant Login](merchant-login.md), [Deal Creation](deal-creation.md)
