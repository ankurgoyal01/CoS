---
service: "nifi-3pip"
title: "NiFi Node Bootstrap and Startup"
generated: "2026-03-03"
type: flow
flow_name: "nifi-node-startup"
flow_type: synchronous
trigger: "Container start — Docker ENTRYPOINT executes scripts/start-http.sh"
participants:
  - "nifiNode1Bootstrap"
  - "nifiNode1Runtime"
  - "zookeeperCoordinator"
architecture_ref: "dynamic-nifi-3pip"
---

# NiFi Node Bootstrap and Startup

## Summary

When a NiFi node container starts, the custom `start-http.sh` entrypoint script runs before the NiFi process. The script reads environment variables, applies them to NiFi's configuration files using `sed`-based property replacement, generates the `state-management.xml` file, initializes the nifi-cli toolkit properties, and then launches the NiFi JVM process. This ensures that cluster addresses, ZooKeeper connection strings, port assignments, and JVM memory settings are correctly injected into the NiFi runtime at container boot time.

## Trigger

- **Type**: Container lifecycle (Docker ENTRYPOINT)
- **Source**: Kubernetes StatefulSet pod creation or pod restart
- **Frequency**: Once per container lifecycle (each pod start)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Bootstrap Script | Configures NiFi properties and initiates startup | `nifiNode1Bootstrap` / `nifiNode2Bootstrap` / `nifiNode3Bootstrap` |
| NiFi Runtime | Executes ingestion flows and serves APIs after startup completes | `nifiNode1Runtime` / `nifiNode2Runtime` / `nifiNode3Runtime` |
| ZooKeeper Coordinator | Receives cluster registration from NiFi after startup | `zookeeperCoordinator` |

## Steps

1. **Load common utilities**: Sources `scripts/common.sh` to define `prop_replace` and `uncomment` shell functions; exports `nifi_bootstrap_file`, `nifi_props_file`, `nifi_toolkit_props_file`, and `FQDN`.
   - From: Docker ENTRYPOINT (`start-http.sh`)
   - To: Shell environment
   - Protocol: Shell source

2. **Apply JVM heap settings**: If `NIFI_JVM_HEAP_INIT` or `NIFI_JVM_HEAP_MAX` are set, replaces `java.arg.2` (`-Xms`) and `java.arg.3` (`-Xmx`) in `bootstrap.conf`.
   - From: `start-http.sh`
   - To: `$NIFI_HOME/conf/bootstrap.conf`
   - Protocol: File write (`sed -i`)

3. **Configure web and cluster properties**: Replaces NiFi property values in `nifi.properties` for web port/host, cluster node address, cluster protocol port, ZooKeeper connect string, election wait time, and leader election implementation. If `NIFI_WEB_HTTP_PORT` is set, disables HTTPS and enables HTTP mode (clears TLS keystore/truststore properties).
   - From: `start-http.sh` using env vars
   - To: `$NIFI_HOME/conf/nifi.properties`
   - Protocol: File write (`sed -i`)

4. **Initialize nifi-cli toolkit**: Executes `toolkit.sh` to write the nifi-cli properties file (`~/.nifi-cli.nifi.properties`) with base URL, keystore, and truststore entries (empty in HTTP mode).
   - From: `start-http.sh`
   - To: `~/.nifi-cli.nifi.properties`, `~/.nifi-cli.config`
   - Protocol: File write (heredoc)

5. **Generate state-management.xml**: Executes `state-config.sh`, which writes `$NIFI_HOME/conf/state-management.xml` using a heredoc. Configures three providers: `local-provider` (WriteAheadLocalStateProvider, directory `./state/local`, checkpoint 2 mins, 16 partitions), `zk-provider` (ZooKeeperStateProvider using `NIFI_ZK_CONNECT_STRING` and `NIFI_ZK_ROOT_NODE`), and `kubernetes-provider` (KubernetesConfigMapStateProvider using `NIFI_KUBERNETES_CONFIGMAP_NAME_PREFIX`).
   - From: `state-config.sh`
   - To: `$NIFI_HOME/conf/state-management.xml`
   - Protocol: File write (heredoc with env var substitution)

6. **Launch NiFi process**: Executes `$NIFI_HOME/bin/nifi.sh run` in the background, starts tailing `nifi-app.log`, registers TERM/HUP/INT signal handlers for graceful shutdown, and waits on the NiFi PID.
   - From: `start-http.sh`
   - To: `nifiNode1Runtime` (JVM process)
   - Protocol: Shell exec

7. **NiFi connects to ZooKeeper**: After startup, the NiFi runtime connects to ZooKeeper at the configured connect string (`nifi-3pip--zookeeper:2181`) to participate in cluster coordination.
   - From: `nifiNode1Runtime`
   - To: `zookeeperCoordinator`
   - Protocol: ZooKeeper client (port 2181)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `NIFI_ZK_CONNECT_STRING` not set | NiFi starts but cannot join cluster; ZooKeeper state provider has empty connect string | Node remains isolated; cluster does not form |
| ZooKeeper unreachable at startup | NiFi starts but waits up to `NIFI_ELECTION_MAX_WAIT` (5 min) for cluster election | Startup probe may fail after 300s; pod restarts |
| NiFi JVM crash | Kubernetes liveness probe (`/nifi-api/system-diagnostics`) fails after 5 consecutive failures (75s) | Pod is killed and restarted by Kubernetes |
| `state-config.sh` fails to write XML | NiFi cannot read state-management config; startup fails | Pod fails to start; StatefulSet retries |

## Sequence Diagram

```
Docker ENTRYPOINT -> start-http.sh: Execute bootstrap script
start-http.sh -> common.sh: Source utility functions
start-http.sh -> bootstrap.conf: Set JVM heap (Xms/Xmx) via sed
start-http.sh -> nifi.properties: Set web, cluster, ZK properties via sed
start-http.sh -> toolkit.sh: Initialize nifi-cli properties file
toolkit.sh -> ~/.nifi-cli.nifi.properties: Write toolkit config
start-http.sh -> state-config.sh: Generate state-management.xml
state-config.sh -> state-management.xml: Write local/ZK/k8s state providers
start-http.sh -> NiFi Runtime: Launch nifi.sh run (background)
NiFi Runtime -> ZooKeeper Coordinator: Connect and register (port 2181)
ZooKeeper Coordinator --> NiFi Runtime: Acknowledge cluster membership
```

## Related

- Architecture dynamic view: `dynamic-nifi-3pip`
- Related flows: [Cluster Formation and Leader Election](cluster-formation.md)
