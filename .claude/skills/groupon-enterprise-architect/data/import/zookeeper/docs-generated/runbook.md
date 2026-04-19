---
service: "zookeeper"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Four-letter word `ruok` on port 2181 | tcp | Configurable (typically 30s) | Configurable |
| `bin/zkServer.sh status` | exec | On demand | — |
| Admin HTTP `/commands/ruok` | http | Configurable | Configurable |
| Prometheus scrape on port 7000 (if enabled) | http | Configurable | Configurable |

### How to check health manually

```bash
# Via four-letter word (requires netcat or nc)
echo ruok | nc localhost 2181
# Expected response: imok

# Via zkServer.sh
bin/zkServer.sh status
# Shows Mode: leader | follower | observer

# Via CLI
bin/zkCli.sh -server localhost:2181
# Connects and shows "Welcome to ZooKeeper!"
```

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `zk_avg_latency` | gauge | Average request latency in milliseconds | >10 ms (warning); >100 ms (critical) |
| `zk_max_latency` | gauge | Maximum request latency observed | >500 ms (critical) |
| `zk_outstanding_requests` | gauge | Number of queued client requests | >10 (warning); >100 (critical) |
| `zk_num_alive_connections` | gauge | Number of active client sessions | Baseline-dependent |
| `zk_watch_count` | gauge | Total number of active watches | Baseline-dependent |
| `zk_znode_count` | gauge | Total number of znodes in the tree | Baseline-dependent |
| `zk_approximate_data_size` | gauge | Approximate total data size in bytes | Baseline-dependent |
| `zk_followers` | gauge | Number of followers (leader only) | `< quorum_size - 1` (critical) |
| `zk_pending_syncs` | gauge | Number of followers awaiting sync | >0 for extended period |

> Metrics are available via `mntr` four-letter word command or through the `zookeeperPrometheusMetrics` container on port 7000 (when `metricsProvider.className=org.apache.zookeeper.metrics.prometheus.PrometheusMetricsProvider` is configured in `zoo.cfg`).

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| ZooKeeper Ensemble Health | Not specified in repo | Operational procedures to be defined by service owner |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| ZooKeeper not responding | `ruok` returns no response or not `imok` | critical | Restart service; check logs at `ZOO_LOG_DIR` |
| Quorum lost | Leader unavailable; `zk_followers < (ensemble_size / 2)` | critical | Check all ensemble members; restart failed nodes |
| High latency | `zk_avg_latency > 100 ms` for >5 minutes | warning | Check disk I/O on `dataDir`; check network between peers |
| Outstanding requests growing | `zk_outstanding_requests > 100` | warning | Check client connection counts; look for slow clients |
| Low disk on dataDir | Disk usage >80% on `dataDir` volume | warning | Run manual purge via `bin/zkCleanup.sh`; enable autopurge |

## Common Operations

### Start the Server

```bash
bin/zkServer.sh start
# Starts in background; PID written to $dataDir/zookeeper_server.pid
# Logs at $ZOO_LOG_DIR

# Start in foreground (for debugging)
bin/zkServer.sh start-foreground
```

### Stop the Server

```bash
bin/zkServer.sh stop
```

### Restart the Server

```bash
bin/zkServer.sh restart
# Equivalent to stop (waits 3 seconds) then start
```

### Check Server Status

```bash
bin/zkServer.sh status
# Returns: Mode: leader | follower | observer | standalone
```

### Connect via CLI

```bash
bin/zkCli.sh -server localhost:2181
# Interactive shell supporting: ls, get, set, create, delete, stat, setAcl, getAcl
```

### Scale Up / Down

To add a new node to a running ensemble:

1. Provision the new host with ZooKeeper installed.
2. Add `server.N=host:2888:3888` entry to `zoo.cfg` on all ensemble members.
3. Create `$dataDir/myid` with the server ID `N` on the new host.
4. Perform a rolling restart of existing members to pick up the new `zoo.cfg`.
5. Start ZooKeeper on the new host.

### Database Operations

ZooKeeper has no relational database. Snapshot and log management is performed using:

```bash
# Clean up old snapshots and logs (retain last 3 snapshots)
bin/zkCleanup.sh $dataDir -n 3

# View snapshot contents
bin/zkSnapShotToolkit.sh $dataDir/version-2/snapshot.<zxid>

# View transaction log
bin/zkTxnLogToolkit.sh $dataDir/version-2/log.<zxid>
```

## Troubleshooting

### Server not responding to `ruok`

- **Symptoms**: `echo ruok | nc localhost 2181` returns nothing or connection refused
- **Cause**: Server process not running, or port 2181 is blocked
- **Resolution**: Check PID file at `$dataDir/zookeeper_server.pid`; check log at `$ZOO_LOG_DIR/zookeeper-*.out`; run `bin/zkServer.sh status`; restart with `bin/zkServer.sh restart`

### Quorum not formed (ensemble stays in LOOKING state)

- **Symptoms**: `bin/zkServer.sh status` returns "Error contacting service"; logs show repeated leader election messages
- **Cause**: Fewer than a majority of servers are reachable (network partition or node failures)
- **Resolution**: Ensure at least `(N/2) + 1` nodes are running and can reach each other on ports 2888 and 3888; check firewall rules; verify `zoo.cfg` peer addresses are correct

### Disk full — ZooKeeper fails to write transaction log

- **Symptoms**: Server log shows `IOException` on transaction log write; clients receive `CONNECTION_LOSS`
- **Cause**: `dataDir` volume is full; autopurge not configured or insufficient retention
- **Resolution**: Free disk space by manually deleting old snapshots and logs (retain at least the last 3); configure `autopurge.snapRetainCount=3` and `autopurge.purgeInterval=1` in `zoo.cfg`; restart server

### High latency

- **Symptoms**: `zk_avg_latency` elevated; client timeouts increase
- **Cause**: Disk I/O contention on `dataDir`; GC pressure; too many outstanding requests
- **Resolution**: Move `dataLogDir` to a dedicated disk separate from snapshot `dataDir`; increase `ZK_SERVER_HEAP`; tune `tickTime`, `syncLimit` in `zoo.cfg`

### Session expired errors in clients

- **Symptoms**: Clients log `SessionExpiredException`; ephemeral znodes are deleted unexpectedly
- **Cause**: Client could not reconnect within session timeout (configured by client, bounded by server `maxSessionTimeout`)
- **Resolution**: Increase client session timeout; check network stability between clients and ZooKeeper; verify `syncLimit` and `tickTime` allow sufficient time for followers to catch up

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Ensemble completely unavailable — all Continuum coordination broken | Immediate | Continuum Platform SRE |
| P2 | Quorum degraded — one node down, still serving but no fault tolerance | 30 min | Continuum Platform team |
| P3 | Single node lagging; metrics elevated; non-critical functionality affected | Next business day | Continuum Platform team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| JVM (Java 8/11) | Verified via `zkServer.sh status` output | No fallback — JVM required |
| Filesystem (`dataDir`) | Monitor disk usage on `dataDir` volume | No fallback — disk required for durability |
| Network (TCP/2181, 2888, 3888) | Verify port reachability with `nc` or telnet | No fallback — network required for quorum and client connections |
