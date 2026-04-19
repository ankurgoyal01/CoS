---
service: "image-service-config"
title: "Rolling App Node Restart"
generated: "2026-03-03"
type: flow
flow_name: "rolling-app-node-restart"
flow_type: batch
trigger: "Manual operator action to restart Python app workers without dropping in-flight image requests"
participants:
  - "Operator"
  - "continuumImageServiceNginxCacheProxy"
  - "continuumImageServiceAppRuntime"
architecture_ref: "dynamic-imageServiceConfig"
---

# Rolling App Node Restart

## Summary

When the Python `imageservice.py` app nodes need to be restarted (e.g., after a new app code deployment, a config change requiring process restart, or a process crash), operators follow a rolling restart procedure that leverages Nginx upstream switching. Each app node is drained from the Nginx `upstream backend` one at a time using the `disable_appX` Capistrano tasks, safely restarted via Supervisord, and then re-added to the upstream pool. This ensures the cache tier continues to serve cached responses throughout the operation and no client requests are dropped.

## Trigger

- **Type**: manual
- **Source**: Operator (Intl-Infrastructure team) after app code deployment or when app processes become unhealthy
- **Frequency**: On-demand; typically following `cap app` deployments or incident response

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator | Initiates and coordinates the rolling restart procedure | External (human) |
| Capistrano Deploy Pipeline | Executes disable/enable tasks and restart commands | `capistranoDeployPipeline` |
| Backend Proxy (Nginx) | Switches upstream configurations to drain / restore app nodes | `nginxBackendProxy` |
| Image Service App Runtime | Hosts Supervisord-managed Python workers being restarted | `continuumImageServiceAppRuntime` |
| Nginx Proxy Cache Store | Continues serving cache hits throughout the restart | `continuumImageServiceProxyCacheStore` |

## Steps

The rolling restart is performed one app node at a time. With 4 production app nodes (`image-service-app1.snc1` through `app4.snc1`), the procedure is repeated 4 times.

### Per-Node Restart (repeat for app1, app2, app3, app4)

1. **Verify cache is compensating**: Confirm that image request traffic is being served from cache hits (`upstream_cache_status=HIT`) or that the other 3 app nodes can absorb the load for cache misses.
   - From: Operator
   - To: Nginx access log / monitoring dashboard
   - Protocol: Manual verification

2. **Drain target app node from upstream**: Operator runs `cap disable_appX` (where X is 1–4). Capistrano SSHs to all cache nodes and runs:
   ```
   ln -sf upstream-appX-disabled.conf /etc/nginx/upstream.conf
   sudo /usr/local/etc/init.d/nginx reload
   ```
   The `upstream-appX-disabled.conf` file contains all app node ports except those of appX, effectively removing it from the load balancer.
   - From: `capistranoDeployPipeline`
   - To: `continuumImageServiceNginxCacheProxy` (all cache nodes)
   - Protocol: SSH remote command

3. **Confirm target node is drained**: Nginx reloads the new upstream configuration. New requests are no longer forwarded to appX. In-flight requests complete (Nginx does not support graceful drain with `reload`; long-running transforms may be interrupted).
   - From: `continuumImageServiceNginxCacheProxy`
   - To: Operator (via monitoring)
   - Protocol: Nginx reload signal

4. **Operator initiates restart**: Operator runs `cap restart`. Capistrano prompts:
   ```
   "Are you sure you have disabled upstream traffic to [image-service-appX.snc1]? y/n: "
   ```
   Operator enters `y`.
   - From: Operator
   - To: `capistranoDeployPipeline`
   - Protocol: Interactive prompt

5. **Supervisord starts / restarts workers**: Capistrano runs on appX:
   ```
   if [ ! -e /var/groupon/log/image-service/supervisord.pid ]; then
     cd /data/thepoint/current; supervisord
   fi
   cd /data/thepoint/current; supervisorctl restart all
   ```
   Supervisord stops and restarts all 12 `image-service-0` through `image-service-11` processes (ports 8000–8011).
   - From: `capistranoDeployPipeline`
   - To: `continuumImageServiceAppRuntime` (target node)
   - Protocol: SSH remote command

6. **Verify app node is healthy**: Operator checks `cap status` to confirm all 12 supervisord processes on the target node are in `RUNNING` state.
   ```
   cap status
   # Runs: cd /data/thepoint/current; supervisorctl status
   ```
   - From: Operator
   - To: `continuumImageServiceAppRuntime`
   - Protocol: SSH remote command

7. **Re-enable target node in upstream**: Operator runs `cap enable_all`. Capistrano SSHs to all cache nodes and runs:
   ```
   ln -sf upstream-default.conf /etc/nginx/upstream.conf
   sudo /usr/local/etc/init.d/nginx reload
   ```
   All 4 app nodes (48 upstream ports total) are active again.
   - From: `capistranoDeployPipeline`
   - To: `continuumImageServiceNginxCacheProxy` (all cache nodes)
   - Protocol: SSH remote command

8. **Repeat for next app node**: Steps 1–7 are repeated for each of the remaining app nodes.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| App node fails to start after restart | `supervisorctl status` shows `FATAL` or `STOPPED` | Investigate app logs at `/var/groupon/log/image-service/`; do not re-enable node until resolved; keep node excluded from upstream |
| `cap enable_all` run before app is confirmed healthy | App node added back to upstream while processes are not ready | Nginx forwards requests to unhealthy ports; requests may timeout; run `cap disable_appX` again immediately |
| All other app nodes also become unavailable during restart | No backend capacity for cache misses | Cache hits continue; misses return 502; operator must expedite recovery of at least one node |
| SSH failure to cache node during disable/enable | `upstream.conf` symlink not updated on that cache node | Cache node continues routing to the target app node being restarted; operator must resolve SSH access and retry |

## Sequence Diagram

```
Operator -> capistranoDeployPipeline: cap disable_app1
capistranoDeployPipeline -> continuumImageServiceNginxCacheProxy: SSH all cache nodes: ln -sf upstream-app1-disabled.conf /etc/nginx/upstream.conf
capistranoDeployPipeline -> continuumImageServiceNginxCacheProxy: SSH all cache nodes: sudo nginx reload
continuumImageServiceNginxCacheProxy -> nginxBackendProxy: Traffic now routes only to app2, app3, app4 nodes

Operator -> capistranoDeployPipeline: cap restart (enter 'y' at prompt)
capistranoDeployPipeline -> continuumImageServiceAppRuntime: SSH app1: supervisorctl restart all
continuumImageServiceAppRuntime --> Operator: All 12 processes RUNNING (via cap status)

Operator -> capistranoDeployPipeline: cap enable_all
capistranoDeployPipeline -> continuumImageServiceNginxCacheProxy: SSH all cache nodes: ln -sf upstream-default.conf /etc/nginx/upstream.conf
capistranoDeployPipeline -> continuumImageServiceNginxCacheProxy: SSH all cache nodes: sudo nginx reload
continuumImageServiceNginxCacheProxy -> nginxBackendProxy: Traffic routes to all 4 app nodes (48 ports)

note over Operator: Repeat disable/restart/enable for app2, app3, app4
```

## Related

- Architecture dynamic view: No dynamic views modeled yet
- Related flows: [Configuration Deployment](configuration-deployment.md)
- Runbook operations: [Runbook — Restart Service](../runbook.md)
- Deployment reference: [Deployment](../deployment.md)
