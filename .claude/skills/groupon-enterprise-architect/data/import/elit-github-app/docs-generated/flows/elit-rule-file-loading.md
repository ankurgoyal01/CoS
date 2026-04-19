---
service: "elit-github-app"
title: "ELIT Rule File Loading"
generated: "2026-03-03"
type: flow
flow_name: "elit-rule-file-loading"
flow_type: synchronous
trigger: "Invoked by ElitScannerFactory during a PR Diff ELIT Scan"
participants:
  - "continuumElitGithubAppService"
  - "scannerFactory"
  - "ruleFileReader"
  - "githubClient"
  - "githubEnterprise"
architecture_ref: "components-elitGithubAppService"
---

# ELIT Rule File Loading

## Summary

Before scanning a PR diff, the service must build a `ContentScanner` configured with the applicable ELIT rules. This flow describes how `ElitScannerFactory` composes the final scanner: it starts with the bundled `default-elit.yml` rules (always applied), then reads any per-repo `.elit.yml` file from the repository's PR head branch, and recursively follows any additional `ruleFiles` references. The result is a merged `ScannerConfiguration` that drives the regex-based violation scanner.

## Trigger

- **Type**: api-call (internal sub-flow)
- **Source**: `PullRequestCheckFunction` calls `ElitScannerFactory.getScanner(request)` as part of the [PR Diff ELIT Scan](pr-diff-elit-scan.md) flow
- **Frequency**: Once per check run scan execution

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| ELIT Scanner Factory | Initiates rule loading; merges default and per-repo configurations | `scannerFactory` |
| Rule File Reader | Recursively reads and merges YAML rule files following `ruleFiles` references | `ruleFileReader` |
| GitHub App Client | Fetches rule file content from the repository at the PR head SHA | `githubClient` |
| GitHub Enterprise | Provides the rule file content from the repository | `githubEnterprise` |

## Steps

1. **Load default configuration**: `ElitScannerFactory` initialises with `ELIT_DEFAULT_CONFIGURATION`, parsed from `src/main/resources/default-elit.yml` at class load time. This includes the base replacement rules (`master`, `slave`, `black\s*list`, `white\s*list`) and `ruleFiles: [.elit.yml]`.
   - From: `scannerFactory`
   - To: classpath resource `/default-elit.yml`
   - Protocol: direct (in-process, at startup)

2. **Create repository rule file opener**: `ElitScannerFactory.getScanner()` creates a `RepositoryRuleLaxFileOpener` bound to the GitHub client, repository, and PR head SHA. This opener knows how to fetch files from the correct branch.
   - From: `scannerFactory`
   - To: `ruleFileReader`
   - Protocol: direct (in-process)

3. **Read default config and follow ruleFiles references**: `RuleFileReader.read()` recursively processes the configuration. For the default config, `ruleFiles` contains `.elit.yml`, so the reader attempts to open that file next.
   - From: `ruleFileReader`
   - To: `scannerFactory` (callback)
   - Protocol: direct (in-process)

4. **Fetch per-repo .elit.yml from GitHub**: `RepositoryRuleLaxFileOpener.read(".elit.yml")` calls `GitHubAppClient` to fetch the file content at the PR head SHA from the repository. If the file does not exist (HTTP 404 equivalent), it returns an empty JSON object `{}` without logging a warning (missing `.elit.yml` is expected and silent).
   - From: `ruleFileReader`
   - To: `githubClient`
   - Protocol: direct (in-process)
   - From: `githubClient`
   - To: `githubEnterprise` (GitHub Contents API)
   - Protocol: HTTPS REST

5. **Parse per-repo configuration**: The file content is parsed as a `ScannerConfiguration` YAML. If the file is empty (`{}`), the result is an empty configuration with no rules.
   - From: `ruleFileReader`
   - To: `scannerFactory` (result)
   - Protocol: direct (in-process)

6. **Follow cross-repo ruleFiles references**: If the per-repo `.elit.yml` contains a `ruleFiles` list with entries of the form `<repo>:<file>`, `RuleFileReader` fetches those files from the default branch of the specified repository. Deduplication prevents infinite loops (already-processed files are tracked in a `Set<String>`).
   - From: `ruleFileReader`
   - To: `githubClient` / `githubEnterprise`
   - Protocol: HTTPS REST (per referenced file)

7. **Merge configurations**: All loaded `ScannerConfiguration` objects are reduced using `ScannerConfiguration.merge()`. The merged config combines `replace` rules and `exclude` patterns from all sources.
   - From: `ruleFileReader`
   - To: `scannerFactory`
   - Protocol: direct (in-process)

8. **Build scanner**: `ElitScannerFactory.getScanner()` calls `.getScanner()` on the merged configuration to produce the final `ContentScanner`. On any exception during loading, the factory falls back to the default configuration's scanner and logs an error.
   - From: `scannerFactory`
   - To: `checkFunction`
   - Protocol: direct (in-process, return value)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `.elit.yml` does not exist in repo | `RepositoryRuleLaxFileOpener` returns `StringReader("{}")` silently | Empty per-repo config merged in; default rules apply |
| Other referenced rule file not found | `RepositoryRuleLaxFileOpener` returns `StringReader("{}")` with a `WARN` log | That file's rules are skipped; scan proceeds with remaining rules |
| YAML parse error in any rule file | Exception caught in `ElitScannerFactory.getScanner()`; logged as ERROR | Entire rule loading falls back to default-only `ContentScanner` |
| Cross-repo file reference to inaccessible repo | GitHub API error surfaced through rule file opener | Treated as missing file; `WARN` logged; scan proceeds |

## Sequence Diagram

```
PullRequestCheckFunction -> ElitScannerFactory: getScanner(checkActionRequest)
ElitScannerFactory -> ElitScannerFactory: Load ELIT_DEFAULT_CONFIGURATION from /default-elit.yml (startup)
ElitScannerFactory -> RepositoryRuleLaxFileOpener: new opener(github, repo, headSha)
ElitScannerFactory -> RuleFileReader: read(defaultConfig, opener)
RuleFileReader -> RepositoryRuleLaxFileOpener: read(".elit.yml")
RepositoryRuleLaxFileOpener -> GitHubAppClient: getRepositoryById(repoId).getFileContent(".elit.yml", headSha)
GitHubAppClient -> GitHub Enterprise: GET /repos/{owner}/{repo}/contents/.elit.yml?ref={headSha}
alt file exists
  GitHub Enterprise --> GitHubAppClient: File content
  GitHubAppClient --> RepositoryRuleLaxFileOpener: Reader of file content
else file not found
  GitHub Enterprise --> GitHubAppClient: 404
  RepositoryRuleLaxFileOpener --> RuleFileReader: StringReader("{}") [silent]
end
RuleFileReader -> RuleFileReader: Parse ScannerConfiguration from content
RuleFileReader -> RuleFileReader: Merge defaultConfig + perRepoConfig
RuleFileReader --> ElitScannerFactory: Merged ScannerConfiguration
ElitScannerFactory -> MergedConfig: getScanner()
MergedConfig --> ElitScannerFactory: ContentScanner
ElitScannerFactory --> PullRequestCheckFunction: ContentScanner
```

## Related

- Architecture dynamic view: `components-elitGithubAppService`
- Related flows: [PR Diff ELIT Scan](pr-diff-elit-scan.md)
