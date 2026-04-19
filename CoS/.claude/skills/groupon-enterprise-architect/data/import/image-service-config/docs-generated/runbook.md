---
service: "image-service-config"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /heartbeat.txt` (default server block, port 80) | HTTP 200 | Load balancer interval | — |
| `GET /nginx_status` (127.0.0.1:80) | HTTP stub_status | Manual / monitoring agent | — |
| `/var/groupon/nginx/heartbeat/heartbeat.txt` file existence | Filesystem | Load balancer check | — |

### Cache node LB inclusion

A cache node is in the load balancer pool when `/var/groupon/nginx/heartbeat/heartbeat.txt` exists. This file is created/removed by Capistrano tasks:
- Add to LB: `cap add_cache_to_lb` — runs `sudo touch /var/groupon/nginx/heartbeat/heartbeat.txt`
- Remove from LB: `cap remove_cache_from_lb` — runs `sudo rm /var/groupon/nginx/heartbeat/heartbeat.txt`

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `upstream_cache_status` | Label (nginx log field) | Logged in access log: HIT / MISS / EXPIRED / BYPASS | Monitor HIT rate — alert if MISS rate spikes significantly |
| `upstream_response_time` | Gauge (nginx log field) | Backend app response time per request | Alert if p99 exceeds acceptable latency SLA |
| `request_time` | Gauge (nginx log field) | Total request processing time including cache lookup | Alert if increasing unexpectedly |
| Active Nginx connections | Gauge (nginx stub_status) | Available at `GET /nginx_status` on 127.0.0.1 | Alert if approaching `worker_connections` limit (16384) |
| Nginx proxy cache disk usage | Gauge | `/var/nginx_proxy_cache` filesystem utilization | Alert at 90% of `max_size` (79 GB production, 100 GB UAT) |

### Dashboards

> Operational details to be defined by service owner — no dashboard configuration present in this repository.

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Cache node removed from LB | Heartbeat file missing | critical | Investigate nginx health; re-add with `cap add_cache_to_lb` after confirming nginx is healthy |
| S3 failover active | Traffic routing to `image-service-west.s3.amazonaws.com` | warning | Investigate AWS S3 us-east status; monitor latency from backup region |
| All backend app upstreams unavailable | Nginx returns 502/504 for all image requests | critical | Check app nodes via `cap status`; restart with `cap restart` if needed |
| Nginx proxy cache disk full | `/var/nginx_proxy_cache` at 100% | critical | Run `purge_nginx_proxy_cache.py` with appropriate regex to free space |

## Common Operations

### Reload Nginx Configuration (no downtime)

After deploying new nginx config via Capistrano, or to apply manual changes:

```bash
sudo /usr/local/etc/init.d/nginx reload
```

This is equivalent to `nginx -s reload` and applies new configuration without dropping active connections.

### Deploy New Configuration (cache nodes)

```bash
cap nginx
```

Renders ERB templates, SCPs all nginx conf files to cache nodes, and reloads nginx on each node. Run from the `image-service-config` repo root.

### Deploy New Configuration (app nodes)

```bash
cap app
```

Deploys app code and uploads `supervisord.conf` + `config.yml` to all production app nodes.

### Restart App Nodes (safely, rolling)

1. Remove app node from backend upstream (disable in nginx):
   ```
   cap disable_app1
   ```
2. Confirm upstream traffic is no longer reaching the node.
3. Restart supervisord workers on that node:
   ```
   cap restart
   # (Capistrano will prompt: "Are you sure you have disabled upstream traffic to [host]? y/n")
   # Enter 'y'
   ```
4. Re-enable the node in upstream:
   ```
   cap enable_all
   ```
5. Repeat for each app node (`disable_app2`, `disable_app3`, `disable_app4`).

### Check App Node Process Status

```bash
cap status
# Runs: cd /data/thepoint/current; supervisorctl status
```

### Purge Nginx Proxy Cache

Use `purge_nginx_proxy_cache.py` to remove cache entries matching a URL pattern:

```bash
sudo python purge_nginx_proxy_cache.py [regex]
# Example: sudo python purge_nginx_proxy_cache.py "450x300/abc123"
# Script will prompt for each matching cache file: "remove /var/nginx_proxy_cache/xx/yy/... ? [y/n]"
```

### Add/Remove Client API Key or Allowed Sizes

1. Edit `config.yml` — add or modify a client entry under `clients:` with `api_key` and `allowed_sizes`.
2. Run `python consolidate_all_allowed_sizes.py` to regenerate `consolidated_config.yml` (optional, for auditing the full allowed-size union).
3. Deploy updated config to app nodes: `cap app` (or `cap app1_uat` for UAT).

### Add Cache Node to Production

1. Add the new hostname to the `production_cache` array in the `Capfile` `nginx` task.
2. Run `cap nginx` to distribute configuration.
3. Run `cap add_cache_to_lb` to add the node to the LB pool.

## Troubleshooting

### High 404 Cache Pollution
- **Symptoms**: Nginx cache disk fills faster than expected; `/nginx_status` shows high request volume but low bytes sent
- **Cause**: `proxy_cache_valid 404 1m` caches 404 responses for 1 minute. If upstream returns many 404s under load, these accumulate on disk.
- **Resolution**: Investigate why upstream is returning 404s. Check app node health via `cap status`. Consider adjusting `proxy_cache_valid` if 404 storm is external.

### Backend App Upstream Failure (502/504)
- **Symptoms**: Clients receive 502 or 504 errors for all non-cached images
- **Cause**: All Python worker processes on all app nodes are down or not responding within `proxy_read_timeout 30s`
- **Resolution**: Run `cap status` to check supervisord process state. If processes are down, run `cap restart` with upstream disabled first (`cap disable_appX`). Check app logs at `/var/groupon/log/image-service/`.

### S3 Origin Unreachable
- **Symptoms**: Cache misses result in 502 errors; nginx error log shows upstream connection failures to `image-service.s3.amazonaws.com`
- **Cause**: AWS S3 us-east outage or network connectivity issue from SNC1
- **Resolution**: Verify `s3-proxy.conf` backup server (`image-service-west.s3.amazonaws.com`) is active. Nginx will passively failover. Check AWS service health dashboard.

### Nginx Config Syntax Error After Deployment
- **Symptoms**: Nginx reload fails; all image requests fail after a `cap nginx` run
- **Cause**: ERB template rendering produced invalid nginx config syntax
- **Resolution**: SSH to a cache node, run `sudo nginx -t` to test config. Review the rendered `nginx.conf` at `/var/groupon/nginx/conf/current/nginx.conf`. Roll back by symlinking a previous release: `ln -sf /var/groupon/nginx/conf/releases/[previous]/nginx.conf /etc/nginx/nginx.conf` and reload.

### Disk Full on Nginx Proxy Cache
- **Symptoms**: Nginx returns 500/502 for new requests; disk usage at 100% on cache node
- **Cause**: `max_size=79000m` limit not enforced quickly enough; or inactive cleanup interval not running
- **Resolution**: Run `purge_nginx_proxy_cache.py` with a broad regex to free space. Nginx will also auto-evict LRU entries eventually. Consider reducing `inactive` period from 30d if disk pressure is chronic.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | All image delivery failing (cache + backend) | Immediate | Intl-Infrastructure on-call |
| P2 | Partial image delivery degraded (high miss rate, slow backend) | 30 min | Intl-Infrastructure on-call |
| P3 | Single app node down, cache compensating | Next business day | Intl-Infrastructure team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Image Service App (`global-image-service-app-vip:80`) | `cap status` on app nodes; nginx upstream error rate | Cache serves hits; misses return 502 |
| AWS S3 Primary (`image-service.s3.amazonaws.com`) | AWS Service Health Dashboard; nginx error log | Auto-failover to `image-service-west.s3.amazonaws.com` via nginx upstream backup |
| AWS S3 Failover (`image-service-west.s3.amazonaws.com`) | AWS Service Health Dashboard | No further fallback — requests fail |
