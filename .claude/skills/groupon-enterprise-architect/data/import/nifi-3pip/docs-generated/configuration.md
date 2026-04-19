---
service: "nifi-3pip"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, helm-values, kustomize, config-files]
---

# Configuration

## Overview

nifi-3pip is configured primarily through environment variables injected at container startup. These variables are consumed by the `start-http.sh` entrypoint script, which uses `sed`-based property replacement to write values into `nifi.properties` and `state-management.xml` before launching the NiFi process. Helm values files (per-component, per-environment) provide the authoritative source of environment variable values for Kubernetes deployments. Kustomize overlays apply StatefulSet-level patches on top of the Helm-generated manifests.

## Environment Variables

### NiFi Node Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NIFI_WEB_HTTP_PORT` | HTTP port NiFi listens on | yes | `8080` | helm (`common.yml`) |
| `NIFI_WEB_HTTP_HOST` | HTTP host binding address | no | `$FQDN` | helm (`common.yml` sets `0.0.0.0`) |
| `NIFI_WEB_HTTPS_PORT` | HTTPS port (used when TLS enabled) | no | `8443` | `start-http.sh` |
| `NIFI_WEB_HTTPS_HOST` | HTTPS host binding | no | `$FQDN` | `start-http.sh` |
| `NIFI_WEB_PROXY_HOST` | Proxy host for web UI access through a proxy | no | — | `start-http.sh` |
| `NIFI_WEB_PROXY_CONTEXT_PATH` | Proxy context path | no | — | `start-http.sh` |
| `NIFI_CLUSTER_IS_NODE` | Whether this instance participates in a cluster | yes | `false` | helm (`common.yml` sets `true`) |
| `NIFI_CLUSTER_NODE_PROTOCOL_PORT` | Port for NiFi cluster protocol communication | yes | `8082` | helm (`common.yml`) |
| `NIFI_CLUSTER_NODE_PROTOCOL_MAX_THREADS` | Max threads for cluster protocol | no | `50` | `start-http.sh` |
| `NIFI_CLUSTER_ADDRESS` | Cluster node address (FQDN) | no | `$FQDN` | `start-http.sh` |
| `NIFI_CLUSTER_LEADER_ELECTION_IMPLEMENTATION` | Leader election manager class | no | `CuratorLeaderElectionManager` | `start-http.sh` |
| `NIFI_STATE_MANAGEMENT_PROVIDER_CLUSTER` | Cluster state provider ID | no | `zk-provider` | `start-http.sh` |
| `NIFI_ZK_CONNECT_STRING` | ZooKeeper connection string | yes | — | helm (`common.yml` sets `nifi-3pip--zookeeper:2181`) |
| `NIFI_ZK_ROOT_NODE` | ZooKeeper root node for NiFi state | no | `/nifi` | `start-http.sh` |
| `NIFI_ELECTION_MAX_WAIT` | Max wait time for cluster flow election | no | `5 mins` | helm (`common.yml` sets `5 min`) |
| `NIFI_ELECTION_MAX_CANDIDATES` | Max candidate nodes for election | no | — | `start-http.sh` |
| `NIFI_SENSITIVE_PROPS_KEY` | Encryption key for sensitive NiFi properties | yes | — | helm (`common.yml`) — **must be rotated before production use** |
| `NIFI_JVM_HEAP_INIT` | JVM initial heap size (`-Xms`) | no | — | helm (`common.yml` sets `12g`) |
| `NIFI_JVM_HEAP_MAX` | JVM maximum heap size (`-Xmx`) | no | — | helm (`common.yml` sets `24g`) |
| `NIFI_JVM_DEBUGGER` | Enables JVM debug port (uncomments bootstrap conf entry) | no | — | `start-http.sh` |
| `NIFI_OFFLOAD_TRAP` | Controls node offload trapping behavior | no | `false` | helm (`common.yml`) |
| `NIFI_VARIABLE_REGISTRY_PROPERTIES` | Path(s) to additional NiFi variable registry files | no | — | `start-http.sh` |
| `NIFI_REMOTE_INPUT_HOST` | Remote input host for site-to-site | no | `$FQDN` | `start-http.sh` |
| `NIFI_REMOTE_INPUT_SOCKET_PORT` | Remote input socket port | no | `10000` | `start-http.sh` |
| `NIFI_ANALYTICS_PREDICT_ENABLED` | Enables NiFi back-pressure prediction analytics | no | `false` | `start-http.sh` |
| `NIFI_ANALYTICS_PREDICT_INTERVAL` | Prediction analytics interval | no | `3 mins` | `start-http.sh` |
| `NIFI_ANALYTICS_QUERY_INTERVAL` | Analytics query interval | no | `5 mins` | `start-http.sh` |
| `NIFI_KUBERNETES_CONFIGMAP_NAME_PREFIX` | ConfigMap name prefix for Kubernetes state provider | no | — | `state-config.sh` |
| `CONFIG_FILE` | Path to per-environment config file | no | — | helm (staging/production overlay YAMLs) |
| `OP_NIFI_PROBE_MAX_TIMEOUT` | Max timeout (seconds) for health check curl probe | no | `15` | `health-check.sh` |

### ZooKeeper Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ALLOW_ANONYMOUS_LOGIN` | Allows unauthenticated ZooKeeper client connections | yes | `yes` | helm (`zookeeper/common.yml`) |
| `ZOO_ENABLE_AUTH` | Enables ZooKeeper authentication | no | `no` | `docker-compose.yml` |
| `ZOO_4LW_COMMANDS_WHITELIST` | Permitted four-letter-word commands | no | `srvr, mntr, ruok, stat` | helm (`zookeeper/common.yml`) |
| `ZOO_RECONFIG_ENABLED` | Enables ZooKeeper dynamic reconfiguration | no | `yes` | helm (`zookeeper/common.yml`) |
| `JVMFLAGS` | Additional JVM flags for ZooKeeper | no | `-Dzookeeper.electionPortBindRetry=0` | helm (`zookeeper/common.yml`) |
| `ZK_CLUSTER_SIZE` | Number of ZooKeeper nodes in the ensemble | yes | `3` | helm (`zookeeper/common.yml`) |
| `ZK_FOLLOWER_PORT` | ZooKeeper follower communication port | yes | `2888` | helm (`zookeeper/common.yml`) |
| `ZK_ELECTION_PORT` | ZooKeeper leader election port | yes | `3888` | helm (`zookeeper/common.yml`) |
| `ZOO_AUTOPURGE_INTERVAL` | Auto-purge interval for ZooKeeper snapshots (hours) | no | `2` | helm (`zookeeper/common.yml`) |

> IMPORTANT: `NIFI_SENSITIVE_PROPS_KEY` is currently set to a placeholder value (`MY_SECRET_TO_BE_FIXED_d37!84b8@6`) in both the development `docker-compose.yml` and the Helm `common.yml`. This must be replaced with a properly managed secret before the service goes live. See the comment in `.meta/deployment/cloud/components/nifi/common.yml`.

## Feature Flags

> No evidence found in codebase of feature flags beyond the `NIFI_ANALYTICS_PREDICT_ENABLED` env var which toggles back-pressure prediction (default: `false`).

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/nifi/common.yml` | YAML | Common Helm values for NiFi component deployment |
| `.meta/deployment/cloud/components/nifi/staging-us-central1.yml` | YAML | Staging environment Helm value overrides for NiFi |
| `.meta/deployment/cloud/components/nifi/production-us-central1.yml` | YAML | Production environment Helm value overrides for NiFi |
| `.meta/deployment/cloud/components/zookeeper/common.yml` | YAML | Common Helm values for ZooKeeper component deployment |
| `.meta/deployment/cloud/components/zookeeper/staging-us-central1.yml` | YAML | Staging environment Helm value overrides for ZooKeeper |
| `.meta/deployment/cloud/components/zookeeper/production-us-central1.yml` | YAML | Production environment Helm value overrides for ZooKeeper |
| `$NIFI_HOME/conf/nifi.properties` | Properties | Main NiFi runtime configuration (written at startup by `start-http.sh`) |
| `$NIFI_HOME/conf/state-management.xml` | XML | NiFi state provider configuration (generated at startup by `state-config.sh`) |
| `$NIFI_HOME/conf/bootstrap.conf` | Properties | NiFi bootstrap configuration including JVM args |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `NIFI_SENSITIVE_PROPS_KEY` | Encryption key for sensitive NiFi flow properties (passwords, tokens stored in flow definitions) | k8s-secret (planned — currently hardcoded placeholder) |

> Secret values are NEVER documented. Only names and rotation policies. The `NIFI_SENSITIVE_PROPS_KEY` must be migrated to a Kubernetes Secret before production use.

## Per-Environment Overrides

- **Staging** (`staging-us-central1`): GCP `stable` VPC, 3 replicas, `CONFIG_FILE=/var/groupon/config/cloud/staging-us-central1.yml`
- **Production** (`production-us-central1`): GCP `prod` VPC, 3 replicas, `CONFIG_FILE=/var/groupon/config/cloud/production-us-central1.yml`
- **Local development**: Uses `docker-compose.yml` with host port mappings (nifi-1: 8021, nifi-2: 8022, nifi-3: 8023) and ZooKeeper at `localhost:2181`. `ZOO_ENABLE_AUTH=no` and `ALLOW_ANONYMOUS_LOGIN=yes`.
