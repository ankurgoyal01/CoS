---
service: "EC_StreamJob"
title: "Spark Job Startup and Colo Selection"
generated: "2026-03-03"
type: flow
flow_name: "spark-job-startup"
flow_type: batch
trigger: "Operator invokes spark-submit with colo, env, and appName arguments"
participants:
  - "continuumEcStreamJob"
  - "sparkStreamingCluster"
  - "kafkaTopicJanusTier2"
architecture_ref: "dynamic-TDMUpdateFlow"
---

# Spark Job Startup and Colo Selection

## Summary

This flow documents how EC_StreamJob initializes when an operator submits the JAR to the YARN cluster via `spark-submit`. The `main()` entry point validates the required colo and env arguments, then delegates to `startJob()` which builds the Spark configuration, creates the `StreamingContext`, selects the correct Kafka broker and topic for the colo, opens the direct Kafka stream, registers the processing pipeline, and starts the streaming loop. The job then runs indefinitely until killed.

## Trigger

- **Type**: manual
- **Source**: Operator executes `spark-submit --class com.groupon.sparkStreamJob.RealTimeJob EC_StreamJob.jar {colo} {env} {appName}` on the Spark job-submitter host
- **Frequency**: On-demand (once per deployment or after job failure/restart)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator | Executes spark-submit command with colo/env/appName args | — |
| EC Stream Job (`RealTimeJob.main`) | Entry point; validates args and calls startJob() | `continuumEcStreamJob` |
| Spark / YARN cluster | Accepts job submission, allocates resources, launches executors | `sparkStreamingCluster` |
| Kafka (`janus-tier2` / `janus-tier2_snc1`) | Stream source opened during initialization | `kafkaTopicJanusTier2` |

## Steps

1. **Validate colo argument**: `main()` checks `args(0)` is either `NA` or `EMEA` (case-insensitive). If invalid, prints usage message and exits with code 0.
   - Internal to `continuumEcStreamJob`

2. **Validate env argument**: `main()` checks `args(1)` is either `staging` or `prod` (case-insensitive). If invalid, prints usage message and exits with code 0.
   - Internal to `continuumEcStreamJob`

3. **Build SparkConf**: Creates a `SparkConf` with `spark.app.name = args(2)` and `spark.driver.maxResultSize = 5g` and `spark.streaming.backpressure.enabled = true`.
   - From: `continuumEcStreamJob`
   - To: `sparkStreamingCluster`
   - Protocol: Spark/YARN resource negotiation

4. **Create StreamingContext**: Instantiates `StreamingContext(conf, Seconds(20))` with a 20-second batch interval.
   - Internal to `continuumEcStreamJob`

5. **Select Kafka parameters**: Based on `colo` argument, resolves:
   - **NA**: broker `kafka.snc1:9092`, group `EC_StreamJobKafKaNAGroup`, client `EC_StreamJobKafKaNA`, topic `janus-tier2`
   - **EMEA**: broker `kafka.dub1:9092`, group `EC_StreamJobKafKaEMEAGroup`, client `EC_StreamJobKafKaEMEA`, topic `janus-tier2_snc1`
   - Both: `fetch.message.max.bytes = 10000000`

6. **Open Kafka direct stream**: Calls `KafkaUtils.createDirectStream[String, Array[Byte], StringDecoder, DefaultDecoder](ssc, kafkaParams, topic)` to create a `DStream` of raw byte arrays.
   - From: `continuumEcStreamJob`
   - To: `kafkaTopicJanusTier2`
   - Protocol: Kafka direct (0.8)

7. **Register processing pipeline**: Chains `.map(_._2)` to extract message bytes, then `.foreachRDD(...)` to register the ingestion-and-TDM-update logic per batch.
   - Internal to `continuumEcStreamJob`

8. **Start streaming context**: Calls `ssc.start()` — YARN allocates executors and the job begins consuming.
   - From: `continuumEcStreamJob`
   - To: `sparkStreamingCluster`
   - Protocol: Spark internal

9. **Await termination**: Calls `Try(ssc.awaitTermination())` — the driver thread blocks here indefinitely, processing 20-second batches until the job is killed via YARN.
   - Internal to `continuumEcStreamJob`

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid colo argument | Prints error message + `System.exit(0)` | Job does not start |
| Invalid env argument | Prints error message + `System.exit(0)` | Job does not start |
| YARN resource unavailable | YARN returns submission error | Job fails to start; operator must retry |
| Kafka broker unreachable at stream creation | Spark throws exception during `createDirectStream` | Job fails to start; operator must verify broker address and retry |
| `awaitTermination` interrupted | `Try` captures the exception | Job exits cleanly after streaming stops |

## Sequence Diagram

```
Operator          -> RealTimeJob:        spark-submit EC_StreamJob.jar {colo} {env} {appName}
RealTimeJob       -> RealTimeJob:        Validate args(0)=colo, args(1)=env
RealTimeJob       -> YARNCluster:        Submit SparkConf (app name, memory, cores)
YARNCluster       --> RealTimeJob:       Executors allocated
RealTimeJob       -> RealTimeJob:        Build kafkaParams + topic from colo
RealTimeJob       -> KafkaBroker:        createDirectStream (topic subscription)
KafkaBroker       --> RealTimeJob:       Stream established
RealTimeJob       -> RealTimeJob:        ssc.start() — begin 20s batch loop
RealTimeJob       -> RealTimeJob:        ssc.awaitTermination() — block driver thread
```

## Related

- Architecture dynamic view: `dynamic-TDMUpdateFlow`
- Related flows: [Janus Event Ingestion and Filtering](janus-event-ingestion.md), [TDM User Data Update](tdm-user-data-update.md)
- Deployment instructions: [Deployment](../deployment.md)
