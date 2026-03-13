---
status: pending
priority: p2
issue_id: "338"
tags: [code-review, caching, performance, rails, architecture]
dependencies: []
---

# Dashboard vars cache stores full ActiveRecord objects — should store plain data

## Problem Statement

`DashboardVariables#set_dashboard_vars` caches a Ruby hash containing live ActiveRecord objects: `Medication` instances (with `dose_logs` preloaded via `includes`), a custom `AdherenceCalculator::Result` Struct, and a `HealthEvent` instance. Solid Cache serializes these via `Marshal`.

Caching full AR objects is fragile and produces larger-than-necessary cache payloads:

1. **Schema migration risk.** A column rename or addition between cache write and cache read can cause `Marshal.load` to return an object with nil fields or raise `ArgumentError`. With a 5-minute TTL and zero-downtime Kamal deploys, a rolling deploy during the TTL window is a realistic scenario.

2. **Stale loaded associations.** `dose_logs` are preloaded at cache-write time and baked into the serialized blob. Methods like `remaining_doses` branch on `dose_logs.loaded?` — the deserialized object reports `loaded? == true` but with a frozen snapshot. `DoseLog` callbacks already invalidate on create/destroy, but a concurrent request that hits the fetch block slightly before the callback fires will serve the stale snapshot.

3. **Payload size.** A `Medication` instance with 10 associated `DoseLog` rows marshals to roughly 3–6 KB. A plain hash with only the fields the dashboard views consume is under 200 bytes. Each cache miss writes a multi-KB blob to `production_cache.sqlite3`.

Flagged by: performance-oracle, architecture-strategist (Phase 22 code review).

## Findings

- `app/controllers/concerns/dashboard_variables.rb:17-35` — caches full AR instances
- `app/models/medication.rb` — `remaining_doses` branches on `dose_logs.loaded?` — could behave differently on deserialized object
- `config/cache.yml` — `max_size: 256.megabytes` is shared across all cache entries; large blobs reduce capacity for other keys

## Proposed Solutions

### Option A: Cache plain scalar hashes (Recommended)
Inside the `Rails.cache.fetch` block, compute all derived values (`remaining_doses`, `low_stock?`, `adherence status`) before serialization and store only primitives:

```ruby
cached = Rails.cache.fetch("dashboard_vars/#{user.id}/#{today}", expires_in: 5.minutes) do
  preventer_adherence = user.medications
    .where(medication_type: :preventer, course: false)
    .includes(:dose_logs)
    .select { |m| m.doses_per_day.present? }
    .map do |m|
      result = AdherenceCalculator.call(m, today)
      { medication_id: m.id, medication_name: m.name, taken: result.taken, scheduled: result.scheduled, status: result.status }
    end
  # ... similar for reliever_medications and active_illness
end
```

Views then read `adherence[:medication_name]` etc. instead of `adherence[:medication].name`.
- **Pros:** No Marshal/schema fragility, 10–30x smaller payloads, no stale-association risk
- **Cons:** Requires view/partial updates to use hash keys instead of AR method calls; larger refactor
- **Effort:** Medium
- **Risk:** Medium (view changes required)

### Option B: Keep AR objects, add a cache version key
Append a version segment to the cache key that increments on schema changes (e.g. via a `CACHE_VERSION` constant in `DashboardVariables`). Bump the version when `Medication` or `HealthEvent` schema changes.
- **Pros:** Minimal code change
- **Cons:** Manual discipline; does not fix payload size; still susceptible to forgotten version bumps
- **Effort:** Small
- **Risk:** Medium (operational, not code)

### Option C: Accept current state, document known risks
Add a comment in `dashboard_variables.rb` documenting the AR-object caching decision, the schema-migration caveat, and the 5-minute TTL as the safety net.
- **Pros:** Zero code change
- **Cons:** Doesn't fix the root issue
- **Effort:** Minimal
- **Risk:** Low (operational only)

## Recommended Action

Option A for the long term; Option C as an interim step while the view refactor is planned.

## Technical Details

**Affected files:**
- `app/controllers/concerns/dashboard_variables.rb`
- `app/views/dashboard/` — partials that read from `@preventer_adherence` and `@reliever_medications`

## Acceptance Criteria

- [ ] `dashboard_vars` cache stores only scalar primitives (no AR instances, no loaded association proxies)
- [ ] Views read from the plain hash structure instead of calling AR methods on deserialized objects
- [ ] No schema migration can silently corrupt a cache hit
- [ ] Cache payload size measured and documented to confirm reduction
- [ ] Test suite passes

## Work Log

- 2026-03-13: Identified in Phase 22 code review (performance-oracle, architecture-strategist)
