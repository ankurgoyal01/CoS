---
service: "gcp-aiaas-cloud-functions"
title: "Merchant Potential Scoring via Google Scraper"
generated: "2026-03-03"
type: flow
flow_name: "merchant-potential-scoring"
flow_type: synchronous
trigger: "HTTP GET request to /google-scraper with accountId or url+merchantName+city"
participants:
  - "continuumAiaasGoogleScraperFunction"
  - "salesForce"
  - "apify"
  - "vertexAi"
  - "openAi"
  - "continuumAiaasTinyUrlApi"
architecture_ref: "components-continuumAiaasGoogleScraperFunction"
---

# Merchant Potential Scoring via Google Scraper

## Summary

The Google Scraper flow collects Google Places data and merchant reviews for a given account, runs feature extraction and ML inference to classify merchant potential (High Potential / Mid-Low Potential / No Potential / Emerging Potential), and writes the result back to the Salesforce account record. It uses either Vertex AI (production) or a LightGBM local model (test mode) for prediction, and classifies sentiment via OpenAI. This flow is the primary mechanism by which Groupon's merchant advisor tooling assesses whether a new merchant is worth pursuing for a deal.

## Trigger

- **Type**: api-call
- **Source**: Internal merchant advisor tooling calling `GET /google-scraper` with merchant identification parameters
- **Frequency**: On-demand (per merchant potential assessment request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Google Scraper Cloud Function | Entry point; validates request, coordinates scraping and scoring | `continuumAiaasGoogleScraperFunction` |
| Google Scraper Request Handler | Parses request parameters and orchestrates the workflow | `continuumAiaasGoogleScraperFunction_googleScraperRequestHandler` |
| Review Collector | Collects Google review and merchant profile data via Apify | `continuumAiaasGoogleScraperFunction_googleScraperReviewCollector` |
| Merchant Potential Scorer | Runs feature extraction and prediction | `continuumAiaasGoogleScraperFunction_googleScraperPotentialScorer` |
| Salesforce Updater | Persists computed merchant potential to Salesforce | `continuumAiaasGoogleScraperFunction_googleScraperSalesforceUpdater` |
| Salesforce CRM | Source of account seed data; target for enrichment write-back | `salesForce` |
| Apify | Provides Google Places and review data via actor tasks | `apify` |
| Vertex AI | Custom ML model for merchant potential classification | `vertexAi` |
| OpenAI | Classifies review sentiment and flags | `openAi` |
| TinyURL API | Shortens review URLs before Salesforce persistence | `continuumAiaasTinyUrlApi` |

## Steps

1. **Parse and validate request**: The Request Handler extracts `accountId`, `url`, `merchantName`, `city`, `state`, `postalCode`, `countryCode`, `pds`, and `test` parameters. Validates that either `accountId` or (`url` or `merchantName`+`city`) is provided.
   - From: Caller
   - To: `continuumAiaasGoogleScraperFunction`
   - Protocol: REST/HTTPS

2. **Authenticate with Salesforce**: If `accountId` is provided, authenticate with Salesforce using username + password + security token to retrieve account details.
   - From: `continuumAiaasGoogleScraperFunction_googleScraperRequestHandler`
   - To: `salesForce`
   - Protocol: HTTPS REST (simple-salesforce)

3. **Collect Google merchant data**: The Review Collector invokes an Apify actor with merchant identification parameters to retrieve Google Places profile, rating, review count, images, and review text.
   - From: `continuumAiaasGoogleScraperFunction_googleScraperReviewCollector`
   - To: `apify`
   - Protocol: HTTPS REST (apify-client)

4. **Classify review sentiment**: OpenAI is called to classify review sentiment and detect flag keywords from the collected review text.
   - From: `continuumAiaasGoogleScraperFunction_googleScraperPotentialScorer`
   - To: `openAi`
   - Protocol: HTTPS REST (OpenAI Chat Completions)

5. **Extract ML features**: The Merchant Potential Scorer extracts the feature vector required by the ML model: `pds_ogp_per_deal`, `reviews_reviewsCount`, `log_5_star`, `log_1_star`, `polarization`, `log_imagesCount`, `area_tier_adj`, `global_pds_star`, `grt_l2_star`, `reviews_score_cat`, `google_merchant_status_encoded`, `grt_l2_cat_name`, `area_Tier`, `fiveStar`.
   - From: `continuumAiaasGoogleScraperFunction_googleScraperPotentialScorer`
   - To: `continuumAiaasGoogleScraperFunction_googleScraperPotentialScorer` (internal)
   - Protocol: direct

6. **Run ML inference**: If `test=true`, uses local LightGBM model; otherwise calls Vertex AI endpoint. Produces a class prediction (0: No Potential, 1: Mid/Low Potential, 2: High Potential) and confidence score.
   - From: `continuumAiaasGoogleScraperFunction_googleScraperPotentialScorer`
   - To: `vertexAi` (or local LightGBM)
   - Protocol: HTTPS REST (google-cloud-aiplatform)

7. **Apply classification logic**: Applies enhanced "Emerging Potential" classification rules: if predicted "No Potential" but OGP > 250, rating > 4, reviews > 5, and has website, reclassify as "Emerging Potential".
   - From: `continuumAiaasGoogleScraperFunction_googleScraperPotentialScorer`
   - To: `continuumAiaasGoogleScraperFunction_googleScraperSalesforceUpdater`
   - Protocol: direct

8. **Shorten URLs**: Review page URLs are shortened via TinyURL API before persistence.
   - From: `continuumAiaasGoogleScraperFunction_googleScraperSalesforceUpdater`
   - To: `continuumAiaasTinyUrlApi`
   - Protocol: HTTPS REST

9. **Update Salesforce account**: The Salesforce Updater writes `Workable_Merchant__c`, `Merchant_Potential_Confidence_GP__c`, `Hero_PDS__c`, and `Location_Tier__c` to the merchant's Salesforce account.
   - From: `continuumAiaasGoogleScraperFunction_googleScraperSalesforceUpdater`
   - To: `salesForce`
   - Protocol: HTTPS REST (simple-salesforce)

10. **Return response**: The scraped data and PDS array are returned to the caller with HTTP 200.
    - From: `continuumAiaasGoogleScraperFunction`
    - To: Caller
    - Protocol: REST/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing required parameters | Return `400 GOOGLESCRAPER_MISSING_INPUT` | Error in `pds` array with empty `scrapedData` |
| Salesforce authentication failure | Log warning; continue without SF authentication | Processing continues; no Salesforce write-back |
| Apify actor failure | Exception caught; `merchantPotential` set to error message string | Response still returned with partial data |
| Vertex AI prediction failure | Exception caught; error message stored in `merchantPotential` field | Response returned without scored potential |
| Salesforce update failure | Log warning; continue processing | Merchant potential not written to CRM but response still returned |

## Sequence Diagram

```
Caller -> GoogleScraperFunction: GET /google-scraper?accountId=X
GoogleScraperFunction -> Salesforce: Authenticate + read account details
Salesforce --> GoogleScraperFunction: Account seed data
GoogleScraperFunction -> Apify: Fetch Google Places profile and reviews
Apify --> GoogleScraperFunction: Reviews, ratings, images, profile data
GoogleScraperFunction -> OpenAI: Classify review sentiment and flags
OpenAI --> GoogleScraperFunction: Sentiment classification
GoogleScraperFunction -> GoogleScraperFunction: Extract feature vector
GoogleScraperFunction -> VertexAI: Predict merchant potential (feature vector)
VertexAI --> GoogleScraperFunction: prediction class + probability
GoogleScraperFunction -> GoogleScraperFunction: Apply Emerging Potential classification rules
GoogleScraperFunction -> TinyURL: Shorten review URLs
TinyURL --> GoogleScraperFunction: Shortened URLs
GoogleScraperFunction -> Salesforce: Update Workable_Merchant__c, Hero_PDS__c, Location_Tier__c
Salesforce --> GoogleScraperFunction: Update confirmation
GoogleScraperFunction --> Caller: 200 {pds: [...], scrapedData: [...]}
```

## Related

- Architecture dynamic view: `components-continuumAiaasGoogleScraperFunction`
- Related flows: [InferPDS Service Extraction](inferpds-service-extraction.md)
