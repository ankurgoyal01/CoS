---
service: "web-config"
title: "Config Generation"
generated: "2026-03-03"
type: flow
flow_name: "config-generation"
flow_type: batch
trigger: "Operator invokes `fab generate:{ENV}` or CI `Build and Test` stage starts"
participants:
  - "webConfigDeployAutomation"
  - "webConfigVhostAssembly"
  - "webConfigTemplateRenderer"
architecture_ref: "components-web-config"
---

# Config Generation

## Summary

The config generation flow transforms version-controlled YAML data files and Mustache templates into ready-to-deploy nginx configuration files for a given environment. It produces `main.conf`, per-virtual-host `.conf` files, shared include fragments, and locale-specific error HTML pages. The output is written to `conf/nginx/k8s/{env}/` (cloud target) and is meant to be committed to the repository before deployment.

## Trigger

- **Type**: manual or CI build
- **Source**: Operator runs `pipenv run fab generate:{ENV}` locally, or the Jenkins `Build and Test` stage calls `docker-compose run routing-config-{env}`
- **Frequency**: On demand, before each deployment or config change

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deployment Automation Tasks | Orchestrates the generation pipeline; sets environment, platform, and deploy-target; invokes generate_config | `webConfigDeployAutomation` |
| Virtual Host Assembly | Merges default config with per-site YAML; resolves server names, aliases, rewrites, error pages, and brand; builds the vhost context dict | `webConfigVhostAssembly` |
| Template Rendering Engine | Renders each Mustache template with the assembled config dict; writes output files to the target path | `webConfigTemplateRenderer` |

## Steps

1. **Validate inputs**: Asserts that `ENV`, `PLATFORM`, and `DEPLOY_TARGET` are set to valid values; confirms execution is from the repository root (`.git` directory present)
   - From: `webConfigDeployAutomation`
   - To: `webConfigDeployAutomation`
   - Protocol: direct

2. **Load default and platform configuration**: Reads `data/{env}/defaults/default.yml` and `data/{env}/defaults/nginx_cloud.yml` (or `nginx.yml` for on-prem); optionally reads `data/{env}/env.yml` and `data/{env}/access.yml`
   - From: `webConfigDeployAutomation`
   - To: filesystem
   - Protocol: direct (PyYAML)

3. **Clean target directory**: Removes and recreates `conf/nginx/k8s/{env}/` and all subdirectories
   - From: `webConfigDeployAutomation`
   - To: filesystem
   - Protocol: direct

4. **Discover virtual-host site files**: Globs `data/{env}/sites/*.yml` to find all per-country virtual-host specifications
   - From: `webConfigDeployAutomation`
   - To: filesystem
   - Protocol: direct

5. **Assemble virtual-host context for each site**: For each `sites/*.yml`, `webConfigVhostAssembly` merges defaults with the site config; resolves primary server name, aliases, canonical host, allowed-server regex, rewrite rule file paths, error-page specs, and brand
   - From: `webConfigDeployAutomation`
   - To: `webConfigVhostAssembly`
   - Protocol: direct

6. **Render virtual-host config files**: For each assembled vhost context, `webConfigTemplateRenderer` renders `templates/nginx/virtual_host.conf.mustache` and writes `conf/nginx/k8s/{env}/virtual_hosts/{identifier}.conf`
   - From: `webConfigVhostAssembly`
   - To: `webConfigTemplateRenderer`
   - Protocol: direct (pystache)

7. **Render error pages**: For each virtual host, iterates over error-page specs; renders locale-specific error HTML from `templates/error_pages/*.mustache` with translation YAML data; writes to `conf/nginx/k8s/{env}/root/{country}/error/{code}.html`
   - From: `webConfigDeployAutomation`
   - To: `webConfigTemplateRenderer`
   - Protocol: direct (pystache)

8. **Render main config**: Renders `templates/nginx/main.conf.mustache` with the combined config dict; writes `conf/nginx/k8s/{env}/main.conf`
   - From: `webConfigDeployAutomation`
   - To: `webConfigTemplateRenderer`
   - Protocol: direct (pystache)

9. **Render include fragments**: Renders `akamai.conf`, `analytics.conf`, `proxy.conf`, `security.conf` (and optionally `access.conf`) into `conf/nginx/k8s/{env}/includes/`
   - From: `webConfigDeployAutomation`
   - To: `webConfigTemplateRenderer`
   - Protocol: direct (pystache)

10. **Copy static assets**: Copies auth files from `data/{env}/auth/` and Akamai static files from `templates/nginx/akamai/` into the target directory
    - From: `webConfigDeployAutomation`
    - To: filesystem
    - Protocol: direct (shutil)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing or invalid `ENV` / `PLATFORM` / `DEPLOY_TARGET` | AssertionError raised; `fab` aborts with red error message | No files generated; operator must fix inputs |
| YAML parse error in data file | PyYAML raises exception; generation aborts | Partial `conf/` output; should not be committed |
| Mustache template rendering error | pystache raises exception; generation aborts | Partial output; do not deploy |
| Missing rewrite file | `glob()` returns empty; rewrite file silently skipped (not included in output) | Virtual host config generated without that rewrite file |

## Sequence Diagram

```
Operator/CI -> webConfigDeployAutomation: fab generate:{ENV} or docker-compose run
webConfigDeployAutomation -> filesystem: load default.yml, nginx_cloud.yml, env.yml, access.yml
webConfigDeployAutomation -> filesystem: glob sites/*.yml
webConfigDeployAutomation -> webConfigVhostAssembly: present_vhost(group, source_path, platform, merged_conf)
webConfigVhostAssembly -> filesystem: glob rewrites/{platform}.*.{identifier}
webConfigVhostAssembly --> webConfigDeployAutomation: vhost context dict
webConfigDeployAutomation -> webConfigTemplateRenderer: write virtual_host.conf.mustache
webConfigTemplateRenderer -> filesystem: write virtual_hosts/{identifier}.conf
webConfigDeployAutomation -> webConfigTemplateRenderer: render error page templates
webConfigTemplateRenderer -> filesystem: write root/{country}/error/{code}.html
webConfigDeployAutomation -> webConfigTemplateRenderer: write main.conf.mustache
webConfigTemplateRenderer -> filesystem: write main.conf
webConfigDeployAutomation -> webConfigTemplateRenderer: write includes/*.conf.mustache
webConfigTemplateRenderer -> filesystem: write includes/*.conf
```

## Related

- Architecture component view: `components-web-config`
- Related flows: [Config Deployment](config-deployment.md), [CI/CD Pipeline](cicd-pipeline.md)
