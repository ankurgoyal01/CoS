---
service: "elit-github-app"
title: "PR Diff ELIT Scan"
generated: "2026-03-03"
type: flow
flow_name: "pr-diff-elit-scan"
flow_type: event-driven
trigger: "GitHub check_run.created webhook event"
participants:
  - "githubEnterprise"
  - "continuumElitGithubAppService"
  - "webhookResource"
  - "actionHandler"
  - "githubClient"
  - "checkFunction"
  - "scannerFactory"
  - "ruleFileReader"
  - "diffReader"
  - "diffParser"
  - "contentScanner"
architecture_ref: "components-elitGithubAppService"
---

# PR Diff ELIT Scan

## Summary

After a check run is created (see [Check Suite Requested](check-suite-requested.md)), GitHub delivers a `check_run.created` event. This flow handles the substantive work of the ELIT scan: the service marks the check run as in-progress, then asynchronously fetches the PR diff from GitHub, loads and merges ELIT scanning rules, parses the diff, scans all inserted lines for problematic language, and reports the result back to GitHub as a check conclusion with inline file annotations. The scan runs on a fixed thread pool of 20 threads.

## Trigger

- **Type**: event
- **Source**: GitHub Enterprise — `check_run` webhook event with action `created`
- **Frequency**: Once per check run creation (i.e., once per PR push or re-request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GitHub Enterprise | Sends `check_run.created` webhook event; provides PR diffs and rule files; receives scan results | `githubEnterprise` |
| GitHub Webhook Resource | Receives authenticated event and delegates to action handler | `webhookResource` |
| Check Action Handler | Routes event to `StartCheckActionHandler` | `actionHandler` |
| GitHub App Client | Authenticates as installation; marks check in-progress; fetches diff; posts conclusions | `githubClient` |
| Pull Request Check Function | Orchestrates the scan: fetches diff URLs, runs scanner, determines conclusion | `checkFunction` |
| ELIT Scanner Factory | Builds the `ContentScanner` from merged default + per-repo rules | `scannerFactory` |
| Rule File Reader | Reads and merges ELIT YAML rule files from the repository | `ruleFileReader` |
| Diff Reader | Fetches raw diff content from GitHub API | `diffReader` |
| Diff Parser | Parses unified diff lines into `DiffItem` objects | `diffParser` |
| Content Scanner | Applies regex replacement rules to inserted diff lines; produces `ContentAnnotation` objects | `contentScanner` |

## Steps

1. **Receive check_run.created event**: `GitHubAppResource` receives the validated POST. The payload contains a `check_run` with `id` and `pull_requests` array, plus `installation.id` and `repository.id`.
   - From: `githubEnterprise`
   - To: `webhookResource`
   - Protocol: HTTPS (signature validated by `messageAuthFilter`)

2. **Route to StartCheckActionHandler**: `CheckActionHandler` evaluates handlers. `StartCheckActionHandler.accepts()` returns `true` when `check_run` is present and action is `created`.
   - From: `actionHandler`
   - To: `StartCheckActionHandler` (in-process)
   - Protocol: direct

3. **Mark check run IN_PROGRESS**: Synchronously authenticates as the installation and calls `updateCheckRun(run.getId()).withStatus(GHCheckRun.Status.IN_PROGRESS).create()` to signal that the scan has started.
   - From: `githubClient`
   - To: `githubEnterprise` (GitHub Checks API)
   - Protocol: HTTPS REST

4. **Submit scan task to thread pool**: The scan work is submitted to a fixed thread pool (`Executors.newFixedThreadPool(20)` wrapped in a `Ctx`-propagating executor). The webhook handler returns HTTP 200 immediately.
   - From: `StartCheckActionHandler`
   - To: thread pool executor (in-process)
   - Protocol: direct (async)

5. **Build ELIT scanner**: `PullRequestCheckFunction` calls `ElitScannerFactory.getScanner(request)` to build a `ContentScanner`. The factory merges the built-in `default-elit.yml` rules with per-repo `.elit.yml` rules (see [ELIT Rule File Loading](elit-rule-file-loading.md)).
   - From: `checkFunction`
   - To: `scannerFactory`
   - Protocol: direct (in-process)

6. **Collect PR diff URLs**: The `CheckActionRequest` provides the list of diff URLs from the `pull_requests` array in the check run payload.
   - From: `checkFunction`
   - To: `CheckActionRequest` (in-process)
   - Protocol: direct

7. **Fetch PR diff**: For each diff URL, `PullRequestCheckFunction` calls `github.getConnector().connect(new URL(diffUrl))` with `Accept: application/vnd.github.v3.diff` to stream the unified diff.
   - From: `diffReader` (via `checkFunction`)
   - To: `githubEnterprise` (GitHub API)
   - Protocol: HTTPS REST

8. **Parse diff**: The raw diff `Reader` is passed to `DiffParser.parse()` which produces a stream of `DiffItem` objects, each with a type (`INSERT`, `DELETE`, `CONTEXT`), file path, line number, and line content.
   - From: `diffParser`
   - To: `checkFunction` (stream)
   - Protocol: direct (in-process)

9. **Scan inserted lines**: `PullRequestCheckFunction.scanDiff()` filters to only `INSERT`-type `DiffItem` objects. For each inserted line, `ContentScanner.scan()` applies the regex replacement rules and returns any `ContentAnnotation` objects for violations.
   - From: `checkFunction`
   - To: `contentScanner`
   - Protocol: direct (in-process)

10. **Determine conclusion**: If no annotations are found, the check conclusion is `SUCCESS`. If any violations exist, the conclusion is `FAILURE` and a summary message is generated (e.g., `"3 violation(s) in 2 file(s) detected"`).
    - From: `checkFunction`
    - To: `GHCheckRunBuilder` (in-process)
    - Protocol: direct

11. **Post check result to GitHub**: The completed `GHCheckRunBuilder` is submitted via `runBuilder.create()`. This sends the conclusion, summary, and all `Annotation` objects (file path, line number, start/end column, failure level, and violation details) back to GitHub.
    - From: `githubClient`
    - To: `githubEnterprise` (GitHub Checks API)
    - Protocol: HTTPS REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Exception during scan (any) | Caught in `StartCheckActionHandler`; run marked `SKIPPED` with `Internal error` output; error logged | Check shown as `SKIPPED` in GitHub; no crash |
| `.elit.yml` parse error | Caught in `ElitScannerFactory`; fallback to default config; error logged | Scan proceeds with default rules only |
| GitHub API error fetching diff | `IllegalStateException` thrown; caught by outer try/catch in `StartCheckActionHandler` | Run marked `SKIPPED` |
| Empty pull_requests list | Stream produces no diff URLs; no annotations generated | Check marked `SUCCESS` (no violations found) |

## Sequence Diagram

```
GitHub Enterprise -> GitHubAppResource: POST /elit-github-app/webhook (check_run.created)
GitHubAppResource -> CheckActionHandler: onEvent(github, action)
CheckActionHandler -> StartCheckActionHandler: accepts() == true; onEvent(app, action)
StartCheckActionHandler -> GitHubAppClient: updateCheckRun(runId).withStatus(IN_PROGRESS)
GitHubAppClient -> GitHub Enterprise: PATCH check run — status: in_progress
GitHub Enterprise --> GitHubAppClient: Updated check run
StartCheckActionHandler -> ThreadPool: submit(scanTask)
GitHubAppResource --> GitHub Enterprise: HTTP 200 OK

[async in thread pool]
scanTask -> ElitScannerFactory: getScanner(request)
ElitScannerFactory -> RuleFileReader: read(defaultConfig, repoOpener)
RuleFileReader -> GitHubAppClient: read .elit.yml from repo at headSha
GitHubAppClient -> GitHub Enterprise: GET file content
GitHub Enterprise --> GitHubAppClient: .elit.yml content (or 404)
RuleFileReader --> ElitScannerFactory: Merged ScannerConfiguration
ElitScannerFactory --> PullRequestCheckFunction: ContentScanner

PullRequestCheckFunction -> GitHub Enterprise: GET diff (Accept: application/vnd.github.v3.diff)
GitHub Enterprise --> PullRequestCheckFunction: Unified diff text
PullRequestCheckFunction -> DiffParser: parse(diffReader)
DiffParser --> PullRequestCheckFunction: Stream<DiffItem>
PullRequestCheckFunction -> ContentScanner: scan(insertedLines, lineNumber)
ContentScanner --> PullRequestCheckFunction: Stream<ContentAnnotation>

alt violations found
  PullRequestCheckFunction -> GHCheckRunBuilder: withConclusion(FAILURE); add annotations
else no violations
  PullRequestCheckFunction -> GHCheckRunBuilder: withConclusion(SUCCESS)
end
GHCheckRunBuilder -> GitHub Enterprise: PATCH check run — conclusion + annotations
```

## Related

- Architecture dynamic view: `components-elitGithubAppService`
- Related flows: [Webhook Signature Validation](webhook-signature-validation.md), [Check Suite Requested — Create Check Run](check-suite-requested.md), [ELIT Rule File Loading](elit-rule-file-loading.md)
