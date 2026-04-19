---
service: "merchant-center-web"
title: "Deal Creation"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "deal-creation"
flow_type: synchronous
trigger: "Merchant initiates new deal/campaign creation from the dashboard"
participants:
  - "merchantCenterWebSPA"
  - "continuumUmapi"
  - "AIaaS"
  - "Bynder"
architecture_ref: "dynamic-continuum-deal-creation"
---

# Deal Creation

## Summary

The deal creation flow allows merchants to compose a new deal or campaign and submit it for Groupon review. The merchant fills out a multi-section form including deal details, pricing, scheduling, and imagery. Images are classified by AIaaS before submission, and merchants may select assets from Bynder. The completed deal payload is submitted to UMAPI, which routes it through Groupon's backend approval pipeline.

## Trigger

- **Type**: user-action
- **Source**: Merchant clicks "Create Deal" or equivalent CTA on the dashboard or deal management list.
- **Frequency**: On-demand.

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Authors deal content, uploads images, sets pricing | N/A (human actor) |
| Merchant Center Web SPA | Renders deal form, orchestrates image upload/classification, submits deal | `merchantCenterWebSPA` |
| UMAPI | Receives and persists the deal, routes to approval pipeline | `continuumUmapi` |
| AIaaS | Classifies uploaded deal images for content compliance | AIaaS (external) |
| Bynder | Provides pre-approved digital asset library for image selection | Bynder (external) |

## Steps

1. **Render Deal Creation Form**: SPA renders the deal creation form using react-hook-form with zod validation schema. Form sections include deal details, description, pricing, scheduling, and media.
   - From: `merchantCenterWebSPA`
   - To: Merchant (browser)
   - Protocol: Client-side render

2. **Merchant Populates Deal Fields**: Merchant enters deal title, description, pricing tiers, redemption rules, and scheduling window.
   - From: Merchant (browser)
   - To: `merchantCenterWebSPA` (form engine)
   - Protocol: In-browser (direct)

3. **Merchant Selects or Uploads Image**: Merchant either selects a pre-approved asset from the Bynder picker or uploads a new image file.
   - From: Merchant (browser)
   - To: `merchantCenterWebSPA`
   - Protocol: In-browser (direct)

4. **Fetch Assets from Bynder (if using DAM)**: SPA calls the proxied Bynder endpoint to list available assets in the merchant's library.
   - From: `merchantCenterWebSPA`
   - To: Bynder (proxied)
   - Protocol: REST / HTTPS

5. **Submit Image to AIaaS for Classification**: SPA uploads the selected/uploaded image to the proxied AIaaS endpoint. AIaaS returns a classification result (approved / flagged).
   - From: `merchantCenterWebSPA`
   - To: AIaaS (proxied)
   - Protocol: REST / HTTPS

6. **Client-Side Form Validation**: SPA runs zod schema validation across all form sections before submission. Inline errors are displayed for any invalid fields.
   - From: `merchantCenterWebSPA` (form engine)
   - To: Merchant (browser)
   - Protocol: In-browser (direct)

7. **Submit Deal to UMAPI**: SPA posts the validated deal payload to UMAPI. Payload includes all deal fields plus image references and AIaaS classification result.
   - From: `merchantCenterWebSPA`
   - To: `continuumUmapi`
   - Protocol: REST / HTTPS (proxied, Bearer token)

8. **UMAPI Acknowledges Submission**: UMAPI creates the deal record and returns a deal ID and initial status (e.g., "pending review").
   - From: `continuumUmapi`
   - To: `merchantCenterWebSPA`
   - Protocol: REST / HTTPS

9. **SPA Confirms Submission to Merchant**: SPA displays a success notification and navigates the merchant to the deal detail or deal list view.
   - From: `merchantCenterWebSPA`
   - To: Merchant (browser)
   - Protocol: Client-side render / route transition

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Client-side validation failure | zod schema blocks submission; inline errors displayed | Merchant corrects fields |
| AIaaS classification rejects image | SPA displays image policy error | Merchant must select a different image |
| AIaaS service unavailable | SPA proceeds without classification or shows warning | Deal submission may proceed with manual review flag (UMAPI-dependent behavior) |
| Bynder picker fails to load | Error state in asset picker component | Merchant falls back to direct upload |
| UMAPI submission fails | react-query mutation error; error toast displayed | Merchant can retry; form state preserved |

## Sequence Diagram

```
Merchant -> merchantCenterWebSPA: Initiate deal creation
merchantCenterWebSPA -> Merchant: Render deal creation form
Merchant -> merchantCenterWebSPA: Fill deal fields + upload/select image
merchantCenterWebSPA -> Bynder: GET /assets (optional Bynder picker)
Bynder --> merchantCenterWebSPA: Asset list
merchantCenterWebSPA -> AIaaS: POST /classify (image data)
AIaaS --> merchantCenterWebSPA: Classification result (approved/flagged)
merchantCenterWebSPA -> merchantCenterWebSPA: Validate full form with zod
merchantCenterWebSPA -> continuumUmapi: POST /deals (deal payload)
continuumUmapi --> merchantCenterWebSPA: Deal ID + status "pending review"
merchantCenterWebSPA -> Merchant: Show success confirmation
```

## Related

- Architecture dynamic view: `dynamic-continuum-deal-creation`
- Related flows: [Merchant Onboarding](merchant-onboarding.md), [Report Generation](report-generation.md)
