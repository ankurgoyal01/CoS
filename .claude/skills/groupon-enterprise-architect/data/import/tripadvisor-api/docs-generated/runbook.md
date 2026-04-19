---
service: "tripadvisor-api"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/resources/status.json` (port 8080) | http | Per Nagios config | Not documented |
| `/resources/manage/heartbeat` | http (heartbeat file) | Continuous via heartbeat daemon | Not documented |
| `gpn-mgmt.py status` | exec | Manual / Nagios | Not documented |

The heartbeat is served by an in-application controller backed by a file at `/var/groupon/run/ta-api/heartbeat.txt`. If the file is present and the application responds with HTTP 200, the host is considered live in the load balancer.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Response time (1 hotel) | histogram | End-to-end latency for single-hotel availability requests | Warning: >200 ms avg; Critical: >300 ms max |
| Response time (10 hotels) | histogram | End-to-end latency for 10-hotel requests | Warning: >250 ms avg; Critical: >500 ms max |
| Request rate | counter | Total RPM across all availability endpoints | Warning/Critical thresholds configured in Splunk |
| Error rate | gauge | Percentage of 4xx/5xx responses | Warning: >10%; Critical: >15% |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| snc1 Getaways Affiliate | Wavefront | `https://groupon.wavefront.com/dashboard/snc1-getaways_affiliate-snc1` |
| sac1 Getaways Affiliate | Wavefront | `https://groupon.wavefront.com/dashboard/sac1-getaways_affiliate-sac1` |
| dub1 Getaways Affiliate | Wavefront | `https://groupon.wavefront.com/dashboard/dub1-getaways_affiliate-dub1` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| `api_heartbeat` | API not accessible / heartbeat returning non-200 | P1 (high — bleeding money) | Restart Apache Tomcat; see Restart procedure below |
| CPU high | Elevated CPU load on app host | P5 (low — preventative) | Check for JVM GC pauses first; investigate high load; notify Affiliates Team |
| `load` | High IO load | P5 | Investigate IOStat; notify Affiliates Team |
| `mem` / `swap` | High memory or swap usage | P5 | Check for GC issues; check for OOM (`PermgenSpace`); restart Tomcat if needed |
| `disk_space` | Disk utilization above threshold | P5 | Clear old logs (`/var/groupon/log/ta-api/`); do NOT delete `catalina-daemon.out` while running |
| `iostat` | IO utilization above threshold | P5 | Investigate with `iostat -mtx 1` and `iotop -P`; notify team |
| `ntp` | NTP skew or daemon issues | P5 | Run `ntpq -p`; synchronize with `ntpdate -s ns1` |
| Average response time SLA breach | Splunk query firing | Warning/Critical | Contact traffic source; investigate upstream Getaways API latency |
| Error rate > 10% | Splunk query firing | Warning | Check `ta-api-application.log`; verify Getaways API health |

Alerts are routed to: `getaways-svc-affiliate-alert@groupon.com` / PagerDuty service `PUB4GAI`.

## Common Operations

### Restart Service

**Remote (preferred):**
```
cap {colo (serverId)? env} graceful_restart
```

**Local:**
```
ssh afl-ta-appN(-staging)?.snc1
sudo /usr/local/etc/init.d/apache_tomcat_ta-api stop && sleep 10 && sudo /usr/local/etc/init.d/apache_tomcat_ta-api start
```

Wait at least 2 minutes after start before testing — services take up to 2 minutes to fully initialise.

### Enable / Disable Heartbeat

**Via Capistrano (preferred):**
```
# Disable
cap {colo (serverId)? env} remove USER=john.smith
# Enable
cap {colo (serverId)? env} add USER=john.smith
```

**Via HTTP (management endpoint):**
```
# Disable
curl -X DELETE afl-ta-appN(-staging)?:8080/resources/manage/heartbeat --basic --user "admin:{password}"
# Enable
curl -X PUT afl-ta-appN(-staging)?:8080/resources/manage/heartbeat --basic --user "admin:{password}"
```

**Local file operation:**
```
# Disable
rm /var/groupon/run/ta-api/heartbeat.txt
# Enable
touch /var/groupon/run/ta-api/heartbeat.txt
```

### Check Service Status

```
sudo /var/groupon/apache-tomcat/scripts/gpn-mgmt.py status
sudo /var/groupon/apache-tomcat/scripts/gpn-mgmt.py test api-core
```

### Scale Up

1. Obtain new host through Groupon Central
2. Configure to hostclass `afl-ta-api` (latest tag) via Config Wizard
3. Perform initial roll: `ssh {host}; sudo /var/tmp/roll`
4. Add host to `ta-api-v1/Capfile`
5. Deploy: `cap {colo (serverId)? env} deploy:app_servers USER=your.username`
6. Add host to load balancer VIP

### Database Operations

> Not applicable. The service does not own or manage any business database schema. If GPN framework database issues arise, contact the GPN team at `gpn-dev@groupon.com`.

## Troubleshooting

### Service Unreachable / Heartbeat Down

- **Symptoms**: Nagios `api_heartbeat` alert; HTTP timeouts from partner
- **Cause**: Tomcat not running, or heartbeat file missing
- **Resolution**:
  1. Run `gpn-mgmt.py status` to check heartbeat and Tomcat status
  2. If heartbeat is OFF or PARTIAL, restart heartbeat: `gpn-mgmt.py hb-start`
  3. If Tomcat is down, restart: follow Restart procedure above
  4. Verify service responds: `gpn-mgmt.py test api-core`

### High Response Latency

- **Symptoms**: Wavefront latency metrics spiking; Splunk SLA alert firing
- **Cause**: Upstream Getaways API slow, or JVM GC pauses
- **Resolution**:
  1. Check GC logs first: `tail -n 200 /var/groupon/apache-tomcat/logs/gc/gc.log | grep "Full GC"`
  2. If frequent Full GCs with little memory reclaimed: stop heartbeat, take heap dump (`jmap`), restart Tomcat
  3. If GC is normal: investigate Getaways API response times via Wavefront
  4. Contact `gpn-dev@groupon.com` if GC is abnormal

### Abnormal Error Rate

- **Symptoms**: >10% error responses; Splunk error rate alert
- **Cause**: Upstream Getaways API failures, partner sending invalid requests, or application exception
- **Resolution**:
  1. Check `ta-api-application.log` at `/var/groupon/log/ta-api/ta-api-application.log`
  2. Check access logs: `/var/groupon/log/ta-api/ta-api-access.<date>.log`
  3. Identify source of errors (partner or internal)
  4. If internal: restart Tomcat and notify Affiliates Team
  5. If external (partner sending bad requests): contact partner to reduce/fix their call patterns

### JVM Memory / OOM

- **Symptoms**: `mem` or `swap` Nagios alerts; service degraded
- **Resolution**:
  1. Check OOM: `grep -i 'PermgenSpace' /var/groupon/log/ta-api/catalina-daemon.out`
  2. Review GC logs for frequency of Full GC events
  3. Stop heartbeat, take heap snapshot: `jmap -dump:format=b,file=heapdump.hprof {pid}`
  4. Restart Tomcat, notify `gpn-dev@groupon.com`

### Disk Space Exhaustion

- **Symptoms**: `disk_space` Nagios alert
- **Resolution**:
  1. Check with `df -h`, locate usage with `du -sh *`
  2. Safely delete old application and access logs in `/var/groupon/log/ta-api/`
  3. GC logs in `/var/groupon/apache-tomcat/logs/gc/` can be deleted safely
  4. Do NOT delete `catalina-daemon.out` while service is running — must stop Tomcat first

### Overloaded by Partner Traffic

- **Symptoms**: High RPM, latency degradation, SLA alerts
- **Resolution**:
  1. Identify traffic source from access logs: `ta-api-access.{date}.log`
  2. Contact partner to reduce request rate
  3. If immediate relief needed, add capacity or temporarily block partner at load balancer

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down; partners unable to get availability | Immediate | Affiliates on-call via PagerDuty (`PUB4GAI`); `getaways-svc-affiliate-alert@groupon.com` |
| P2 | Degraded — high latency or elevated error rate | 30 min | Affiliates Engineering (`getaways-eng@groupon.com`) |
| P3 | Minor impact — single partner affected or intermittent errors | Next business day | Affiliates Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Getaways Search API | Check `getaways-search` service status in service portal | Returns empty hotel availability list to partner (`getaways.api.forceOff=true` to force-disable) |
| Getaways Content API | Check `getaways-content` service status | Returns degraded response without content enrichment |
| MySQL (GPN framework DB) | `gpn-mgmt.py status` | GPN framework may degrade non-business operations |
