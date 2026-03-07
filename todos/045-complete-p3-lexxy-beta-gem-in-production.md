---
status: complete
priority: p3
issue_id: "045"
tags: [code-review, security, supply-chain, gemfile]
dependencies: []
---

# `lexxy` Beta Gem in Production Gemfile — Supply Chain Risk

## Problem Statement

`Gemfile` includes `gem "lexxy", "~> 0.1.26.beta"` in the production dependency group (not scoped to `:development` or `:test`). Pre-release beta gems are published under relaxed stability guarantees and may not follow a formal security disclosure process. Combined with `~>` version constraint, a `bundle update` could pull in a newer beta release without explicit review.

## Findings

**Flagged by:** security-sentinel (Medium — Finding 3)

**Location:** `Gemfile`, line 69

```ruby
gem "lexxy", "~> 0.1.26.beta"
```

**Risks:**
1. Beta releases may introduce breaking changes or security regressions with no CVE tracking
2. `~> 0.1.26.beta` allows any `0.1.26.*` beta update — a compromised `0.1.26.1.beta` would be automatically pulled
3. `lexxy` is a Lexical-based rich text editor — its JS is served to users, making supply chain compromise high-impact
4. `bundler-audit` does not track CVEs for beta gems reliably

**Relationship to Trix/ActionText:** Planning docs indicate `lexxy` replaced Trix as the frontend editor. The gem ships `lexxy.js` which is pinned in `importmap.rb`. If lexxy serves the rich text editor widget, a compromised JS would allow client-side XSS at the editor level — affecting health notes entered by users.

## Proposed Solutions

### Solution A: Lock to exact version (Near-term fix)
```ruby
gem "lexxy", "0.1.26.beta"  # exact version pin; requires explicit bump
```
- **Pros:** Prevents auto-update to newer beta. `Gemfile.lock` still pins the sha256.
- **Cons:** Still a beta gem. Still no CVE tracking.
- **Effort:** Tiny
- **Risk:** None (more restrictive)

### Solution B: Evaluate stable release or alternative
Check if lexxy has a stable release. If not, evaluate whether ActionText + Trix (built-in to Rails) could handle the use case without a third-party beta dependency.
- **Effort:** Medium (investigation + potential migration)
- **Risk:** Medium (could require form changes)

### Solution C: Verify gem sha256 in deploy pipeline
Add a step to verify `Gemfile.lock` gem sha256 against the published gem on rubygems.org before each deploy.
- **Effort:** Medium (CI/pipeline change)
- **Risk:** Low

## Recommended Action

Solution A immediately (lock exact version). Solution B as a longer-term evaluation. Check if a stable lexxy release is available.

## Technical Details

- **File:** `Gemfile`, line 69
- **importmap pin:** `config/importmap.rb` — `pin "lexxy", to: "lexxy.js"`

## Acceptance Criteria

- [ ] `lexxy` version locked to exact version string (not `~>` with beta)
- [ ] Decision documented: continue with lexxy or migrate to stable alternative
- [ ] `bundler-audit check --update` runs cleanly in CI
- [ ] Gemfile.lock sha256 verified against published gem

## Work Log

- 2026-03-07: Created from second-pass code review. Flagged by security-sentinel as Medium supply chain risk.
