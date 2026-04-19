---
service: "gcp-aiaas-cloud-functions"
title: "Deal Revenue Scoring"
generated: "2026-03-03"
type: flow
flow_name: "deal-revenue-scoring"
flow_type: synchronous
trigger: "HTTP POST request with deal title, content, and pds query parameter"
participants:
  - "continuumAiaasDealScoreFunction"
  - "vertexAi"
  - "salesForce"
  - "openAi"
architecture_ref: "components-continuumAiaasDealScoreFunction"
---

# Deal Revenue Scoring

## Summary

The Deal Score flow accepts a deal's title, description text, and PDS category, runs it through a feature extraction pipeline, calls a Vertex AI custom ML model to predict expected revenue, assigns a revenue label (Ace / King / Queen / Jack / Do not show), and generates a deal summary card using OpenAI. This flow supports merchant advisors in evaluating deal quality before publishing.

## Trigger

- **Type**: api-call
- **Source**: Internal merchant advisor tooling calling `POST /` on the Deal Score Cloud Function with deal content and PDS as parameters
- **Frequency**: On-demand (per deal scoring request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Score Cloud Function | Entry point; validates request, orchestrates scoring pipeline | `continuumAiaasDealScoreFunction` |
| Deal Score Request Handler | Handles CORS, parses and validates inputs | `continuumAiaasDealScoreFunction_dealScoreRequestHandler` |
| Feature Extractor | Derives text, readability, and merchant features for ML inference | `continuumAiaasDealScoreFunction_dealScoreFeatureExtractor` |
| Prediction Client | Calls Vertex AI endpoint for revenue prediction | `continuumAiaasDealScoreFunction_dealScorePredictionClient` |
| Response Builder | Assembles final scored response with summary | `continuumAiaasDealScoreFunction_dealScoreResponseBuilder` |
| Vertex AI | Custom ML model predicting deal revenue | `vertexAi` |
| Salesforce CRM | Provides merchant account details used in feature extraction | `salesForce` |
| OpenAI | Generates deal summary card content | `openAi` |

## Steps

1. **Handle CORS preflight**: If method is `OPTIONS`, return 204 with CORS headers immediately.
   - From: Caller
   - To: `continuumAiaasDealScoreFunction`
   - Protocol: REST/HTTPS

2. **Validate required parameters**: Extract and validate `pds` query parameter (required) and JSON body fields `title` and `content` (at least one required). Return `400` errors for missing or invalid inputs.
   - From: `continuumAiaasDealScoreFunction_dealScoreRequestHandler`
   - To: `continuumAiaasDealScoreFunction_dealScoreRequestHandler` (internal)
   - Protocol: direct

3. **Extract features from deal text**: The Feature Extractor derives textual and merchant features: `wordCount`, `titleLengthWords`, `readabilityStructureQuality`, `readabilityInformationClarity`, `redFlags`, `city`, `areaTier`, `fiveStar`. Also reads account information from Salesforce if `accountId` is provided.
   - From: `continuumAiaasDealScoreFunction_dealScoreFeatureExtractor`
   - To: `salesForce` (optional, if `accountId` provided)
   - Protocol: HTTPS REST

4. **Call Vertex AI prediction endpoint**: The Prediction Client sends the feature vector to the Vertex AI endpoint (`prj-grp-aiaas-stable-6113`, `us-central1`, endpoint `1617826906667745280`) and receives a predicted revenue value.
   - From: `continuumAiaasDealScoreFunction_dealScorePredictionClient`
   - To: `vertexAi`
   - Protocol: HTTPS REST (google-cloud-aiplatform SDK)

5. **Classify revenue label**: Map the predicted revenue float to a categorical label using `REVENUE_THRESHOLDS`: Ace (>= 118.11), King (>= 58.96), Queen (>= 25.02), Jack (>= 0.0), Do not show (< 0.0).
   - From: `continuumAiaasDealScoreFunction_dealScorePredictionClient`
   - To: `continuumAiaasDealScoreFunction_dealScoreResponseBuilder`
   - Protocol: direct

6. **Generate deal summary card**: Send deal metadata (category, city, area tier, predicted label, revenue, margin, discount, unit value) to OpenAI to generate a human-readable summary card.
   - From: `continuumAiaasDealScoreFunction_dealScoreResponseBuilder`
   - To: `openAi`
   - Protocol: HTTPS REST (OpenAI Chat Completions API)

7. **Build and return response**: Assemble the scored response containing `title`, `predictedRevenue`, `label`, `pds`, `summary`, `extractedFeatures`, and `metadata`. Return with HTTP 200.
   - From: `continuumAiaasDealScoreFunction`
   - To: Caller
   - Protocol: REST/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing `pds` parameter | Return `400 MISSING_PDS_PARAMETER` | Structured error in full response envelope |
| Empty JSON body | Return `400 INVALID_PAYLOAD` | Structured error in full response envelope |
| Feature extraction failure | Return `500 FEATURE_EXTRACTION_ERROR` | Default feature values and error in response |
| Vertex AI prediction failure | Return `500 MODEL_PREDICTION_ERROR` | Default revenue 0.0, label "Not Available", error in response |
| Summary generation failure | Return `500 SUMMARY_GENERATION_ERROR` | Default summary message, error in response |
| Unexpected exception | Return `500 DEAL_SCORE_INTERNAL_ERROR` | Full default response with error envelope |

The Deal Score function always returns a complete response object even on failure — callers receive the full response shape with error details in the `"error"` field.

## Sequence Diagram

```
Caller -> DealScoreFunction: POST /?pds=X (body: {title, content, ...})
DealScoreFunction -> DealScoreFunction: Validate pds, title/content
DealScoreFunction -> Salesforce: Read account details (if accountId provided)
Salesforce --> DealScoreFunction: Account metadata
DealScoreFunction -> DealScoreFunction: Extract features (wordCount, readability, redFlags...)
DealScoreFunction -> VertexAI: Predict revenue (feature vector)
VertexAI --> DealScoreFunction: predicted_revenue float
DealScoreFunction -> DealScoreFunction: Categorize revenue to label (Ace/King/Queen/Jack)
DealScoreFunction -> OpenAI: Generate summary card
OpenAI --> DealScoreFunction: summary text
DealScoreFunction --> Caller: 200 {title, predictedRevenue, label, summary, extractedFeatures, metadata}
```

## Related

- Architecture dynamic view: `components-continuumAiaasDealScoreFunction`
- Related flows: [AI Deal Structure Generation](ai-deal-structure-generation.md)
