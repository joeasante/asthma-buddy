---
status: pending
priority: p2
issue_id: "261"
tags: [code-review, rails, maintainability]
dependencies: []
---

# Notification Body Hard-Codes "14 days" Instead of `Medication::LOW_STOCK_DAYS`

## Problem Statement

The notification body string in `app/models/notification.rb` reads `"fewer than 14 days of supply remaining"` as a literal, but `Medication::LOW_STOCK_DAYS = 14` is the authoritative constant. If `LOW_STOCK_DAYS` is ever changed, the notification body will silently diverge and show users a stale threshold. The literal and the constant will be out of sync with no compiler or test to catch it.

## Findings

`app/models/notification.rb` line 30:

```ruby
body: "#{medication.name} has fewer than 14 days of supply remaining. Consider requesting a refill."
```

`app/models/medication.rb` defines:

```ruby
LOW_STOCK_DAYS = 14
```

- The `14` in the notification body is a copy of `Medication::LOW_STOCK_DAYS`, not a reference to it.
- Changing `LOW_STOCK_DAYS` to another value (e.g. 10 or 21) would update the low-stock detection logic but leave the notification text unchanged.
- Users would receive notifications saying "fewer than 14 days" even when the actual threshold was different.

Confirmed by: kieran-rails-reviewer.

## Proposed Solutions

### Option A — Interpolate the constant *(Recommended)*

```ruby
body: "#{medication.name} has fewer than #{Medication::LOW_STOCK_DAYS} days of supply remaining. Consider requesting a refill."
```

Pros: single source of truth; body text always matches the detection threshold; zero-effort to maintain
Cons: none

### Option B — Move the body string to a locale key

```yaml
# config/locales/en.yml
notifications:
  low_stock:
    body: "%{name} has fewer than %{days} days of supply remaining. Consider requesting a refill."
```

```ruby
body: I18n.t("notifications.low_stock.body", name: medication.name, days: Medication::LOW_STOCK_DAYS)
```

Pros: internationalisation-ready; body text is editable without touching model code
Cons: adds indirection for a string that is currently not localised; premature for a single-locale app

## Recommended Action

Option A — interpolate `Medication::LOW_STOCK_DAYS` directly. Minimal change, maximum correctness.

## Technical Details

- **Affected file:** `app/models/notification.rb` line 30

## Acceptance Criteria

- [ ] The notification body no longer contains the literal `"14 days"` hard-coded as a string
- [ ] The body interpolates `Medication::LOW_STOCK_DAYS` for the day count
- [ ] A test asserts that the generated notification body reflects the value of `Medication::LOW_STOCK_DAYS` (not a fixed `"14"`)
- [ ] If `Medication::LOW_STOCK_DAYS` is changed in future, the notification body test fails loudly rather than silently passing with stale text

## Work Log

- 2026-03-11: Found by kieran-rails-reviewer during Phase 19 code review
