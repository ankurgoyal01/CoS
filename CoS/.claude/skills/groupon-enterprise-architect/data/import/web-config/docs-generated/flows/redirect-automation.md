---
service: "web-config"
title: "Redirect Automation"
generated: "2026-03-03"
type: flow
flow_name: "redirect-automation"
flow_type: batch
trigger: "Operator runs `create-redirects -e {production|test}` from the repository root"
participants:
  - "webConfigRedirectAutomation"
  - "continuumJiraService"
  - "cloudPlatform"
  - "githubEnterprise"
architecture_ref: "components-web-config"
---

# Redirect Automation

## Summary

The redirect automation flow reads open redirect-request Jira tickets from the MESH project, parses each ticket's description to extract source URLs and a destination URL, generates nginx `rewrite` directives, prepends them to the appropriate rewrite rule data files in the repository, commits and pushes a feature branch to GitHub Enterprise, opens a pull request, and transitions each processed Jira ticket to `In PR - Needs Review`. This automates a workflow that would otherwise require manual editing of nginx rewrite files.

## Trigger

- **Type**: manual
- **Source**: Operator runs the Go CLI: `./create-redirects -e production` (or `-e test` for validation)
- **Frequency**: On demand when Jira redirect tickets are ready to be processed

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Redirect Automation CLI | Orchestrates all steps; reads CLI flags; calls Jira, AWS, Git, and GitHub | `webConfigRedirectAutomation` |
| AWS Secrets Manager | Provides the Jira API token secret (`hybrid-boundary-svc-user-jira`) | `cloudPlatform` |
| Jira | Source of redirect request tickets (`MESH` project, `Redirects` and `Legal Redirects` components, `To Do` status) | `continuumJiraService` |
| GitHub Enterprise | Receives the feature branch and hosts the pull request | `githubEnterprise` |

## Steps

1. **Parse CLI arguments**: Reads `-e {environment}`, optional `-r {region}`, `-c {config_path}`, `-t {ticket}`, `--dryrun`; loads `conf/config_{environment}.yaml` for `jira_url`, `redirects_output_path`, `env_specific_folder`
   - From: Operator
   - To: `webConfigRedirectAutomation`
   - Protocol: CLI args

2. **Retrieve Jira credentials from AWS Secrets Manager**: Calls `secretsmanager.GetSecretValue` for secret `hybrid-boundary-svc-user-jira` in `us-west-2` (default region); unmarshals JSON to extract the Jira API token for a dedicated service account
   - From: `webConfigRedirectAutomation`
   - To: `cloudPlatform` (AWS Secrets Manager)
   - Protocol: AWS SDK (HTTPS)

3. **Query Jira for open redirect tickets**: Executes JQL `project = 'MESH' AND status IN ('To Do') AND component IN ('Redirects', 'Legal Redirects') ORDER BY created DESC`; returns all matching issues
   - From: `webConfigRedirectAutomation`
   - To: `continuumJiraService`
   - Protocol: HTTPS REST (go-jira)

4. **Parse each Jira ticket**: For each issue, reads the ticket `Description` field; tokenises by whitespace; scans for `from` URL(s) and a `to` URL; determines the appropriate nginx rewrite file based on source host TLD and path (e.g., `nginx.deals.de`, `nginx.other.fr`, `nginx.all_envs.us`); builds `rewrite "(?i)^{path}(/|$)" "{destination}" permanent;` directives
   - From: `webConfigRedirectAutomation`
   - To: `webConfigRedirectAutomation`
   - Protocol: direct

5. **Prompt operator to confirm**: Prints a summary of found redirects and prompts for confirmation (unless `--dryrun`); operator enters any key to continue or `q` to abort
   - From: `webConfigRedirectAutomation`
   - To: Operator (stdin/stdout)
   - Protocol: interactive

6. **Create feature branch and prepend rewrite rules**: Runs `git branch {initials}/{JIRA_KEY}` and `git checkout`; for each target rewrite file, prepends the new `rewrite` directives to the existing file content; runs `git add {file}` for each modified file
   - From: `webConfigRedirectAutomation`
   - To: local git working tree
   - Protocol: direct (os/exec)

7. **Commit and push branch to GitHub Enterprise**: Runs `git commit -m "[MESH-{key}]"` and `git push --set-upstream origin {branch}`, then checks out `master` and deletes the local branch
   - From: `webConfigRedirectAutomation`
   - To: `githubEnterprise`
   - Protocol: Git (SSH)

8. **Create pull request**: Uses the GitHub Enterprise API (`https://github.groupondev.com/api/v3`) with `REDIRECT_API_TOKEN` OAuth2 token to open a PR from the feature branch against `master` in `routing/web-config`; receives the PR HTML URL
   - From: `webConfigRedirectAutomation`
   - To: `githubEnterprise`
   - Protocol: HTTPS REST (go-github + oauth2)

9. **Update Jira tickets**: For each processed issue key, posts a comment `[REDIRECTS CREATED] {USER}: {PR_URL}` and transitions the ticket status to `In PR - Needs Review`
   - From: `webConfigRedirectAutomation`
   - To: `continuumJiraService`
   - Protocol: HTTPS REST (go-jira)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AWS Secrets Manager call fails | Panic with AWS error code | CLI terminates; no Jira calls made |
| Jira query returns no tickets | Prints "no redirect tickets found"; returns | No files modified |
| Malformed ticket description (no `to` keyword) | Skips the ticket with an error message; continues to next ticket | Other valid tickets are still processed |
| Invalid source or destination URL | Logs `Invalid destination URL`; breaks out of that ticket's parse loop | Ticket skipped; operator must fix Jira description |
| Redirect file not found on disk | Prints error; skips that file; continues | Other files still updated; missing redirects must be added manually |
| Git branch creation fails (branch already exists) | Returns error `could not create branch`; aborts git operations | No files committed; operator must delete the stale branch manually |
| GitHub PR creation fails | Prints error; Jira tickets are NOT updated | PR must be created manually; redirects are already in data files |

## Sequence Diagram

```
Operator -> webConfigRedirectAutomation: create-redirects -e production
webConfigRedirectAutomation -> cloudPlatform: GetSecretValue(hybrid-boundary-svc-user-jira)
cloudPlatform --> webConfigRedirectAutomation: Jira API token JSON
webConfigRedirectAutomation -> continuumJiraService: GET issues (MESH, To Do, Redirects|Legal Redirects)
continuumJiraService --> webConfigRedirectAutomation: issue list
webConfigRedirectAutomation -> webConfigRedirectAutomation: parse each ticket; build rewrite rules
webConfigRedirectAutomation -> Operator: print summary; prompt for confirmation
Operator --> webConfigRedirectAutomation: confirm
webConfigRedirectAutomation -> local git: git branch {name}; git checkout
webConfigRedirectAutomation -> filesystem: prepend rewrite rules to data/*/rewrites/nginx.*
webConfigRedirectAutomation -> local git: git add + git commit + git push
local git -> githubEnterprise: push branch
webConfigRedirectAutomation -> githubEnterprise: POST /repos/routing/web-config/pulls
githubEnterprise --> webConfigRedirectAutomation: PR URL
webConfigRedirectAutomation -> continuumJiraService: POST comment + transition to "In PR - Needs Review"
```

## Related

- Architecture component view: `components-web-config`
- Related flows: [Config Generation](config-generation.md), [CI/CD Pipeline](cicd-pipeline.md)
