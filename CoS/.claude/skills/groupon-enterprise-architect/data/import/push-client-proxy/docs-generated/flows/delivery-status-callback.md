---
service: "push-client-proxy"
title: "Delivery Status Callback"
generated: "2026-03-03"
type: flow
flow_name: "delivery-status-callback"
flow_type: asynchronous
trigger: "msys_delivery Kafka topic event"
participants:
  - "continuumKafkaBroker"
  - "continuumPushClientProxyService"
  - "continuumPushClientProxyRedisPrimary"
architecture_ref: "dynamic-email-request-flow"
---

# Delivery Status Callback

## Summary

When the SparkPost/Momentum email platform (via Bloomreach) delivers or fails an email, it writes a CSV-format delivery status event to the `msys_delivery` Kafka topic. push-client-proxy consumes these events, looks up the original email metadata from Redis, and dispatches an HTTP callback to the Bloomreach webhook endpoint to report delivery status back to the upstream system.

## Trigger

- **Type**: event
- **Source**: `continuumKafkaBroker` publishing to the `msys_delivery` topic
- **Frequency**: Per email delivery event (asynchronous, continuous)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kafka Broker | Event source — delivers `msys_delivery` CSV messages | `continuumKafkaBroker` |
| push-client-proxy service | Consumer — parses event, looks up metadata, dispatches callback | `continuumPushClientProxyService` |
| Primary Redis cache | Metadata store — provides `from`, `to`, `customData`, `requestId` by `userId`+`sendId` | `continuumPushClientProxyRedisPrimary` |
| Bloomreach webhook | HTTP callback target — receives delivery status event | (external HTTP endpoint) |

## Steps

1. **Receives batch of delivery-status messages**: `KafkaMessageListener.listenToMsysDelivery` receives a batch of CSV-format messages from the `msys_delivery` topic on the `batchKafkaListenerContainerFactory` (1 record per poll, manual acknowledgment).
   - From: `continuumKafkaBroker`
   - To: `continuumPushClientProxyService` (`pcpKafkaDeliveryListener`)
   - Protocol: Kafka (SSL/TLS), consumer group `email-search-processor-group`

2. **Extracts sendId and userId from CSV**: For each message, `CsvFieldExtractor.extractFields(message, topic)` parses the CSV row and extracts the `sendId` (field index 31) and `userId` (field index 29) for the `msys_delivery` topic.
   - From: `pcpKafkaDeliveryListener`
   - To: (internal `CsvFieldExtractor`)
   - Protocol: direct

3. **Looks up email metadata from Redis**: Calls `RedisUtil.getEmailDetails(userId, sendId)` to retrieve the `from`, `to`, `customData`, and `requestId` stored when the original email was injected.
   - From: `pcpKafkaDeliveryListener`
   - To: `continuumPushClientProxyRedisPrimary` (via `pcpRedisUtil`)
   - Protocol: Redis

4. **Builds delivery callback event**: Constructs a delivery event map with `timestamp`, `from`, `to`, `customData`, `requestId`, `status` (hardcoded `"delivered"`), and `userId`.
   - From: `pcpKafkaDeliveryListener`
   - To: (internal)
   - Protocol: direct

5. **Posts callback to downstream endpoint**: Calls `EmailApiTemplate.sendEmail(emailRequest)` which POSTs the batch of delivery events to the Bloomreach webhook URL.
   - From: `pcpKafkaDeliveryListener` (via `pcpEmailApiTemplate`)
   - To: Bloomreach webhook (`https://groupon-api.bloomreach.co/channels/hook/email/customemail/...`)
   - Protocol: HTTPS (REST POST)

6. **Acknowledges Kafka messages**: If all messages in the batch were successfully processed (indices match total count), calls `acknowledgment.acknowledge()` to commit offsets.
   - From: `pcpKafkaDeliveryListener`
   - To: `continuumKafkaBroker`
   - Protocol: Kafka

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| CSV parse failure | Message index tracked as processed; acknowledgment proceeds | Message not retried; no callback sent for this message |
| Redis lookup returns no data (userId+sendId not in cache) | Message index tracked as processed; acknowledgment proceeds | Message not retried; no callback sent |
| Missing `from` or `to` fields in Redis data | Message index tracked as processed; acknowledgment proceeds | Message not retried; no callback sent |
| HTTP callback (`EmailApiTemplate`) failure | Exception caught and logged; no re-throw; acknowledgment proceeds | Callback lost; no retry mechanism for callback failures |
| Unexpected exception during batch processing | Acknowledgment withheld; logged as error | Kafka retries entire batch |
| Partial batch: some messages processed, some not | Acknowledgment withheld for the batch | Kafka retries the entire batch (previously processed messages re-processed) |

## Sequence Diagram

```
KafkaBroker -> KafkaMessageListener: msys_delivery batch (CSV messages)
KafkaMessageListener -> CsvFieldExtractor: extractFields(message, "msys_delivery")
CsvFieldExtractor --> KafkaMessageListener: {sendId, userId}
KafkaMessageListener -> RedisUtil: getEmailDetails(userId, sendId)
RedisUtil -> PrimaryRedis: HGET userId:sendId
PrimaryRedis --> RedisUtil: {from, to, customData, requestId}
RedisUtil --> KafkaMessageListener: emailDetails map
KafkaMessageListener -> EmailApiTemplate: sendEmail(eventBatch)
EmailApiTemplate -> BloomreachWebhook: POST /channels/hook/email/... {events[]}
BloomreachWebhook --> EmailApiTemplate: 200 OK
EmailApiTemplate --> KafkaMessageListener: success
KafkaMessageListener -> KafkaBroker: acknowledge()
```

## Related

- Architecture dynamic view: `dynamic-email-request-flow`
- Related flows: [Email Send Request](email-send-request.md)
