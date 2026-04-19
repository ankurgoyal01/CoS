---
service: "mds-feed-job"
title: "Multi-Language Translation"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "multi-language-translation"
flow_type: batch
trigger: "Internal — invoked by transformerPipeline when feed definition specifies multi-locale output"
participants:
  - "transformerPipeline"
  - "externalApiAdapters"
architecture_ref: "dynamic-mds-feed-job-feed-generation"
---

# Multi-Language Translation

## Summary

Multi-Language Translation is a sub-flow within the transformer pipeline that translates deal content (titles, descriptions, and other text fields) into target locale languages using the Google Translate API. It is activated when a feed definition requires output in a language not natively available in the MDS snapshot. Translated content is applied back to the Spark dataset before output formatting.

## Trigger

- **Type**: internal (programmatic)
- **Source**: `transformerPipeline` locale/language transformer step, when feed definition specifies a target locale requiring translation
- **Frequency**: Per feed run that targets a non-native-language locale; may be invoked for multiple target languages within a single run

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Transformer Pipeline | Identifies text fields requiring translation; applies translated values back to dataset | `transformerPipeline` |
| External API Adapters | Manages Google Translate API calls, batching, and retry | `externalApiAdapters` |
| Google Translate | Cloud translation service | external |

## Steps

1. **Identify translation requirement**: `transformerPipeline` processes the feed locale transformer step and detects that the target locale requires translation for one or more text fields (e.g., `title`, `description`, `short_title`).
   - From: `transformerPipeline`
   - To: `transformerPipeline` (internal check)
   - Protocol: direct

2. **Extract text fields for translation**: `transformerPipeline` collects distinct text values from the Spark dataset that require translation, deduplicated to minimize API call volume.
   - From: `transformerPipeline`
   - To: in-memory collection
   - Protocol: direct (Spark collect / distinct operation)

3. **Batch translation requests**: `externalApiAdapters` batches text values into translation API requests within Google Translate API limits.
   - From: `externalApiAdapters`
   - To: Google Translate API
   - Protocol: HTTPS/JSON (Google Translate REST API)

4. **Send translation requests to Google Translate**: `externalApiAdapters` submits batched translation requests specifying source language (auto-detect or explicit) and target language.
   - From: `externalApiAdapters`
   - To: Google Translate
   - Protocol: HTTPS/JSON

5. **Receive translated text**: Google Translate returns translated text for each input string in the batch.
   - From: Google Translate
   - To: `externalApiAdapters`
   - Protocol: HTTPS/JSON

6. **Build translation lookup map**: `externalApiAdapters` assembles a source-to-translated-text lookup map and returns it to `transformerPipeline`.
   - From: `externalApiAdapters`
   - To: `transformerPipeline`
   - Protocol: direct (in-process)

7. **Apply translations to Spark dataset**: `transformerPipeline` broadcasts the translation lookup map and applies it to the dataset via UDF to replace source-language text fields with translated values.
   - From: `transformerPipeline`
   - To: Spark dataset (broadcast UDF)
   - Protocol: direct (Spark UDF)

8. **Proceed to output format step**: Dataset with translated fields continues through the standard transformer pipeline output formatting step.
   - From: `transformerPipeline`
   - To: `transformerPipeline` (next transformer step)
   - Protocol: direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Google Translate API unavailable | Failsafe retry with backoff | If retries exhausted, translation step fails; batch fails for translation-required locales |
| Translation API quota exceeded | Failsafe retry after backoff delay | Retry; if quota cannot be satisfied, step fails |
| Partial translation response (some strings not translated) | Log missing translations; use source-language fallback for untranslated fields | Feed published with some untranslated fields; quality degraded |
| Translation result encoding error | Log and skip affected field; use original value | Affected field uses source-language value |

## Sequence Diagram

```
transformerPipeline  -> transformerPipeline  : Detect translation requirement (locale config)
transformerPipeline  -> transformerPipeline  : Extract distinct text values (title, description)
transformerPipeline  -> externalApiAdapters   : Request translation (text[], source_lang, target_lang)
externalApiAdapters  -> GoogleTranslate       : POST /translate (batched text values)
GoogleTranslate     --> externalApiAdapters   : Translated text[]
externalApiAdapters --> transformerPipeline   : Translation lookup map
transformerPipeline  -> transformerPipeline   : Broadcast map + apply UDF to dataset
transformerPipeline  -> transformerPipeline   : Continue to output format step
```

## Related

- Architecture dynamic view: `dynamic-mds-feed-job-feed-generation`
- Related flows: [Transformer Pipeline Execution](transformer-pipeline-execution.md), [Feed Job Orchestration](feed-job-orchestration.md)
