---
service: "mirror-maker-kubernetes"
title: "Startup and Initialization"
generated: "2026-03-03"
type: flow
flow_name: "startup-initialization"
flow_type: synchronous
trigger: "Kubernetes pod start"
participants:
  - "mirrorMaker_envValidator"
  - "mirrorMaker_configWriter"
  - "mirrorMaker_securityBootstrap"
  - "mirrorMaker_runtimeLauncher"
  - "continuumKafkaBroker"
architecture_ref: "components-continuum-mirror-maker-service"
---

# Startup and Initialization

## Summary

When a MirrorMaker pod starts, a sequential Bash-driven initialization pipeline runs before the Java MirrorMaker process is launched. The pipeline validates environment variables, generates producer/consumer property files, creates SSL/TLS keystores and truststores from mounted certificates, and finally invokes the MirrorMaker runtime. This flow runs once per pod lifecycle and must complete successfully for the pod to reach the ready state.

## Trigger

- **Type**: Kubernetes pod start (container entrypoint)
- **Source**: Kubernetes scheduler starting a pod (new deploy, pod restart, HPA scale-out)
- **Frequency**: Once per pod lifetime

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Environment Validator | Validates all required env vars (`SOURCE`, `DESTINATION`, `WHITELIST`, `GROUPID`) and optional ones; applies defaults | `mirrorMaker_envValidator` |
| Config Writer | Generates producer.properties, consumer.properties, and MM2 config files from validated env var values | `mirrorMaker_configWriter` |
| Security Bootstrap | Invokes OpenSSL and keytool to build JKS keystores and truststores from certificates in `/var/groupon/certs`; appends SSL config to property files | `mirrorMaker_securityBootstrap` |
| MirrorMaker Runtime Launcher | Executes `kafka-mirror-maker` with resolved property files and optional custom message handlers | `mirrorMaker_runtimeLauncher` |
| Kafka Cluster (source) | Accepts initial consumer group join and partition assignment | `continuumKafkaBroker` |
| Kafka Cluster (destination) | Accepts initial producer connection | `continuumKafkaBroker` |

## Steps

1. **Validate environment variables**: The Environment Validator reads all env vars from the container environment, checks that `SOURCE`, `DESTINATION`, `WHITELIST`, and `GROUPID` are non-empty, applies default values for optional vars (`COMPRESSION=snappy`, `NUM_STREAMS`, etc.), and exits with an error if required vars are missing.
   - From: `mirrorMaker_envValidator`
   - To: `mirrorMaker_configWriter`
   - Protocol: In-process (Bash variable passing)

2. **Generate property files**: The Config Writer renders producer.properties (with `DESTINATION` as bootstrap servers, `COMPRESSION`, `ACKS`, `LINGER_MS`, `BATCH_SIZE`, `MAX_REQUEST_SIZE`), consumer.properties (with `SOURCE` as bootstrap servers, `GROUPID`, `NUM_STREAMS`, `AUTO_OFFSET_RESET`), and any MirrorMaker2 config files. Files are written to a known path on the container filesystem.
   - From: `mirrorMaker_configWriter`
   - To: `mirrorMaker_securityBootstrap`
   - Protocol: In-process (Bash file I/O)

3. **Bootstrap security material**: If `SOURCE_USE_MTLS=true`, the Security Bootstrap reads the client certificate and key from `/var/groupon/certs`, invokes `keytool` to import into a JKS keystore, and appends `ssl.keystore.*` and `ssl.truststore.*` settings to consumer.properties. The same process is applied for the destination side if `DESTINATION_USE_MTLS=true`.
   - From: `mirrorMaker_securityBootstrap`
   - To: `mirrorMaker_runtimeLauncher`
   - Protocol: In-process (Bash file I/O, keytool/OpenSSL system calls)

4. **Launch MirrorMaker runtime**: The Runtime Launcher invokes `kafka-mirror-maker` with the consumer and producer property files. If `IS_JANUS_FORWARDER=true`, a custom message handler class is added to the command line for topic renaming. The Java process takes over and begins the consumer-producer replication loop.
   - From: `mirrorMaker_runtimeLauncher`
   - To: `continuumKafkaBroker` (source and destination)
   - Protocol: Kafka native protocol (TCP/mTLS)

5. **Consumer group join**: MirrorMaker connects to the source broker, joins the consumer group (`GROUPID`), and receives partition assignments for the whitelisted topics.
   - From: `continuumMirrorMakerService`
   - To: `continuumKafkaBroker` (source)
   - Protocol: Kafka consumer group protocol

6. **Producer connection**: MirrorMaker connects to the destination broker and initializes the producer for replication output.
   - From: `continuumMirrorMakerService`
   - To: `continuumKafkaBroker` (destination)
   - Protocol: Kafka producer protocol

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing required env var | Environment Validator exits with non-zero code | Pod fails to start; Kubernetes restarts pod (CrashLoopBackOff) |
| Certificate not found in `/var/groupon/certs` | Security Bootstrap exits with non-zero code | Pod fails to start; check `client-certs` volume mount |
| Kafka broker unreachable at startup | MirrorMaker Kafka client retries with backoff | Pod stays running but assigned-partitions = 0; liveness probe continues to pass (pgrep java) |
| keytool/OpenSSL error | Security Bootstrap exits | Pod fails to start; review certificate format |

## Sequence Diagram

```
EnvValidator -> ConfigWriter: Pass validated env var values
ConfigWriter -> SecurityBootstrap: Write consumer/producer property files
SecurityBootstrap -> SecurityBootstrap: Build JKS keystore/truststore from /var/groupon/certs
SecurityBootstrap -> RuntimeLauncher: Provide final property files and SSL material
RuntimeLauncher -> KafkaBroker(source): Consumer group join + partition assignment
RuntimeLauncher -> KafkaBroker(destination): Producer connect
KafkaBroker(source) --> RuntimeLauncher: Partition assignments confirmed
KafkaBroker(destination) --> RuntimeLauncher: Producer ready
```

## Related

- Architecture dynamic view: `dynamic-mirror-maker-replication-flow`
- Component diagram: `components-continuum-mirror-maker-service`
- Related flows: [Topic Replication](topic-replication.md)
