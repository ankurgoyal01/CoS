---
service: "groupon-monorepo"
title: "AI Deal Content Generation"
generated: "2026-03-03"
type: flow
flow_name: "ai-deal-content-generation"
flow_type: asynchronous
trigger: "User initiates AI deal generation in AIDG frontend"
participants:
  - "aidgReactFe"
  - "encoreTs"
  - "microservicesPython"
  - "salesForce"
architecture_ref: "dynamic-ai-deal-content-generation"
---

# AI Deal Content Generation

## Summary

This flow covers the AI-driven deal content generation pipeline used by the AIDG (AI Deal Generation) application. A sales representative initiates deal generation through the AIDG React frontend. The system pulls merchant data from Salesforce, scrapes business information from the web, applies AI/ML inference through Python microservices (image classification, merchant quality, content generation), and produces structured deal content using LLM models (OpenAI/Anthropic) via the centralized AI gateway.

## Trigger

- **Type**: user-action
- **Source**: Sales representative initiates AI deal generation in AIDG frontend
- **Frequency**: on-demand, multiple times per day

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| AIDG React Frontend | UI for AI deal generation workflow | `aidgReactFe` |
| AIDG Backend Service | Orchestrates AI pipeline, Salesforce data, MongoDB storage | `encoreTs` (aidg) |
| AI Gateway | Centralized LLM proxy with Langfuse observability | `encoreTs` (_core_system/ai-gateway) |
| AIDG AIaaS Proxy | Proxy to Python AI microservices | `encoreTs` (_tribe_ai/aidg_aiaas) |
| Python Microservices | ML inference (image classification, merchant quality, content) | `microservicesPython` |
| Salesforce Service | Merchant CRM data retrieval | `encoreTs` (_tribe_b2b/salesforce) |
| Salesforce | External CRM platform | `salesForce` |

## Steps

1. **Initiate Generation**: Sales rep selects merchant and starts AI deal creation
   - From: `aidgReactFe`
   - To: `encoreTs` (aidg service)
   - Protocol: REST (generated client)

2. **Fetch Salesforce Data**: Pull merchant details and history from CRM
   - From: `encoreTs` (salesforce service)
   - To: `salesForce`
   - Protocol: REST (jsforce)

3. **Web Scraping**: Scrape merchant website and social media for business context
   - From: `encoreTs` (aidg_aiaas proxy)
   - To: `microservicesPython` (google-scraper, social-scraper, image-scraper)
   - Protocol: REST

4. **Image Classification**: Classify scraped images for deal relevance
   - From: `encoreTs` (aidg_aiaas proxy)
   - To: `microservicesPython` (image-classification)
   - Protocol: REST

5. **Merchant Quality Assessment**: Score merchant quality for deal ranking
   - From: `encoreTs` (aidg_aiaas proxy)
   - To: `microservicesPython` (merchant-quality)
   - Protocol: REST

6. **Publish Quality Event**: Notify downstream of merchant quality completion
   - From: `encoreTs` (aidg service)
   - To: Pub/Sub topic `merchant-quality-completed`
   - Protocol: Encore Pub/Sub

7. **Generate Deal Content**: Use LLM to generate deal text, structure, and options
   - From: `encoreTs` (aidg service)
   - To: `encoreTs` (ai-gateway)
   - Protocol: Internal service call (OpenAI/Anthropic via LangChain)

8. **Store Results**: Persist generated content and inference data
   - From: `encoreTs` (aidg service)
   - To: MongoDB
   - Protocol: Mongoose driver

9. **Publish Inference Event**: Notify of completed AI inference with Salesforce enrichment
   - From: `encoreTs` (aidg service)
   - To: Pub/Sub topic `services-inferred-with-sf-data`
   - Protocol: Encore Pub/Sub

10. **Present to User**: Return generated deal content for review and editing
    - From: `encoreTs` (aidg service)
    - To: `aidgReactFe`
    - Protocol: REST (generated client)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce data unavailable | Continue with available data; flag incomplete | Deal generated with partial context |
| Web scraping failure | Skip scraping; rely on Salesforce and user input | Deal generated without web enrichment |
| Python AI service timeout | Retry with timeout; degrade gracefully | Feature-specific degradation (e.g., no image classification) |
| LLM API failure | Retry with exponential backoff; try alternate model | Generation delayed; user notified |
| MongoDB write failure | Retry; log error | Results may be lost; user can regenerate |

## Sequence Diagram

```
Sales Rep -> AIDG Frontend: Start AI deal generation
AIDG Frontend -> AIDG Service: POST generate deal
AIDG Service -> Salesforce Service: Get merchant data
Salesforce Service -> Salesforce: SOQL query
Salesforce --> AIDG Service: Merchant data
AIDG Service -> AIaaS Proxy: Scrape + classify
AIaaS Proxy -> Python Services: ML inference
Python Services --> AIaaS Proxy: Results
AIDG Service -> AI Gateway: Generate content (LLM)
AI Gateway -> OpenAI/Anthropic: Chat completion
OpenAI/Anthropic --> AI Gateway: Generated text
AIDG Service -> MongoDB: Store results
AIDG Service -> PubSub: services-inferred-with-sf-data
AIDG Service --> AIDG Frontend: Generated deal content
```

## Related

- Architecture dynamic view: `dynamic-ai-deal-content-generation`
- Related flows: [Deal Creation and Publishing](deal-creation-publishing.md), [Salesforce Account Sync](salesforce-account-sync.md)
