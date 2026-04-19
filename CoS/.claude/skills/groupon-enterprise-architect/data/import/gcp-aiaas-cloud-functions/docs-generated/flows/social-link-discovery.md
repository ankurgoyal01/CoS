---
service: "gcp-aiaas-cloud-functions"
title: "Social Link Discovery"
generated: "2026-03-03"
type: flow
flow_name: "social-link-discovery"
flow_type: synchronous
trigger: "HTTP GET or POST with merchantUrl parameter"
participants:
  - "continuumAiaasSocialLinkScraperFunction"
  - "apify"
architecture_ref: "components-continuumAiaasSocialLinkScraperFunction"
---

# Social Link Discovery

## Summary

The Social Link Discovery flow accepts a merchant website URL, crawls up to a configurable number of pages (default 3), extracts all social media profile links from anchor tags and JSON-LD `sameAs` structured data, and optionally enriches discovered Instagram profiles via an Apify actor. The flow supports 15 social platforms and returns a structured JSON map of platform-to-URL-list alongside crawl metadata. It is used to enrich merchant profiles with social media presence data.

## Trigger

- **Type**: api-call
- **Source**: Internal merchant advisor tooling or enrichment pipelines calling the Social Link Scraper Cloud Function
- **Frequency**: On-demand (per merchant social enrichment request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Social Link Scraper Cloud Function | Entry point; validates request, coordinates crawl and enrichment | `continuumAiaasSocialLinkScraperFunction` |
| Social Link Request Handler | Validates `merchantUrl` and optional parameters | `continuumAiaasSocialLinkScraperFunction_socialLinkRequestHandler` |
| Crawler | Fetches merchant pages and extracts social links from anchors and JSON-LD | `continuumAiaasSocialLinkScraperFunction_socialLinkCrawler` |
| Apify Adapter | Enriches discovered Instagram profiles via Apify actor `dSCLg0C3YEZ83HzYX` | `continuumAiaasSocialLinkScraperFunction_socialLinkApifyAdapter` |
| Apify | Instagram profile enrichment actor | `apify` |

## Steps

1. **Handle CORS preflight**: If request method is `OPTIONS`, return 204 with CORS headers immediately.
   - From: Caller
   - To: `continuumAiaasSocialLinkScraperFunction`
   - Protocol: REST/HTTPS

2. **Parse and validate request**: Extract `merchantUrl` (or `merchant_url`) from query params or JSON body — required. Parse optional parameters: `maxPages` (default 3), `timeout` (default 5 seconds), `scrapeInstagram` (default false), `apifyToken`, `apifyMaxProfiles` (default 2), `includePostsData` (default false). Both camelCase and snake_case parameter names are accepted.
   - From: `continuumAiaasSocialLinkScraperFunction_socialLinkRequestHandler`
   - To: `continuumAiaasSocialLinkScraperFunction_socialLinkRequestHandler` (internal)
   - Protocol: direct

3. **Normalize merchant URL**: If the URL lacks a scheme, prepend `https://`. Initialize the crawl queue with the merchant homepage.
   - From: `continuumAiaasSocialLinkScraperFunction_socialLinkCrawler`
   - To: `continuumAiaasSocialLinkScraperFunction_socialLinkCrawler` (internal)
   - Protocol: direct

4. **Fetch and parse pages**: For each page in the queue (up to `maxPages`), send an HTTP GET request with browser-like User-Agent header. Parse HTML using BeautifulSoup with the `lxml` parser.
   - From: `continuumAiaasSocialLinkScraperFunction_socialLinkCrawler`
   - To: Merchant website (external)
   - Protocol: HTTPS (requests library)

5. **Extract social links from anchors**: Scan all `<a href>` elements in parsed HTML and extract links whose domains match the supported social platform list (Facebook, Instagram, Twitter/X, LinkedIn, YouTube, TikTok, Pinterest, Threads, Snapchat, WeChat, Weibo, VK).
   - From: `continuumAiaasSocialLinkScraperFunction_socialLinkCrawler`
   - To: `continuumAiaasSocialLinkScraperFunction_socialLinkCrawler` (internal)
   - Protocol: direct

6. **Extract social links from JSON-LD**: Scan `<script type="application/ld+json">` blocks for `sameAs` fields containing additional social media profile URLs.
   - From: `continuumAiaasSocialLinkScraperFunction_socialLinkCrawler`
   - To: `continuumAiaasSocialLinkScraperFunction_socialLinkCrawler` (internal)
   - Protocol: direct

7. **Discover sub-pages**: On the homepage only, identify links with keywords `contact`, `about`, `connect`, `social`, `find-us` in link text or href; add those to the crawl queue for subsequent iterations.
   - From: `continuumAiaasSocialLinkScraperFunction_socialLinkCrawler`
   - To: `continuumAiaasSocialLinkScraperFunction_socialLinkCrawler` (internal)
   - Protocol: direct

8. **Enrich Instagram profiles (conditional)**: If `scrapeInstagram=true`, `apifyToken` is available, and Instagram URLs were discovered, extract Instagram usernames and call Apify actor `dSCLg0C3YEZ83HzYX` with up to `apifyMaxProfiles` usernames. Retrieve profile metadata (followers, biography, business category, verified status).
   - From: `continuumAiaasSocialLinkScraperFunction_socialLinkApifyAdapter`
   - To: `apify`
   - Protocol: HTTPS REST (apify-client)

9. **Assemble and return response**: Build the result map with discovered social platforms as keys (arrays of URLs), plus `_meta` (source URL, pages crawled, elapsed time), `success` flag, and `message` string. If Instagram enrichment was performed, add `instagram_apify` key with profile data.
   - From: `continuumAiaasSocialLinkScraperFunction`
   - To: Caller
   - Protocol: REST/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing `merchantUrl` parameter | Return `400` with error message | JSON error response |
| Invalid parameter value (non-integer `maxPages`) | Return `400` with error details | JSON error response |
| Page fetch fails (timeout, network error) | Log and skip page; continue with remaining queue | Fewer pages crawled; partial social links returned |
| All pages fail to fetch | `success: false`, message "Failed to fetch any page" | Response returned with empty social link map |
| No social links found | `success: true`, message "Fetched site but found no social links." | Response returned with empty social link map |
| Missing `apifyToken` for Instagram enrichment | Include `instagram_apify.error: "Missing Apify token..."` in response | Response still includes base social links; no Instagram enrichment |
| Apify actor failure | Include error in `instagram_apify.error` field | Response still includes base social links |
| Unexpected exception | Return `500` with error message | JSON error response |

## Sequence Diagram

```
Caller -> SocialLinkScraperFunction: GET /?merchantUrl=https://example.com&scrapeInstagram=true&apifyToken=X
SocialLinkScraperFunction -> SocialLinkScraperFunction: Parse and validate parameters
SocialLinkScraperFunction -> MerchantWebsite: GET https://example.com (User-Agent: Chrome)
MerchantWebsite --> SocialLinkScraperFunction: HTML page
SocialLinkScraperFunction -> SocialLinkScraperFunction: Extract anchors and JSON-LD sameAs links
SocialLinkScraperFunction -> MerchantWebsite: GET https://example.com/contact (discovered sub-page)
MerchantWebsite --> SocialLinkScraperFunction: HTML page
SocialLinkScraperFunction -> SocialLinkScraperFunction: Extract additional social links
SocialLinkScraperFunction -> SocialLinkScraperFunction: Filter links by social domain list
SocialLinkScraperFunction -> SocialLinkScraperFunction: Extract Instagram usernames
SocialLinkScraperFunction -> Apify: Call actor dSCLg0C3YEZ83HzYX {usernames: [...]}
Apify --> SocialLinkScraperFunction: Instagram profile data
SocialLinkScraperFunction --> Caller: 200 {facebook: [...], instagram: [...], instagram_apify: {...}, _meta: {...}}
```

## Related

- Architecture dynamic view: `components-continuumAiaasSocialLinkScraperFunction`
- Related flows: [InferPDS Service Extraction](inferpds-service-extraction.md)
