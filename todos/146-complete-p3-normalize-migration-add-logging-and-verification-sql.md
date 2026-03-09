---
status: pending
priority: p3
issue_id: "146"
tags: [code-review, migrations, data-integrity, deployment]
dependencies: []
---

# Normalize Migration Should Log Before Overwriting Unparseable Data

## Problem Statement

`NormalizeDoubleEncodedTriggers` rescues `JSON::ParserError` and silently overwrites unparseable `triggers` values with `"[]"`. If any production rows had non-JSON data (plain text, comma-separated lists from an old bug), those values are permanently destroyed without any log entry. Additionally, verification SQL queries should be documented for post-deploy confirmation.

Flagged by: data-migration-expert.

## Findings

**File:** `db/migrate/20260308140000_normalize_double_encoded_triggers.rb`, lines 20–22

```ruby
rescue JSON::ParserError
  log.update_column(:triggers, "[]")
end
```

No logging. If a row is corrupted in an unexpected way, the migration silently zeroes it out.

## Proposed Solution

Add logging to the rescue block:

```ruby
rescue JSON::ParserError => e
  Rails.logger.warn "[NormalizeDoubleEncodedTriggers] Unparseable triggers on SymptomLog##{log.id}: #{raw.inspect} — resetting to []. Error: #{e.message}"
  log.update_column(:triggers, "[]")
end
```

Also add a comment with post-deploy verification SQL:

```ruby
# Post-deploy verification:
#   SELECT COUNT(*) FROM symptom_logs WHERE triggers LIKE '"%';
#   -- Expected: 0 (no double-encoded strings remain)
#
#   SELECT triggers, COUNT(*) FROM symptom_logs
#   WHERE triggers IS NOT NULL AND triggers != '[]'
#   GROUP BY triggers ORDER BY COUNT(*) DESC LIMIT 20;
#   -- Inspect for any unexpected non-JSON values
```

## Acceptance Criteria

- [ ] `JSON::ParserError` rescue logs the affected row ID and raw value
- [ ] Verification SQL documented in migration comments
- [ ] Migration still runs cleanly (logging does not affect behavior)

## Work Log

- 2026-03-08: Identified by data-migration-expert
