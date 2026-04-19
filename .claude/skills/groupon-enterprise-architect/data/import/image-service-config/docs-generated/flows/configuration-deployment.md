---
service: "image-service-config"
title: "Configuration Deployment"
generated: "2026-03-03"
type: flow
flow_name: "configuration-deployment"
flow_type: batch
trigger: "Manual execution of a Capistrano task by an operator"
participants:
  - "Operator"
  - "continuumImageServiceConfigBundle"
  - "continuumImageServiceNginxCacheProxy"
  - "continuumImageServiceAppRuntime"
architecture_ref: "dynamic-imageServiceConfig"
---

# Configuration Deployment

## Summary

When configuration changes are required — such as adding a new API client, adjusting allowed image sizes, updating nginx buffer settings, or modifying upstream VIP addresses — an operator runs a Capistrano task from the `image-service-config` repository. The `capistranoDeployPipeline` renders ERB templates with environment-specific values, then SCPs the resulting configuration files to all target cache and app nodes and reloads the relevant services.

## Trigger

- **Type**: manual
- **Source**: Operator (Intl-Infrastructure team) executing `cap nginx`, `cap app`, `cap staging`, or environment-specific Capistrano tasks
- **Frequency**: On-demand; triggered by configuration changes or new client onboarding

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator | Initiates Capistrano task; owns `image-service-config` repo | External (human) |
| Capistrano Deploy Pipeline | Renders templates, distributes files, triggers reloads | `capistranoDeployPipeline` |
| Nginx Template Set | Provides `nginx.conf.erb` and `upstream-default.conf.erb` templates | `nginxTemplateSet` |
| App Runtime Config Set | Provides `supervisord.conf` and `config.yml` payloads | `appRuntimeConfigSet` |
| Image Service Nginx Cache Proxy | Receives new nginx/upstream config; reloads nginx | `continuumImageServiceNginxCacheProxy` |
| Image Service App Runtime | Receives new `config.yml` and `supervisord.conf`; auto-detects config changes | `continuumImageServiceAppRuntime` |

## Steps

### Cache Node Configuration (`cap nginx` task)

1. **Operator invokes Capistrano task**: Operator runs `cap nginx` from the repository root.
   - From: Operator
   - To: `capistranoDeployPipeline`
   - Protocol: Shell command

2. **Capistrano renders ERB templates**: `capistranoDeployPipeline` calls `from_template("nginx.conf.erb")` and `from_template("upstream-default.conf.erb")` using Ruby ERB, injecting environment-specific values:
   - `server_names_cdn`: e.g., `img.grouponcdn.com origin-img.grouponcdn.com image-service-vip.snc1`
   - `server_names_proxy`: e.g., `image-service.s3.amazonaws.com image-service-s3-proxy-vip.snc1`
   - `upstream_vip`: e.g., `global-image-service-app-vip:80`
   - `proxy_set_header`: e.g., `Host image-service.s3.amazonaws.com`
   - From: `capistranoDeployPipeline`
   - To: `nginxTemplateSet`
   - Protocol: In-process (Ruby ERB)

3. **Capistrano SCPs rendered files to cache nodes**: Deploys rendered `nginx.conf`, `upstream-default.conf`, `s3-proxy.conf`, and supporting files to each cache node's deploy path (`/var/groupon/nginx/conf/`). Excludes: `.git`, `Capfile`, `supervisord.conf`, `config.yml`, ERB source files.
   - From: `capistranoDeployPipeline`
   - To: `continuumImageServiceNginxCacheProxy` (each cache node: `image-service-cache1.snc1` through `cache8.snc1`)
   - Protocol: Capistrano SCP (SSH)

4. **Capistrano enables all upstreams**: Runs `enable_all` task: `ln -sf upstream-default.conf /etc/nginx/upstream.conf` on each cache node.
   - From: `capistranoDeployPipeline`
   - To: `continuumImageServiceNginxCacheProxy`
   - Protocol: SSH remote command

5. **Nginx reloads configuration**: `sudo /usr/local/etc/init.d/nginx reload` applied to each cache node; new nginx config takes effect without dropping active connections.
   - From: `continuumImageServiceNginxCacheProxy` (Nginx master process)
   - To: `continuumImageServiceNginxCacheProxy` (Nginx worker processes)
   - Protocol: Unix signal (SIGHUP via init script)

### App Node Configuration (`cap app` / `update_app_config` task)

1. **Operator invokes Capistrano task**: Operator runs `cap app` or `update_app_config`.
   - From: Operator
   - To: `capistranoDeployPipeline`
   - Protocol: Shell command

2. **Capistrano uploads supervisord.conf**: SCPs `supervisord.conf` to `/data/thepoint/current` on each app node.
   - From: `capistranoDeployPipeline`
   - To: `continuumImageServiceAppRuntime`
   - Protocol: Capistrano SCP (SSH)

3. **Capistrano uploads config.yml**: SCPs `config.yml` (or `uat/config.yml` for UAT environment) to `/data/thepoint/current` on each app node.
   - From: `capistranoDeployPipeline` (from `appRuntimeConfigSet`)
   - To: `imageServiceConfigLoader`
   - Protocol: Capistrano SCP (SSH)

4. **Config Loader detects new config**: The Python `imageservice.py` application auto-detects changes to `config.yml` and reloads client API keys and allowed-size policies without a process restart (described in Capfile comment: "auto-detect and reload config.yml changes, no restart needed").
   - From: `imageServiceConfigLoader`
   - To: `imageRequestHandler`
   - Protocol: In-process (file watch or periodic reload)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| ERB template rendering fails | Capistrano task aborts with error; no files deployed | Existing config on nodes unchanged |
| SCP to a cache node fails | Capistrano reports error for that node; other nodes may succeed | Partial deployment; operator must re-run task for failed nodes |
| Nginx syntax error in rendered config | `nginx reload` fails; old config remains active | Operator must fix ERB template, re-render, and redeploy |
| `config.yml` has invalid YAML syntax | Capistrano uploads file; app may fail to reload | App processes continue with old config until issue resolved |
| Capistrano cannot reach a node (SSH failure) | Task reports connection error; node skipped | Node retains old configuration; operator must resolve SSH access |

## Sequence Diagram

```
Operator -> capistranoDeployPipeline: cap nginx (or cap app)
capistranoDeployPipeline -> nginxTemplateSet: Render nginx.conf.erb with env vars
nginxTemplateSet --> capistranoDeployPipeline: Rendered nginx.conf
capistranoDeployPipeline -> nginxTemplateSet: Render upstream-default.conf.erb with upstream_vip
nginxTemplateSet --> capistranoDeployPipeline: Rendered upstream-default.conf
loop for each cache node (cache1-cache8.snc1)
  capistranoDeployPipeline -> continuumImageServiceNginxCacheProxy: SCP nginx.conf, upstream-default.conf, s3-proxy.conf
  capistranoDeployPipeline -> continuumImageServiceNginxCacheProxy: SSH: ln -sf upstream-default.conf /etc/nginx/upstream.conf
  capistranoDeployPipeline -> continuumImageServiceNginxCacheProxy: SSH: sudo nginx reload
end
loop for each app node (app1-app4.snc1)
  capistranoDeployPipeline -> appRuntimeConfigSet: Upload supervisord.conf
  capistranoDeployPipeline -> imageServiceConfigLoader: SCP config.yml to /data/thepoint/current
  imageServiceConfigLoader -> imageRequestHandler: Auto-reload API keys and allowed sizes
end
```

## Related

- Architecture dynamic view: No dynamic views modeled yet
- Related flows: [Rolling App Node Restart](rolling-app-node-restart.md)
- Deployment details: [Deployment](../deployment.md)
- Configuration reference: [Configuration](../configuration.md)
