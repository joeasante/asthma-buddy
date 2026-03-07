---
phase: 05-symptom-timeline
plan: 01
subsystem: ui
tags: [rails, turbo-frames, hotwire, sqlite, activerecord, pagination, css-custom-properties]

# Dependency graph
requires:
  - phase: 04-symptom-management
    provides: SymptomLog model with CRUD, inline edit/delete via Turbo Streams, scoped to Current.user
  - phase: 03-symptom-recording
    provides: SymptomLog model with chronological scope, has_rich_text :notes, enums for symptom_type/severity

provides:
  - SymptomLog.in_date_range scope (nil-bounded start/end dates)
  - SymptomLog.severity_counts class method returning {mild:, moderate:, severe:} hash
  - SymptomLog.paginate class method (no gem, offset/limit arithmetic)
  - SymptomLogsController#index with preset/start_date/end_date/page params and full @variable set
  - Timeline index page with Turbo Frame architecture (filter bar outside, content inside frame)
  - _filter_bar partial: preset chips (7/30/90/All) + custom date form targeting timeline_content frame
  - _trend_bar partial: horizontal stacked severity bar with percentage widths
  - _timeline_row partial: compact row with severity indicator bar, dom_id, type/severity/timestamp/notes
  - _pagination partial: Prev/Next with page position indicator, targeting timeline_content frame
  - symptom_timeline.css: severity color palette (CSS custom properties) for reuse in Phase 6+ peak flow

affects:
  - 05-symptom-timeline (plan 02 adds tests for these scopes)
  - 06-peak-flow (will reuse --severity-mild/moderate/severe CSS custom properties for zone colors)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Turbo Frame split architecture: filter bar outside frame, content inside — enables targeted partial refresh without full page reload
    - Manual pagination via offset/limit — no kaminari/pagy dependency; returns [records, total_pages, current_page] tuple
    - Severity color palette via CSS custom properties — established green/yellow/red visual language shared across phases
    - severity_counts via ActiveRecord group(:severity).count with transform_keys — database-level aggregation, not Ruby-level

key-files:
  created:
    - app/views/symptom_logs/_filter_bar.html.erb
    - app/views/symptom_logs/_trend_bar.html.erb
    - app/views/symptom_logs/_timeline_row.html.erb
    - app/views/symptom_logs/_pagination.html.erb
    - app/assets/stylesheets/symptom_timeline.css
  modified:
    - app/models/symptom_log.rb
    - app/controllers/symptom_logs_controller.rb
    - app/views/symptom_logs/index.html.erb

key-decisions:
  - "Manual pagination (no gem) — paginate class method returns [records, total_pages, page] tuple using offset/limit; avoids adding kaminari/pagy for a simple 25-per-page use case"
  - "Filter bar lives OUTSIDE turbo_frame_tag 'timeline_content' so chip links/date form can target the frame without being inside it"
  - "dom_id added to _timeline_row article so Turbo Stream destroy (from existing destroy action) can still remove entries by id"
  - "CSS custom properties (--severity-mild/moderate/severe) established in symptom_timeline.css for Phase 6+ peak flow zone color reuse"
  - "Removed stray javascript_include_tag 'trix' from index — project uses Lexxy, not Trix (per project MEMORY.md)"

patterns-established:
  - "Turbo Frame split: controls outside frame, results inside — filter bar outside timeline_content, content refreshes without reloading controls"
  - "Severity color palette: --severity-mild (#2d8a4e green), --severity-moderate (#c57a00 amber), --severity-severe (#c0392b red) — shared visual language for all severity/zone indicators"
  - "DB-level aggregation: group(:severity).count for severity_counts — do not compute in Ruby"

# Metrics
duration: 3min
completed: 2026-03-07
---

# Phase 5 Plan 01: Symptom Timeline Summary

**Filtered, paginated symptom timeline with Turbo Frame partial refresh, severity trend bar, and CSS custom property color palette for Phase 6+ reuse.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-07T13:25:37Z
- **Completed:** 2026-03-07T13:28:24Z
- **Tasks:** 3
- **Files modified:** 8 (5 created, 3 modified)

## Accomplishments
- Added `in_date_range`, `severity_counts`, and `paginate` class methods to SymptomLog model
- Enhanced SymptomLogsController#index to parse preset/date/page params, scope queries to Current.user, and set all timeline instance variables
- Built complete timeline UI: filter bar with preset chips and custom date form, severity trend bar, compact timeline rows, pagination nav
- Established severity color palette as CSS custom properties for Phase 6+ peak flow zone reuse

## Task Commits

Each task was committed atomically:

1. **Task 1: Model scopes and controller index action** - `d5fd7be` (feat)
2. **Task 2: Timeline index page, filter bar, and trend bar** - `9dfc185` (feat)
3. **Task 3: Timeline row partial, pagination partial, and CSS** - `08847ab` (feat)

## Files Created/Modified
- `app/models/symptom_log.rb` - Added in_date_range scope, severity_counts, and paginate class methods
- `app/controllers/symptom_logs_controller.rb` - Rewrote index action with full filter/pagination/severity logic
- `app/views/symptom_logs/index.html.erb` - Restructured with Turbo Frame split architecture
- `app/views/symptom_logs/_filter_bar.html.erb` - Preset chips + custom date form, targeting timeline_content frame
- `app/views/symptom_logs/_trend_bar.html.erb` - Horizontal stacked severity bar with percentage widths
- `app/views/symptom_logs/_timeline_row.html.erb` - Compact row: severity indicator bar, dom_id, type/severity/timestamp/notes preview
- `app/views/symptom_logs/_pagination.html.erb` - Prev/Next nav with page position, targeting timeline_content frame
- `app/assets/stylesheets/symptom_timeline.css` - Severity color palette (CSS custom properties), filter chips, trend bar, pagination, empty state, mobile responsive

## Decisions Made
- Manual pagination (no gem) — avoids kaminari/pagy dependency for simple 25-per-page use case
- Filter bar outside turbo_frame so chip links/form can target the frame without nesting issues
- dom_id on `_timeline_row` article to preserve Turbo Stream destroy targeting
- CSS custom properties for severity colors to establish reusable design language

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added dom_id to _timeline_row article element**
- **Found during:** Task 3 (timeline row partial creation)
- **Issue:** Existing controller test `test_index_shows_only_current_user's_symptom_logs` asserted `#symptom_log_247688535` existed in rendered page; without dom_id on the row article, Turbo Stream destroy could also not target entries for removal
- **Fix:** Added `id="<%= dom_id(symptom_log) %>"` to the article element in `_timeline_row.html.erb`
- **Files modified:** `app/views/symptom_logs/_timeline_row.html.erb`
- **Verification:** All 88 tests pass after fix
- **Committed in:** `08847ab` (Task 3 commit)

**2. [Rule 1 - Bug] Removed stray javascript_include_tag "trix" from index.html.erb**
- **Found during:** Task 2 (restructuring index.html.erb)
- **Issue:** Old index had `<%= javascript_include_tag "trix" %>` in content_for :head; project uses Lexxy (not Trix) per project MEMORY.md — this was including a non-existent or incorrect JS asset
- **Fix:** Removed the `javascript_include_tag "trix"` block entirely from index.html.erb
- **Files modified:** `app/views/symptom_logs/index.html.erb`
- **Verification:** App loads without errors; no Trix JS included for this page
- **Committed in:** `9dfc185` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs)
**Impact on plan:** Both fixes necessary for correctness — dom_id required for Turbo Stream targeting and existing test compliance; Trix removal aligns with project's Lexxy decision. No scope creep.

## Issues Encountered
None beyond the deviations documented above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Timeline view fully functional with filter/pagination/trend bar
- Severity CSS custom properties established and ready for Phase 6 peak flow zone color reuse
- Plan 02 (tests) can now write unit tests for `in_date_range`, `severity_counts`, and `paginate` scopes
- No blockers

## Self-Check: PASSED

Files verified:
- FOUND: app/models/symptom_log.rb
- FOUND: app/controllers/symptom_logs_controller.rb
- FOUND: app/views/symptom_logs/index.html.erb
- FOUND: app/views/symptom_logs/_filter_bar.html.erb
- FOUND: app/views/symptom_logs/_trend_bar.html.erb
- FOUND: app/views/symptom_logs/_timeline_row.html.erb
- FOUND: app/views/symptom_logs/_pagination.html.erb
- FOUND: app/assets/stylesheets/symptom_timeline.css

Commits verified:
- FOUND: d5fd7be (Task 1)
- FOUND: 9dfc185 (Task 2)
- FOUND: 08847ab (Task 3)

---
*Phase: 05-symptom-timeline*
*Completed: 2026-03-07*
