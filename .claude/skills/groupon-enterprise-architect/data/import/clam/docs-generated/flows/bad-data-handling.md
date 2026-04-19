---
service: "clam"
title: "Bad Data Handling Flow"
generated: "2026-03-03"
type: flow
flow_name: "bad-data-handling"
flow_type: event-driven
trigger: "A malformed or incomplete histogram event is received from the Kafka input topic"
participants:
  - "continuumClamSparkStreamingJob"
  - "clamKafkaIoAdapter"
  - "clamHistogramAggregator"
architecture_ref: "dynamic-clamHistogramAggregationFlow"
---

# Bad Data Handling Flow

## Summary

When CLAM encounters a histogram event that cannot be decoded or that is missing required fields, it silently discards the record and increments an operational counter metric. This validation occurs inline within the `mapPartitions` step of the streaming pipeline. There is no dead-letter queue; bad records are filtered before the aggregation state is touched. The bad-data metric (`custom.clam.bad-data`) provides observability into the rate of malformed upstream events.

## Trigger

- **Type**: event-driven
- **Source**: A Kafka message on `metrics_histograms_v2` (or `histograms_v2` in staging) with an invalid JSON payload, null fields/tags map, or missing required tag/field keys
- **Frequency**: Per malformed event; occurs as part of normal micro-batch processing

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kafka I/O Adapter | Reads the raw string value from Kafka | `clamKafkaIoAdapter` |
| Histogram Aggregator | Invokes mapPartitions; orchestrates decode-and-filter | `clamHistogramAggregator` |
| TDigestDecoder | Parses JSON and validates required fields; marks bad records | Component of `clamHistogramAggregator` (class `TDigest.TDigestDecoder`) |
| Metrics Gateway | Receives `bad-data` counter increment | External (`unknownMetricsGatewayEndpoint_18b7c61a`) |

## Steps

1. **Receive raw string from Kafka**: `KafkaIO.read()` delivers the Kafka `value` as a UTF-8 string to each Spark executor partition.
   - From: Kafka input topic
   - To: `clamKafkaIoAdapter`
   - Protocol: Kafka consumer

2. **Attempt JSON parse**: `TDigest.TDigestDecoder.fromString()` calls `gson.fromJson(toParse, TDigest.class)`. If parsing throws any exception (invalid JSON, type mismatch), a new empty `TDigest` is created and `setAsBadData()` is called on it.
   - From: `clamHistogramAggregator` (mapPartitions)
   - To: `TDigestDecoder`
   - Protocol: in-process

3. **Validate completeness**: After a successful Gson parse, the decoder checks that `output.fields` and `output.tags` are not null. If either is null, `setAsBadData()` is called.
   - From: `TDigestDecoder`
   - To: `TDigest` object
   - Protocol: in-process

4. **Validate required keys**: The decoder checks for the presence of `compression` in `fields` and `service`, `aggregates`, `bucket_key` in `tags`. If any are absent, `setAsBadData()` is called.
   - From: `TDigestDecoder`
   - To: `TDigest` object
   - Protocol: in-process

5. **Mark bad data and emit metric**: `TDigest.setAsBadData()` sets `this.badData = true`, calls `MetricsUtil.inc("bad-data", clamConfig)` to increment the counter, and logs a WARN-level message with the raw input string.
   - From: `TDigestDecoder`
   - To: Metrics Gateway (via `MetricsSubmitter`)
   - Protocol: HTTP (InfluxDB line protocol)

6. **Filter bad records**: Back in the streaming pipeline, `filter(TDigest::isGoodData)` removes all records where `badData == true`. These records do not enter the watermarking, grouping, or state aggregation steps.
   - From: `clamHistogramAggregator`
   - To: Remaining valid stream
   - Protocol: Spark Dataset filter (in-process)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| JSON parse exception | `setAsBadData()` + warn log + `bad-data` metric increment; record filtered | Record silently discarded; pipeline continues |
| Null `fields` or `tags` map | Same as above | Record silently discarded; pipeline continues |
| Missing required field/tag key | Same as above | Record silently discarded; pipeline continues |
| 100% bad-data rate | All records filtered; no aggregates emitted; `bad-data` metric spikes | Alert on `bad-data` rate spike; investigate upstream producer |

## Sequence Diagram

```
Kafka -> KafkaIO: raw string value
KafkaIO -> TDigestDecoder: fromString(rawString, config)
TDigestDecoder -> TDigestDecoder: gson.fromJson() — attempt JSON parse
alt parse fails
  TDigestDecoder -> TDigest: setAsBadData(rawString, config, exception)
  TDigest -> MetricsSubmitter: inc("bad-data")
  MetricsSubmitter -> MetricsGateway: POST bad-data counter
  TDigestDecoder --> HistogramAggregator: TDigest{badData=true}
else parse succeeds
  TDigestDecoder -> TDigest: validate fields/tags not null and required keys present
  alt validation fails
    TDigest -> MetricsSubmitter: inc("bad-data")
    MetricsSubmitter -> MetricsGateway: POST bad-data counter
    TDigestDecoder --> HistogramAggregator: TDigest{badData=true}
  else validation passes
    TDigestDecoder --> HistogramAggregator: TDigest{badData=false, tdigest=MergingDigest}
  end
end
HistogramAggregator -> HistogramAggregator: filter(TDigest::isGoodData) — drops bad records
```

## Related

- Architecture dynamic view: `dynamic-clamHistogramAggregationFlow`
- Related flows: [Histogram Aggregation](histogram-aggregation.md)
- Runbook: [Bad data spike troubleshooting](../runbook.md)
