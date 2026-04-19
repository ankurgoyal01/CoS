---
service: "merchant-center-web"
title: "2FA Enrollment"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "2fa-enrollment"
flow_type: synchronous
trigger: "Merchant opts in to two-factor authentication from account settings"
participants:
  - "merchantCenterWebSPA"
  - "continuumUmapi"
  - "continuumDoormanSSO"
architecture_ref: "dynamic-continuum-2fa-enrollment"
---

# 2FA Enrollment

## Summary

The 2FA enrollment flow allows merchants to add a second authentication factor to their Merchant Center account for enhanced security. The merchant initiates enrollment from the account settings section; the SPA coordinates with UMAPI to register the 2FA method and guides the merchant through verification. Once enrolled, subsequent logins via Doorman SSO require the second factor.

## Trigger

- **Type**: user-action
- **Source**: Merchant navigates to security settings within `/account/*` and selects "Enable Two-Factor Authentication".
- **Frequency**: Once per merchant account (or when updating 2FA method).

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Initiates 2FA enrollment, completes verification challenge | N/A (human actor) |
| Merchant Center Web SPA | Renders enrollment UI, submits registration to UMAPI | `merchantCenterWebSPA` |
| UMAPI | Registers 2FA method, validates verification code | `continuumUmapi` |
| Doorman SSO | Enforces 2FA on subsequent logins post-enrollment | `continuumDoormanSSO` |

## Steps

1. **Merchant Navigates to Security Settings**: Merchant opens `/account/security` or equivalent route.
   - From: Merchant (browser)
   - To: `merchantCenterWebSPA`
   - Protocol: Client-side route transition

2. **SPA Fetches Current 2FA Status**: SPA calls UMAPI to retrieve current account security settings and 2FA enrollment state.
   - From: `merchantCenterWebSPA`
   - To: `continuumUmapi`
   - Protocol: REST / HTTPS (proxied, Bearer token)

3. **SPA Renders 2FA Enrollment UI**: SPA displays available 2FA methods (e.g., authenticator app, SMS) and an enrollment initiation button.
   - From: `merchantCenterWebSPA`
   - To: Merchant (browser)
   - Protocol: Client-side render

4. **Merchant Initiates Enrollment**: Merchant selects 2FA method and clicks enroll.
   - From: Merchant (browser)
   - To: `merchantCenterWebSPA`
   - Protocol: In-browser (direct)

5. **SPA Requests 2FA Setup from UMAPI**: SPA posts enrollment initiation request to UMAPI. UMAPI generates a setup secret/QR code and returns it.
   - From: `merchantCenterWebSPA`
   - To: `continuumUmapi`
   - Protocol: REST / HTTPS (proxied, Bearer token)

6. **Merchant Registers 2FA Device**: SPA displays the QR code or SMS prompt. Merchant scans the QR code with an authenticator app or enters their phone number.
   - From: `merchantCenterWebSPA`
   - To: Merchant (browser)
   - Protocol: Client-side render

7. **Merchant Submits Verification Code**: Merchant enters the OTP from their authenticator app or SMS. SPA submits the code to UMAPI for verification.
   - From: `merchantCenterWebSPA`
   - To: `continuumUmapi`
   - Protocol: REST / HTTPS (proxied, Bearer token)

8. **UMAPI Confirms Enrollment**: UMAPI validates the OTP and activates 2FA for the merchant account. Returns success status.
   - From: `continuumUmapi`
   - To: `merchantCenterWebSPA`
   - Protocol: REST / HTTPS

9. **SPA Confirms Enrollment Complete**: SPA displays success confirmation. Subsequent logins via Doorman SSO will now require the second factor.
   - From: `merchantCenterWebSPA`
   - To: Merchant (browser)
   - Protocol: Client-side render

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid OTP submitted | UMAPI returns validation error | SPA shows "incorrect code" message; merchant retries |
| OTP expired (TOTP time window passed) | UMAPI returns expiry error | SPA prompts merchant to try the next code |
| UMAPI unavailable during enrollment | react-query mutation error | Error toast; enrollment incomplete; merchant retries later |
| Merchant loses access to 2FA device | Out of scope for this flow | Recovery handled by UMAPI account recovery process |

## Sequence Diagram

```
Merchant -> merchantCenterWebSPA: Navigate to /account/security
merchantCenterWebSPA -> continuumUmapi: GET /account/security-settings
continuumUmapi --> merchantCenterWebSPA: 2FA status (not enrolled)
merchantCenterWebSPA -> Merchant: Render 2FA enrollment UI
Merchant -> merchantCenterWebSPA: Select method + click Enroll
merchantCenterWebSPA -> continuumUmapi: POST /account/2fa/setup
continuumUmapi --> merchantCenterWebSPA: Setup secret / QR code
merchantCenterWebSPA -> Merchant: Display QR code
Merchant -> merchantCenterWebSPA: Enter OTP from authenticator app
merchantCenterWebSPA -> continuumUmapi: POST /account/2fa/verify (OTP)
continuumUmapi --> merchantCenterWebSPA: Enrollment confirmed
merchantCenterWebSPA -> Merchant: Show success; 2FA now active
```

## Related

- Architecture dynamic view: `dynamic-continuum-2fa-enrollment`
- Related flows: [Merchant Login](merchant-login.md), [Merchant Onboarding](merchant-onboarding.md)
