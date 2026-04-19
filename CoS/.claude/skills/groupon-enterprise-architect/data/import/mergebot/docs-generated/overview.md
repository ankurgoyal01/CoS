---
service: "mergebot"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Developer Productivity / SOX Compliance"
platform: "Continuum / Release Engineering"
team: "RAPT"
status: active
tech_stack:
  language: "Ruby"
  language_version: "2.4.7"
  framework: "Rails"
  framework_version: "4.2.11.1"
  runtime: "Unicorn"
  runtime_version: "4.3.1"
  build_tool: "Bundler"
  package_manager: "Bundler / RubyGems"
---

# Mergebot Overview

## Purpose

Mergebot enables pull requests to be merged into GitHub Enterprise repositories without requiring developers to hold direct write access. Its primary use case is SOX compliance: it validates approvals, CI build status, committer email domain, and per-repository policy before executing a merge via the GitHub API. It also automates post-merge branch cleanup and notifies teams via Slack.

## Scope

### In scope

- Receiving and verifying GitHub webhook events (`issue_comment`, `pull_request_review`)
- Validating PR merge eligibility against a per-repository `.ghe-bot.yml` policy
- Enforcing CI build-green requirement before merging
- Supporting two approval modes: comment-based (`approval_by_comment`) and GitHub review-based (`approval_by_review`)
- Blocking merges when block words appear in comments, PR title, or PR body
- Executing PR merges via GitHub API using configurable merge methods (`merge`, `squash`, `rebase`)
- Deleting source branches after merge (configurable, with allowlist for protected branches)
- Posting Slack notifications on merge success and failure
- Enforcing Groupon email address requirement on all commits

### Out of scope

- CI pipeline execution (handled by Jenkins / Conveyor CI)
- GitHub branch protection rule management
- PR creation or code review workflows
- Deployment pipeline orchestration

## Domain Context

- **Business domain**: Developer Productivity / SOX Compliance
- **Platform**: Continuum / Release Engineering
- **Upstream consumers**: GitHub Enterprise (sends webhook events to Mergebot on each issue comment or PR review action)
- **Downstream dependencies**: GitHub Enterprise API (PR reads, merge, branch delete), Slack API (notifications), Groupon logging stack (structured logs)

## Stakeholders

| Role | Description |
|------|-------------|
| RAPT Team (scam-team@groupon.com) | Service owners; maintain and operate Mergebot |
| Repository administrators | Configure `.ghe-bot.yml` and install the Mergebot GitHub App on repos |
| Engineers | Authors and reviewers of PRs managed by Mergebot |
| SOX compliance / audit | Rely on Mergebot to enforce separation of duties in `sox-inscope` repositories |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 2.4.7 | `.ci/Dockerfile` |
| Framework | Rails | 4.2.11.1 | `Gemfile` |
| Runtime | Unicorn | 4.3.1 | `Gemfile`, `script/unicorn-mergebot` |
| Build tool | Bundler | — | `Gemfile`, `Gemfile.lock` |
| Package manager | RubyGems | — | `Gemfile` source: `rubygems.groupondev.com` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `rails` | 4.2.11.1 | http-framework | Web application framework; routing, controllers |
| `unicorn` | 4.3.1 | http-framework | Rack/HTTP server for production |
| `octokit` | 4.14.0 | http-client | GitHub API client; PR reads, merge, branch delete |
| `faraday` | — | http-client | HTTP client used as Octokit transport |
| `slack-api` | 1.2.4 | messaging | Slack API client for posting notifications |
| `steno_logger` | ~0.3 | logging | Structured JSON log emission to ELK/filebeat |
| `sonoma-metrics` | 0.6.0 | metrics | Groupon internal metrics emission |
| `rspec` | — | testing | Unit and integration test framework |
| `rspec-rails` | — | testing | Rails integration for RSpec |
| `awesome_print` | — | logging | Debug pretty-printer for development |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `Gemfile.lock` for a full list.
