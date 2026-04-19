---
service: "AIGO-CheckoutBot"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Conversational AI / Checkout Support"
platform: "Continuum"
team: "AIGO Team (amata@groupon.com)"
status: active
tech_stack:
  language: "TypeScript"
  language_version: "5.6.2"
  framework: "Express / Next.js / React"
  framework_version: "4.21.1 / 14.2.14 / 18.3.1"
  runtime: "Node.js"
  runtime_version: "18.20.4"
  build_tool: "npm"
  package_manager: "npm"
---

# AIGO-CheckoutBot Overview

## Purpose

AIGO-CheckoutBot is a conversational AI chatbot that supports Groupon customers through the checkout experience. It orchestrates dynamic decision-tree-driven conversations, leveraging LLM providers (OpenAI GPT and Google Gemini) to generate context-aware responses. The service provides operators with an admin interface to configure conversation flows, simulate interactions, and review analytics.

## Scope

### In scope

- Receiving and processing end-user chat messages via an embeddable chat widget
- Executing configurable conversation decision trees stored in PostgreSQL
- Generating LLM responses through OpenAI and Google Gemini integrations
- Persisting conversation state, messages, and turn history in PostgreSQL
- Caching SSE tokens and distributed coordination locks in Redis
- Providing an admin frontend for designing decision trees, managing prompts, and configuring projects
- Running deal simulation replays to validate conversation flow behavior
- Aggregating conversation analytics and producing reports
- Escalating conversations to Salesforce and creating follow-up tasks in Asana
- Publishing conversation events to Salted for engagement state synchronization

### Out of scope

- Core checkout transaction processing (handled by Continuum order/payment services)
- Customer identity and authentication management (handled upstream)
- Deal and merchant catalog management (handled by deal services)
- LLM model training or fine-tuning

## Domain Context

- **Business domain**: Conversational AI / Checkout Support
- **Platform**: Continuum
- **Upstream consumers**: Customer-facing Groupon pages that embed the Chat Widget Bundle; admin operators accessing the Admin Frontend
- **Downstream dependencies**: OpenAI GPT, Google Gemini, Salesforce, Asana, Salted (engagement platform), PostgreSQL, Redis

## Stakeholders

| Role | Description |
|------|-------------|
| AIGO Team | Owns development and operations (amata@groupon.com) |
| Checkout Operators | Configure conversation trees and prompts via the Admin Frontend |
| Groupon Customers | End users who interact with the chat widget during checkout |
| Customer Support | Receives escalations created in Salesforce by the bot |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | TypeScript | 5.6.2 | package.json |
| Framework (API) | Express | 4.21.1 | package.json |
| Framework (Admin UI) | Next.js | 14.2.14 | package.json |
| Framework (UI) | React | 18.3.1 | package.json |
| Runtime | Node.js | 18.20.4 | package.json engines |
| Build tool | npm | — | package.json |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `pg` | 8.15.6 | db-client | PostgreSQL client for all application data access |
| `redis` | 4.7.1 | db-client | Redis client for cache, SSE tokens, and coordination locks |
| `openai` | 4.98.0 | http-framework | OpenAI GPT API client for LLM completions |
| `@google/genai` | 1.9.0 | http-framework | Google Gemini API client for LLM completions |
| `@tanstack/react-query` | 5.66.0 | state-management | Server-state and async data management in the Admin Frontend |
| `winston` | 3.16.0 | logging | Structured application logging |
| `jsonwebtoken` | 9.0.2 | auth | JWT creation and verification for API authentication |
| `node-pg-migrate` | 7.9.1 | orm | PostgreSQL schema migrations |
| `axios` | 1.7.7 | http-framework | HTTP client for outbound integration calls |
| `tailwindcss` | 3.4.13 | ui-framework | Utility-first CSS framework for Admin Frontend and Chat Widget |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
