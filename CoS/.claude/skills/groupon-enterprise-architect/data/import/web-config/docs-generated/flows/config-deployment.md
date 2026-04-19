---
service: "web-config"
title: "Config Deployment"
generated: "2026-03-03"
type: flow
flow_name: "config-deployment"
flow_type: batch
trigger: "Operator runs `fab {ENV} deploy:{REVISION}` after config generation and PR merge"
participants:
  - "webConfigDeployAutomation"
  - "apiProxy"
architecture_ref: "components-web-config"
---

# Config Deployment

## Summary

The config deployment flow delivers generated nginx configuration from the repository to the target routing hosts via SSH, using Fabric tasks. It validates the config with `nginx -t`, symlinks the new release as the active config, and triggers a live nginx reload. The flow supports rollback to a previous revision. For Kubernetes environments, the equivalent delivery mechanism is the CI/CD pipeline (Docker image push + kustomize image-tag update).

## Trigger

- **Type**: manual
- **Source**: Operator runs `pipenv run fab {ENVIRONMENT} deploy:{REVISION}` from the repository root after configuration has been generated and changes have been merged to master
- **Frequency**: On demand, per config change

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deployment Automation Tasks | Orchestrates SSH-based file copy, validation, symlink, and nginx reload | `webConfigDeployAutomation` |
| apiProxy (routing host) | Receives new config files; runs nginx -t; reloads nginx process | `apiProxy` |

## Steps

1. **Set environment context**: Fabric task selects target hosts and paths based on the environment alias (e.g., `prod_snc1` sets `env.hosts` to `routing-app[1-10].snc1`, `env.deploy_path` to `/var/groupon/routing-web-config`, `env.platform_path` to `/var/groupon/nginx`)
   - From: `webConfigDeployAutomation`
   - To: `webConfigDeployAutomation`
   - Protocol: direct

2. **Validate revision**: For production environments (`prod_*`), confirms the provided SHA is reachable from `origin/master` using `git branch -r --contains {sha}`; aborts if not found
   - From: `webConfigDeployAutomation`
   - To: local git
   - Protocol: direct

3. **Fetch config archive at revision**: Creates a Git archive of the generated `conf/` directory at the specified revision; uploads the archive to each routing host via SSH into `{deploy_path}/releases/{sha}/`
   - From: `webConfigDeployAutomation`
   - To: `apiProxy` (routing hosts via SSH)
   - Protocol: SSH/Fabric

4. **Validate nginx config on host**: Runs `nginx -t -c /var/groupon/nginx/conf/main.conf` on each routing host remotely; aborts the deploy if validation fails, leaving the current symlink unchanged
   - From: `webConfigDeployAutomation`
   - To: `apiProxy` (routing host nginx process)
   - Protocol: SSH/Fabric (exec)

5. **Symlink new release as current**: On each routing host, updates the `{deploy_path}/current` symlink to point to `{deploy_path}/releases/{sha}/`
   - From: `webConfigDeployAutomation`
   - To: `apiProxy` (routing host filesystem)
   - Protocol: SSH/Fabric

6. **Write REVISION and META files**: Writes the deployed SHA to `{platform_config_path}/REVISION` and deployment metadata (timestamp, operator) to `{platform_config_path}/META` on each host
   - From: `webConfigDeployAutomation`
   - To: `apiProxy` (routing host filesystem)
   - Protocol: SSH/Fabric

7. **Reload nginx**: Executes `/usr/local/etc/init.d/nginx reload` on each routing host to apply the new configuration without dropping connections
   - From: `webConfigDeployAutomation`
   - To: `apiProxy` (nginx process)
   - Protocol: SSH/Fabric (exec)

8. **Verify deployment**: Operator runs `pipenv run fab {ENV} check_revision check_meta` to confirm all hosts show the expected revision
   - From: Operator
   - To: `webConfigDeployAutomation` -> routing hosts
   - Protocol: SSH/Fabric

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `nginx -t` fails on a host | Deploy aborts for that host; symlink not updated | Existing config remains active; operator must fix the template/data issue and redeploy |
| SSH connection failure | Fabric task fails with connection error | Partial deploy possible if some hosts succeeded; operator must inspect and rerun |
| Invalid or unreachable revision (production) | `sha_at_origin_master` returns false; Fabric aborts | No files copied; deploy not started |
| Rollback needed | Operator runs `pipenv run fab {ENV} rollback` | Previous release symlink restored; nginx reloaded |

## Sequence Diagram

```
Operator -> webConfigDeployAutomation: fab {ENV} deploy:{SHA}
webConfigDeployAutomation -> local git: validate SHA is in origin/master
webConfigDeployAutomation -> apiProxy (routing hosts): SSH: copy config archive to releases/{sha}/
webConfigDeployAutomation -> apiProxy (routing hosts): SSH: nginx -t (validation)
apiProxy --> webConfigDeployAutomation: validation result
webConfigDeployAutomation -> apiProxy (routing hosts): SSH: ln -nsf releases/{sha}/ current
webConfigDeployAutomation -> apiProxy (routing hosts): SSH: write REVISION + META
webConfigDeployAutomation -> apiProxy (routing hosts): SSH: nginx reload
apiProxy --> webConfigDeployAutomation: reload confirmation
Operator -> webConfigDeployAutomation: fab {ENV} check_revision check_meta
webConfigDeployAutomation -> apiProxy (routing hosts): SSH: cat REVISION; cat META
```

## Related

- Architecture component view: `components-web-config`
- Related flows: [Config Generation](config-generation.md), [CI/CD Pipeline](cicd-pipeline.md)
